-- Live Wire: water transfer of the pumps (authority only). Linked barrels, the relays
-- that need water, the litres moved each minute and their client synchronisation.
-- Attached to LiveWire.Pump (LW_Pump.lua): every function is called as Pump.xxx.
if isClient() then return end
require "LiveWire/LW_PumpRelays"

LiveWire = LiveWire or {}

local Pump = LiveWire.Pump
local Defs = LiveWire.Defs

-- Session memory of the last barrel sync (the relay one is Pump.relaySynced, dropped
-- when a relay is removed). Barrel entries are dropped when a pump is forgotten.
local barrelSyncedAt = {} -- posKey -> world age (minutes) of the last sync

-- Barrel object of a stored position. Returns obj, true when the square is loaded
-- (obj nil when the barrel is gone); nil, false when the square is not loaded.
function Pump.findBarrel(dev, key)
    local b = dev.barrels and dev.barrels[key]
    if not b then return nil, false end
    local sq = getCell():getGridSquare(b.x, b.y, b.z)
    if not sq then return nil, false end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local m = LiveWire.Install.barrelMark(o)
        if m and m.pump == dev.id then return o, true end
    end
    return nil, true
end

-- Link a barrel (a water container next to the pump) to this pump.
function Pump.linkBarrel(dev, barrel)
    local sq = barrel:getSquare()
    if not sq then return end
    local key = LiveWire.posKey(sq:getX(), sq:getY(), sq:getZ())
    dev.barrels[key] = { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
    barrel:getModData()[Defs.BARREL_KEY] = { pump = dev.id, x = sq:getX(), y = sq:getY(), z = sq:getZ() }
    if isServer() then barrel:transmitModData() end
    LiveWire.Devices.syncMark(dev)
    Pump.maintain(dev)
end

-- Unlink the barrel stored under `key` (its mark is cleared when it is loaded).
function Pump.unlinkBarrel(dev, key)
    local obj = Pump.findBarrel(dev, key)
    if obj then
        obj:getModData()[Defs.BARREL_KEY] = nil
        if isServer() then obj:transmitModData() end
    end
    dev.barrels[key] = nil
    dev.missingBarrel = dev.missingBarrel or {}
    dev.missingBarrel[key] = nil
    LiveWire.Devices.syncMark(dev)
    Pump.maintain(dev)
end

-- Drop the barrels that are gone (or no longer marked for this pump) on a loaded
-- square, after two consecutive checks. Returns true when the list changed.
function Pump.checkBarrels(dev)
    local changed = false
    dev.missingBarrel = dev.missingBarrel or {}
    local keys = {}
    for key in pairs(dev.barrels) do keys[#keys + 1] = key end
    for i = 1, #keys do
        local key = keys[i]
        local obj, loaded = Pump.findBarrel(dev, key)
        if loaded and not obj then
            dev.missingBarrel[key] = (dev.missingBarrel[key] or 0) + 1
            if dev.missingBarrel[key] >= 2 then
                LiveWire.log("barrel " .. key .. " is gone from pump " .. dev.id .. ", unlinking it")
                dev.barrels[key] = nil
                dev.missingBarrel[key] = nil
                changed = true
            end
        elseif loaded then
            dev.missingBarrel[key] = nil
        end
    end
    return changed
end

-- Linked barrels that can give water now, largest amount first.
function Pump.sourcesOf(dev)
    local list = {}
    for key in pairs(dev.barrels) do
        local obj = Pump.findBarrel(dev, key)
        if obj and LiveWire.Install.barrelState(obj) == "ok" then
            local fc = obj:getFluidContainer()
            if fc:getAmount() > Defs.PUMP_FLUID_EPSILON then
                list[#list + 1] = { obj = obj, fc = fc, amount = fc:getAmount() }
            end
        end
    end
    table.sort(list, function(a, b) return a.amount > b.amount end)
    return list
end

-- True when a plumbed fixture (getUsesExternalWaterSource) on the floor below, on the
-- relay's square or one of the 8 around it, draws its water from this relay. An empty
-- relay is enough to offer "Plumb" (IsoObject.FindExternalWaterSource returns the first
-- empty source), so a relay that feeds no plumbed fixture is left unfilled. Checked each
-- minute for relays that are not full only: at most 9 squares per relay, so a fixture
-- plumbed by a player is supplied from the next minute without waiting for the
-- inventory rebuild.
function Pump.feedsPlumbedFixture(x, y, z)
    local cell = getCell()
    for oy = -1, 1 do
        for ox = -1, 1 do
            local sq = cell:getGridSquare(x + ox, y + oy, z - 1)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    local spr = o:getSprite()
                    local props = spr and spr:getProperties()
                    if not instanceof(o, "IsoWorldInventoryObject") and props
                        and props:has(IsoFlagType.waterPiped) and o:getUsesExternalWaterSource() then
                        local src = IsoObject.FindExternalWaterSource(sq)
                        local ss = src and LiveWire.Install.isRelay(src) and src:getSquare()
                        if ss and ss:getX() == x and ss:getY() == y and ss:getZ() == z then return true end
                    end
                end
            end
        end
    end
    return false
end

-- Loaded relays of the pump that feed a plumbed fixture, with their free capacity, and
-- the total. Water already in an unused relay stays there.
function Pump.needsOf(dev)
    local list, total = {}, 0
    local keys = {}
    for key in pairs(dev.relays) do keys[#keys + 1] = key end
    table.sort(keys)
    for i = 1, #keys do
        local r = dev.relays[keys[i]]
        local relay = Pump.findRelay(r.x, r.y, r.z)
        local mark = relay and relay:getModData()[Defs.RELAY_KEY]
        if mark and mark.pump == dev.id then
            local fc = relay:getFluidContainer()
            local need = fc:getFreeCapacity()
            if need > Defs.PUMP_FLUID_EPSILON and Pump.feedsPlumbedFixture(r.x, r.y, r.z) then
                list[#list + 1] = { obj = relay, fc = fc, need = need, key = keys[i], before = fc:getAmount() }
                total = total + need
            end
        end
    end
    return list, total
end

-- Relay and barrel synchronisation (C03). obj:sync() makes every nearby client
-- recalculate paths and lighting of the square (IsoThumpable.syncIsoObjectReceive),
-- and the client plumbing only needs to know whether water is left. A relay is synced
-- when it stops being empty, becomes full, or SYNC_LITRES moved since its last sync;
-- a barrel at most every BARREL_SYNC_MINUTES, or when it becomes empty.
-- Session memory only: after a restart the first transfer syncs.
Pump.SYNC_LITRES = 5
Pump.BARREL_SYNC_MINUTES = 10
local function syncRelay(rn)
    local amount = rn.fc:getAmount()
    local last = Pump.relaySynced[rn.key]
    if rn.before <= Defs.PUMP_FLUID_EPSILON or rn.fc:getFreeCapacity() <= Defs.PUMP_FLUID_EPSILON or last == nil
        or math.abs(amount - last) >= Pump.SYNC_LITRES then
        rn.obj:sync()
        Pump.relaySynced[rn.key] = amount
    end
end

local function syncBarrel(src)
    local sq = src.obj:getSquare()
    local key = sq and LiveWire.posKey(sq:getX(), sq:getY(), sq:getZ()) or tostring(src.obj)
    local now = getGameTime():getWorldAgeHours() * 60
    local last = barrelSyncedAt[key]
    if src.fc:getAmount() <= Defs.PUMP_FLUID_EPSILON or last == nil or now - last >= Pump.BARREL_SYNC_MINUTES
        or now < last then
        src.obj:sync()
        barrelSyncedAt[key] = now
    end
end

-- Move up to dev.budget litres from the barrels (`sources`, largest first) to the
-- relays that need water (`needs`). Returns the litres moved; updates dev.budget and
-- dev.pumped.
function Pump.moveWater(dev, needs, sources)
    local moved = 0
    local touchedRelays, touchedBarrels = {}, {}
    for _, rn in ipairs(needs) do
        local want = math.min(rn.need, dev.budget - moved)
        for _, src in ipairs(sources) do
            if want <= Defs.PUMP_FLUID_EPSILON then break end
            local n = math.min(want, src.fc:getAmount())
            if n > Defs.PUMP_FLUID_EPSILON then
                -- Tainted water stays tainted in the relay (the tap purifies it, as
                -- vanilla), in the barrel's own proportion: a trace never taints it all.
                local inBarrel = src.fc:getAmount()
                local tainted = inBarrel > 0
                    and math.min(n, n * src.fc:getSpecificFluidAmount(Fluid.TaintedWater) / inBarrel) or 0
                src.fc:removeFluid(n)
                if n - tainted > 0 then rn.fc:addFluid(Fluid.Water, n - tainted) end
                if tainted > 0 then rn.fc:addFluid(Fluid.TaintedWater, tainted) end
                touchedBarrels[src.obj] = src
                touchedRelays[rn.obj] = rn
                moved = moved + n
                want = want - n
            end
        end
    end
    for _, rn in pairs(touchedRelays) do syncRelay(rn) end
    for _, src in pairs(touchedBarrels) do syncBarrel(src) end
    dev.budget = dev.budget - moved
    dev.pumped = (dev.pumped or 0) + moved
    return moved
end

-- A pump is removed: the barrel sync memory is cleared and the barrel marks of loaded
-- barrels are cleared.
function Pump.releaseBarrels(dev)
    barrelSyncedAt = {}
    local barrels = {}
    for key in pairs(dev.barrels or {}) do barrels[#barrels + 1] = key end
    for i = 1, #barrels do
        local obj = Pump.findBarrel(dev, barrels[i])
        if obj then
            obj:getModData()[Defs.BARREL_KEY] = nil
            if isServer() then obj:transmitModData() end
        end
    end
end
