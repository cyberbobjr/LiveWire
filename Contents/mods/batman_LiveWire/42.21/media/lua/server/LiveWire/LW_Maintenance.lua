-- Live Wire: authoritative maintenance hazards and salvage.
if isClient() then return end
require "LiveWire/LW_Stack"
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
        player:dropHeldItems(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()), false, false)
    else player:dropHandItems() end
    -- Native item move, no replacement item: abort before consuming repair materials.
    LiveWire.notify(player, "IGUI_LW_Shock", {}, true)
    if LiveWire.Journal then LiveWire.Journal.add(grid, "IGUI_LW_Event_Shock") end
    return true
end

function Maintenance.salvage(player, obj)
    local R = LiveWire.Registry
    if not R or not R.ready or R.readOnly or not player or player:isDead() then return false end
    local m = LiveWire.Marks.get(obj)
    local dev = m and LiveWire.Registry.device(m.id)
    if not dev or (dev.cond or 100) > 0 then return false end
    if not LiveWire.Stack.canMove(obj) then return false end
    if LiveWire.Devices.find(dev) ~= obj or LiveWire.Defs.modelOfObject(obj) ~= dev.model then return false end
    local sq = obj:getSquare()
    if not sq or obj:getObjectIndex() == -1 or not LiveWire.Commands.checkDevice(player, dev.id, 2)
        or not LiveWire.Install.hasLevel(player, 3) or not LiveWire.Install.screwdriver(player)
        or not LiveWire.Batteries.isEmpty(obj) then return false end
    if dev.role == "inverter" and (dev.state == "on" or dev.coupled) then return false end
    local grid = dev.grid and LiveWire.Registry.grid(dev.grid)
    if Maintenance.liveWork(player, grid) then return false end
    local model = dev.model
    LiveWire.Devices.remove(dev.id)
    sq:transmitRemoveItemFromSquare(obj)
    LiveWire.Install.giveItem(player, "Base.ElectronicsScrap")
    LiveWire.Install.giveItem(player, "Base.ElectricWire")
    if model == "SolarPanel" then LiveWire.Install.giveItem(player, "LiveWire.SolarCell") end
    LiveWire.Xp.award(player, 3)
    return true
end
