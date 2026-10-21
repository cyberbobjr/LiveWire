-- Live Wire in-game check: vanilla electrical crafts still complete with the mod loaded
-- (player report, 2026-10-21: improvised flashlight and lantern stop at 96 % or stay at
-- 100 %). Crafts through the same path as the crafting window: HandcraftLogic +
-- ISHandcraftAction.FromLogic + ISTimedActionQueue, one recipe after the other.
-- Run it with a pz-autotest configuration whose "hooks" points to this file (the
-- project's autotest.json uses lw_hooks.lua); it needs a save with a table or a
-- counter within 30 tiles of the player.
local H = {}
local lines, okAll = {}, true
local p
local RECIPES = {
    { name = "MakeImprovisedFlashlight", out = "Base.Flashlight_Crafted" },
    { name = "MakeImprovisedLantern", out = "Base.Lantern_CraftedElectric" },
}
local INPUTS = { "Base.Screwdriver", "Base.Pliers", "Base.SmallSaw" }
local PER_CRAFT = { "Base.ElectronicsScrap", "Base.LightBulb", "Base.ElectricWire", "Base.TinCanEmpty",
                    "Base.Screws", "Base.Wire" }
local state = { i = 0, phase = "seek", t0 = 0, maxDelta = 0, action = nil }
local surface = nil
local LIMIT_MS = 60000

local function rec(ok, msg)
    if not ok then okAll = false end
    lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. msg
end

local function count(fullType)
    return p:getInventory():getCountTypeRecurse(fullType)
end

local function startCraft(r)
    local recipe = getScriptManager():getCraftRecipe(r.name)
    if not recipe then
        rec(false, r.name .. ": recipe not found")
        return false
    end
    -- AnySurfaceCraft recipes need a craft surface within 3 tiles, passed to the logic
    -- as the crafting window does (BaseCraftingLogic.canPerformCurrentRecipe).
    local logic = HandcraftLogic.new(p, nil, surface)
    -- The crafting window always works in manual input mode and fills the inputs itself
    -- (ISHandCraftPanel.lua:166, 355); FromLogic needs it (convertToPZNetTable of the inputs).
    logic:setManualSelectInputs(true)
    logic:setContainers(ISInventoryPaneContextMenu.getContainers(p))
    logic:setRecipe(recipe)
    logic:autoPopulateInputs()
    local can = logic:canPerformCurrentRecipe()
    lines[#lines + 1] = "INFO " .. r.name .. ": canPerformCurrentRecipe = " .. tostring(can)
        .. ", known = " .. tostring(p:isRecipeKnown(recipe))
    if not can then
        rec(false, r.name .. ": cannot be performed with the given items")
        return false
    end
    local action = ISHandcraftAction.FromLogic(logic)
    ISTimedActionQueue.add(action)
    state.action = action
    state.before = count(r.out)
    state.maxDelta = 0
    state.t0 = getTimestampMs()
    return true
end

function H.start(ctx)
    p = getPlayer()
    if not p then return false, "no player" end
    p:setPerkLevelDebug(Perks.Electricity, 3)
    for _, r in ipairs(RECIPES) do p:getKnownRecipes():add(r.name) end
    for _, t in ipairs(INPUTS) do p:getInventory():AddItem(t) end
    for _ = 1, #RECIPES do
        for _, t in ipairs(PER_CRAFT) do p:getInventory():AddItem(t) end
    end
    lines[#lines + 1] = "INFO mods: Live Wire loaded = " .. tostring(LiveWire ~= nil)
    return true
end

-- A generic craft surface (table, counter) near the player, or nil.
local function findSurface(radius)
    local cell = getCell()
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for r = 0, radius do
        for x = px - r, px + r do
            for y = py - r, py + r do
                local sq = cell:getGridSquare(x, y, pz)
                local objs = sq and sq:getObjects()
                if objs then
                    for i = 0, objs:size() - 1 do
                        if objs:get(i):isGenericCraftingSurface() then return objs:get(i) end
                    end
                end
            end
        end
    end
    return nil
end

-- A walkable square next to the surface.
local function besideSurface(obj)
    local sq = obj:getSquare()
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local s = getCell():getGridSquare(sq:getX() + d[1], sq:getY() + d[2], sq:getZ())
        if s and s:isFree(false) and sq:canReachTo(s) then return s end
    end
    return nil
end

function H.done(ctx)
    if state.phase == "seek" then
        local obj = findSurface(30)
        local spot = obj and besideSurface(obj)
        if not spot then
            rec(false, "no craft surface (table, counter) within 30 tiles of the save's player")
            return true
        end
        p:setX(spot:getX() + 0.5)
        p:setY(spot:getY() + 0.5)
        p:setLastX(p:getX())
        p:setLastY(p:getY())
        surface = obj
        lines[#lines + 1] = "INFO craft surface: " .. tostring(obj:getSprite():getName())
        state.phase = "settle"
        state.t0 = getTimestampMs()
        return false
    end
    if state.phase == "settle" then
        if getTimestampMs() - state.t0 > 1500 then state.phase = "next" end
        return false
    end
    if state.phase == "next" then
        state.i = state.i + 1
        local r = RECIPES[state.i]
        if not r then return true end
        if startCraft(r) then state.phase = "run" else state.phase = "next" end
        return false
    end
    local r = RECIPES[state.i]
    local a = state.action
    if a and a.getJobDelta then
        local d = a:getJobDelta() or 0
        if d > state.maxDelta then state.maxDelta = d end
    end
    local queue = ISTimedActionQueue.getTimedActionQueue(p)
    local busy = queue and queue.queue and #queue.queue > 0
    local made = count(r.out) > (state.before or 0)
    if made and not busy then
        rec(true, string.format("%s: %s created (max progress %d %%)", r.name, r.out, math.floor(state.maxDelta * 100 + 0.5)))
        state.phase = "next"
    elseif not busy then
        rec(false, string.format("%s: action ended without %s (max progress %d %%)", r.name, r.out,
            math.floor(state.maxDelta * 100 + 0.5)))
        state.phase = "next"
    elseif getTimestampMs() - state.t0 > LIMIT_MS then
        rec(false, string.format("%s: still running after %d s (max progress %d %%)", r.name, LIMIT_MS / 1000,
            math.floor(state.maxDelta * 100 + 0.5)))
        ISTimedActionQueue.clear(p)
        state.phase = "next"
    end
    return false
end

function H.result(ctx)
    return { ok = okAll, summary = okAll and "vanilla crafts OK" or "vanilla craft failure", lines = lines }
end

return H
