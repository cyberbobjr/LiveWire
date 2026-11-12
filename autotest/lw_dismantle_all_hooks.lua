-- Live Wire and LiveWire Extended in-game check: every dismantle recipe through the crafting
-- window path (HandcraftLogic + ISHandcraftAction.FromLogic + ISTimedActionQueue), one after
-- the other, on new items (no mark: full condition). For each: the item is consumed, parts come
-- back, no tool is consumed. Extended recipes (fixed outputs) are checked part by part. The
-- voltage tester recipe (car batteries) is covered by lw_dismantle_hooks.lua's sibling runs.
local H = {}
local lines, okAll = {}, true
local p
local TOOLS = { "Base.Screwdriver", "Base.Hammer", "Base.PipeWrench" }
local RECIPES = {
    { "LWDismantleSolarPanel", "Base.Mov_LiveWire_SolarPanel" },
    { "LWDismantleWindTurbine", "Base.Mov_LiveWire_WindTurbine" },
    { "LWDismantleWaterWheel", "Base.Mov_LiveWire_WaterWheel" },
    { "LWDismantleInverter", "Base.Mov_LiveWire_Inverter" },
    { "LWDismantleInverterCabinet", "Base.Mov_LiveWire_InverterCabinet" },
    { "LWDismantlePowerBank", "Base.Mov_LiveWire_PowerBank" },
    { "LWDismantleBreaker", "Base.Mov_LiveWire_Breaker" },
    { "LWDismantleBatteryAlarm", "Base.Mov_LiveWire_BatteryAlarm" },
    { "LWDismantleWaterPump", "Base.Mov_LiveWire_WaterPump" },
    { "LWDismantleCouplingKit", "LiveWire.CouplingKit" },
    { "LWDismantleSoundproofKit", "LiveWire.SoundproofKit" },
    { "LWDismantleWindTurbineBlades", "LiveWire.WindTurbineBlades" },
    { "LWDismantleWindTurbineMast", "LiveWire.WindTurbineMast" },
    { "LWDismantleDeepCycleBattery", "LiveWire.DeepCycleBattery" },
    { "LWXDismantleTerminal", "Base.Mov_LiveWire_Terminal",
      { ["Base.MetalPipe"] = 1, ["Base.SmallSheetMetal"] = 1, ["Base.ElectricWire"] = 1, ["Base.Screws"] = 2 } },
    { "LWXDismantlePanel8", "Base.Mov_LiveWire_Panel8",
      { ["Base.SmallSheetMetal"] = 1, ["Base.ElectricWire"] = 1, ["Base.Screws"] = 2 } },
    { "LWXDismantlePanel16", "Base.Mov_LiveWire_Panel16",
      { ["Base.SmallSheetMetal"] = 2, ["Base.ElectricWire"] = 1, ["Base.Screws"] = 2 } },
    { "LWXDismantlePanel24", "Base.Mov_LiveWire_Panel24",
      { ["Base.SmallSheetMetal"] = 3, ["Base.ElectricWire"] = 1, ["Base.Screws"] = 2 } },
}
local state = { i = 0, phase = "next", t0 = 0 }
local LIMIT_MS = 90000

local function rec(ok, msg)
    if not ok then okAll = false end
    lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. msg
end

local function snapshot()
    local s, items = {}, p:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local t = items:get(i):getFullType()
        s[t] = (s[t] or 0) + 1
    end
    return s
end

local function startCraft(r)
    local recipe = getScriptManager():getCraftRecipe("LiveWire." .. r[1])
    if not recipe then rec(false, r[1] .. ": recipe not found"); return false end
    if not p:getInventory():AddItem(r[2]) then rec(false, r[1] .. ": cannot create " .. r[2]); return false end
    local logic = HandcraftLogic.new(p, nil, nil)
    logic:setManualSelectInputs(true)
    logic:setContainers(ISInventoryPaneContextMenu.getContainers(p))
    logic:setRecipe(recipe)
    logic:autoPopulateInputs()
    if not logic:canPerformCurrentRecipe() then
        rec(false, r[1] .. ": cannot be performed with the given items"); return false
    end
    state.before = snapshot()
    ISTimedActionQueue.add(ISHandcraftAction.FromLogic(logic))
    state.t0 = getTimestampMs()
    return true
end

function H.start(ctx)
    p = getPlayer()
    if not p then return false, "no player" end
    for _, t in ipairs(TOOLS) do p:getInventory():AddItem(t) end
    p:setPerkLevelDebug(Perks.Electricity, 0)
    state.errors = getLuaDebuggerErrorCount()
    return true
end

function H.done(ctx)
    if state.phase == "next" then
        state.i = state.i + 1
        local r = RECIPES[state.i]
        if not r then
            rec(getLuaDebuggerErrorCount() == state.errors, "no Lua error")
            return true
        end
        state.phase = startCraft(r) and "run" or "next"
        return false
    end
    local r = RECIPES[state.i]
    local queue = ISTimedActionQueue.getTimedActionQueue(p)
    local busy = queue and queue.queue and #queue.queue > 0
    if busy and getTimestampMs() - state.t0 < LIMIT_MS then return false end
    if busy then ISTimedActionQueue.clear(p); rec(false, r[1] .. ": still running after " .. LIMIT_MS .. " ms") end
    local after, gained, bad = snapshot(), {}, {}
    local seen = {}
    for t in pairs(after) do seen[t] = true end
    for t in pairs(state.before) do seen[t] = true end
    for t in pairs(seen) do
        local d = (after[t] or 0) - (state.before[t] or 0)
        if t ~= r[2] and d ~= 0 then gained[#gained + 1] = string.format("%s %+d", t, d) end
        if d < 0 and t ~= r[2] then bad[#bad + 1] = t .. " lost" end
    end
    table.sort(gained)
    if (after[r[2]] or 0) - (state.before[r[2]] or 0) ~= -1 then bad[#bad + 1] = r[2] .. " not consumed" end
    if #gained == 0 then bad[#bad + 1] = "no part back" end
    if r[3] then
        for t, n in pairs(r[3]) do
            local d = (after[t] or 0) - (state.before[t] or 0)
            if d ~= n then bad[#bad + 1] = string.format("%s %+d (want %+d)", t, d, n) end
        end
    end
    rec(#bad == 0, r[1] .. " at Electrical 0: " .. (#bad == 0 and table.concat(gained, ", ") or table.concat(bad, ", ")))
    state.phase = "next"
    return false
end

function H.result(ctx)
    local n = 0
    for _, s in ipairs(lines) do if s:sub(1, 4) == "PASS" then n = n + 1 end end
    return { ok = okAll, summary = n .. "/" .. #lines .. " PASS", lines = lines }
end

return H
