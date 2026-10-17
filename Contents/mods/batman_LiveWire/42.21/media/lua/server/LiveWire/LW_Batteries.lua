-- Live Wire: batteries lying on the floor, linked to an inverter (authority only).
-- Charge lives in the item uses (0..1 of the effective capacity), wear in its
-- condition: both travel to clients with item:syncItemFields() on the server
-- (ItemStats packet, notes-moteur.md note 10). The device mark lives in the item
-- ModData, which is saved with the world item.
if isClient() then return end

LiveWire = LiveWire or {}

local Batteries = {}
LiveWire.Batteries = Batteries

function Batteries.def(fullType)
    return LiveWire.Defs.batteries[fullType]
end

function Batteries.capacity(dev, cond)
    local def = Batteries.def(dev.model)
    if not def then return 0 end
    return LiveWire.Physics.batteryCapacity(def.capacityKWh, cond,
        LiveWire.Config.get("BatteryCapacityMultiplier"))
end

-- Locate the linked world item. Returns worldObject, item, square (nil when the
-- square is not loaded; worldObject nil when the battery was picked up).
function Batteries.find(dev)
    local sq = getCell():getGridSquare(dev.x, dev.y, dev.z)
    if not sq then return nil, nil, nil end
    local w, item = LiveWire.Marks.findBatteryOnSquare(sq, dev.id)
    return w, item, sq
end

-- Read the live state of a battery into a physics entry.
-- Returns entry or nil (picked up). `loaded` tells whether the item was read.
function Batteries.read(dev)
    local w, item, sq = Batteries.find(dev)
    if sq and not w then return nil, true end
    local entry = { dev = dev, item = item }
    if item then
        entry.cond = item:getCondition()
        entry.capacity = Batteries.capacity(dev, entry.cond)
        entry.charge = item:getCurrentUsesFloat() * entry.capacity
    else
        entry.cond = dev.cond or 100
        entry.capacity = Batteries.capacity(dev, entry.cond)
        entry.charge = (dev.charge or 0) * entry.capacity
    end
    entry.before = entry.charge
    return entry, item ~= nil
end

-- Write a physics entry back to the registry and, when loaded, to the item.
function Batteries.write(entry)
    local dev = entry.dev
    local frac = 0
    if entry.capacity > 0 then frac = LiveWire.clamp(entry.charge / entry.capacity, 0, 1) end
    dev.charge = frac
    dev.cond = entry.cond
    local item = entry.item
    if item then
        local oldFrac = item:getCurrentUsesFloat()
        local oldCond = item:getCondition()
        local newCond = math.floor(entry.cond + 0.5)
        local changed = math.abs(oldFrac - frac) >= 0.005 or oldCond ~= newCond
        item:setCurrentUsesFloat(frac)
        if oldCond ~= newCond then item:setConditionNoSound(newCond) end
        if changed and isServer() then item:syncItemFields() end
    end
end

-- Push the registry snapshot onto the item when its square has just loaded:
-- nobody could touch it while unloaded.
function Batteries.restore(dev)
    local _, item = Batteries.find(dev)
    if not item then return end
    item:setCurrentUsesFloat(LiveWire.clamp(dev.charge or 0, 0, 1))
    item:setConditionNoSound(math.floor((dev.cond or item:getCondition()) + 0.5))
    if isServer() then item:syncItemFields() end
end

-- Create the device for a world battery item; returns dev or nil, reasonKey.
function Batteries.register(worldObj, grid, linkerLevel)
    local item = worldObj:getItem()
    if not item or not Batteries.def(item:getFullType()) then
        return nil, "Tooltip_LW_NotABattery"
    end
    if item:getCondition() <= 0 then return nil, "Tooltip_LW_DeadBattery" end
    local sq = worldObj:getSquare()
    local mark = LiveWire.Marks.getItem(item)
    local dev = mark and LiveWire.Registry.device(mark.id)
    if dev then
        LiveWire.Registry.moveDevice(dev, sq:getX(), sq:getY(), sq:getZ())
    else
        dev = LiveWire.Registry.addDevice({
            role = "battery", model = item:getFullType(),
            x = sq:getX(), y = sq:getY(), z = sq:getZ(),
        })
        LiveWire.Marks.set(item, dev.id, dev.model)
    end
    dev.cond = item:getCondition()
    dev.charge = item:getCurrentUsesFloat()
    dev.wearFactor = LiveWire.Defs.batteryWearSkillFactor(linkerLevel)
    dev.cycles = dev.cycles or 0
    LiveWire.Registry.link(dev, grid)
    return dev
end

-- Forget a battery that was picked up (its energy left with the item).
function Batteries.forget(dev, item)
    if item then LiveWire.Marks.clear(item) end
    LiveWire.Registry.removeDevice(dev.id)
end
