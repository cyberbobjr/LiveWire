-- Live Wire in-game check of GitHub issues #3 and #4 (solo).
-- #3: an inverter whose range circle and network view are open is picked up by the vanilla
--     moveable code (direct call of pickUpMoveableInternal, not the furniture cursor): both
--     views close by themselves within a second, the player standing next to it.
-- #4: the player is told how many devices the pick-up disconnected; the water wheel view
--     (DeviceView.snapshot, direct call) gives its season, wear and efficiency factors, the
--     LCD rows show them, and a server multiplier at 0 reads "disabled".
-- Fixtures: the water wheel is a registry entry linked by Registry.link (no river needed),
-- the multiplier is changed through the sandbox option and restored.
local H = {}
local lines, okAll = {}, true
local S = { phase = "start" }
local INVERTER = "batman_livewire_01_12"

local function rec(ok, msg, detail)
    if not ok then okAll = false end
    lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. msg .. (detail and (" - " .. tostring(detail)) or "")
end

local function clearZombies()
    local list = getCell():getZombieList()
    for i = list:size() - 1, 0, -1 do
        local z = list:get(i)
        z:removeFromWorld(); z:removeFromSquare()
    end
end

local function freeGround(x0, y0)
    for r = 0, 6 do
        for dy = -r, r do
            for dx = -r, r do
                local sq = getCell():getGridSquare(x0 + dx, y0 + dy, 0)
                if sq and sq:isFree(false) and sq:isSolidFloor() and not LiveWire.Marks.firstOnSquare(sq) then
                    return sq
                end
            end
        end
    end
    return nil
end

local function wheelChecks(R, grid, obj)
    local d = R.addDevice({ role = "source", model = "WaterWheel", x = S.sq:getX() + 1, y = S.sq:getY(), z = 0,
        cond = 60, eff = 0.85 })
    R.link(d, grid)
    local s = LiveWire.DeviceView.snapshot(d)
    rec(s and s.season ~= nil and math.abs(s.wear - 0.8) < 1e-6 and s.eff == 0.85 and s.setting == 1,
        "#4 wheel view gives season, wear, efficiency and setting",
        s and string.format("season %s wear %.2f eff %.2f setting %s state %s", tostring(s.season), s.wear, s.eff,
            tostring(s.setting), tostring(s.state)))
    local rows = table.concat(LiveWire.DevicePanel.lines({ obj = obj, data = s }), " | ")
    local factors = getText("IGUI_LW_DeviceHydroFactors", string.format("%.2f", s.season), "0.80", "0.85")
    rec(string.find(rows, factors, 1, true) ~= nil, "#4 LCD row of the factors, translated", rows)
    local opt = getSandboxOptions():getOptionByName("LiveWire.HydroMultiplier")
    local old = opt:getValue()
    opt:setValue(0)
    local off = LiveWire.DeviceView.snapshot(d)
    opt:setValue(old)
    rec(off.state == "disabled" and off.setting == 0, "#4 multiplier 0 reads disabled", off.state)
    rows = table.concat(LiveWire.DevicePanel.lines({ obj = obj, data = off }), " | ")
    rec(string.find(rows, getText("IGUI_LW_State_disabled"), 1, true) ~= nil, "#4 LCD says why", rows)
end

function H.start(ctx)
    S.p = getPlayer()
    S.p:setGodMod(true); S.p:setInvisible(true)
    clearZombies()
    S.errors = getLuaDebuggerErrorCount()
    S.sq = freeGround(math.floor(S.p:getX()) + 2, math.floor(S.p:getY()))
    if not S.sq then rec(false, "free square for the inverter"); S.phase = "end"; return true end
    S.props = ISMoveableSpriteProps.new(getSprite(INVERTER))
    S.obj = S.props:placeMoveableInternal(S.p, S.sq, S.props:instanceItem(INVERTER), INVERTER)
    local m = S.obj and LiveWire.Marks.get(S.obj)
    local R = LiveWire.Registry
    S.inv = m and R.device(m.id)
    if not S.inv then rec(false, "inverter placed and registered"); S.phase = "end"; return true end
    rec(true, "inverter placed and registered", S.inv.id)
    wheelChecks(R, R.grid(S.inv.grid), S.obj)
    -- Notifications shown to the player.
    S.notes = {}
    local show = LiveWire.Client.showNotify
    LiveWire.Client.showNotify = function(player, key, args, bad)
        S.notes[#S.notes + 1] = { key = key, args = args }
        return show(player, key, args, bad)
    end
    LiveWire.RangeView.show(S.inv.id, S.sq:getX(), S.sq:getY(), S.sq:getZ())
    LiveWire.NetworkView.show(S.inv.id, "links")
    S.t0 = getTimestampMs()
    S.phase = "open"
    return true
end

function H.done(ctx)
    clearZombies()
    local now = getTimestampMs()
    if S.phase == "end" then return true end
    if S.phase == "open" then
        if now - S.t0 < 2000 then return false end
        rec(LiveWire.RangeView.isShown(S.inv.id), "#3 circle shown while the inverter stands")
        rec(LiveWire.NetworkView.inverter == S.inv.id, "#3 network view open while the inverter stands")
        S.props:pickUpMoveableInternal(S.p, S.sq, S.obj, nil, INVERTER, true, false)
        rec(S.obj:getObjectIndex() == -1, "inverter picked up")
        S.t0, S.phase = now, "picked"
        return false
    end
    if S.phase == "picked" then
        local closed = not LiveWire.RangeView.isShown(S.inv.id) and LiveWire.NetworkView.inverter == nil
        if not closed and now - S.t0 < 5000 then return false end
        rec(not LiveWire.RangeView.isShown(S.inv.id), "#3 circle closed after the pick-up", (now - S.t0) .. " ms")
        rec(LiveWire.NetworkView.inverter == nil, "#3 network view closed after the pick-up", (now - S.t0) .. " ms")
        local told
        for _, n in ipairs(S.notes) do if n.key == "IGUI_LW_DevicesDisconnected" then told = n end end
        rec(told ~= nil and tostring(told.args[1]) == "1", "#4 player told: 1 device disconnected",
            told and getText(told.key, told.args[1]))
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        return true
    end
    return true
end

function H.result(ctx)
    return { ok = okAll, summary = "LiveWire issues #3 #4" .. (okAll and " PASS" or " FAIL"), lines = lines }
end
return H
