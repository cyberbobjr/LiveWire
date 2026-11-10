-- Live Wire: authoritative maintenance hazards.
if isClient() then return end
LiveWire = LiveWire or {}
local Maintenance = {}
LiveWire.Maintenance = Maintenance

function Maintenance.shockChance(level)
    return math.floor(50 * math.max(0, 6 - level) / 6 + 0.5)
end

function Maintenance.liveWork(player, grid)
    if not grid or not LiveWire.Config.get("LiveWorkRisk") then return false end
    local inv = LiveWire.Registry.device(grid.inverter)
    local level = LiveWire.Install.level(player)
    -- Breakers isolate the downstream supply, not the inverter's terminals.
    -- Empty batteries, a trip or a fault are not an explicit isolation either.
    if not inv or inv.state == "off" or level >= 6 then return false end
    if ZombRand(100) >= Maintenance.shockChance(level) then return false end
    local hand = player:getBodyDamage():getBodyPart(LiveWire.Install.screwdriverHand(player))
    hand:setAdditionalPain(math.max(hand:getAdditionalPain(), 10))
    hand:setBurnTime(math.max(hand:getBurnTime(), 5))
    if isServer() then
        sendDamage(player)
        -- 42.22 replaced dropHeldItems(x, y, z, heavy, throw) with dropHeldItemsServer() (both held
        -- items, on the player's square); 42.21 only has the former.
        if player.dropHeldItemsServer then player:dropHeldItemsServer()
        else player:dropHeldItems(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()), false, false) end
    else player:dropHandItems() end
    -- Native item move, no replacement item: abort before consuming repair materials.
    LiveWire.notify(player, "IGUI_LW_Shock", {}, true)
    if LiveWire.Journal then LiveWire.Journal.add(grid, "IGUI_LW_Event_Shock") end
    return true
end
