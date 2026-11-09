-- Live Wire: relay tanks of the water pumps (authority only). Life cycle of the relays
-- (place, remove, claim, release), the relays a pump wants, and the discovery of the
-- plumbed fixtures around a pump. Attached to LiveWire.Pump (LW_Pump.lua): every
-- function is called as Pump.xxx.
if isClient() then return end
require "LiveWire/LW_Pump"
require "LiveWire/LW_SquareScan"
require "LiveWire/LW_CircuitProvider"
require "LiveWire/LW_EventBus"

LiveWire = LiveWire or {}

local Pump = LiveWire.Pump
local Defs = LiveWire.Defs

local function R() return LiveWire.Registry end

local hasAny = Pump.hasAny
local countOf = Pump.countOf

-- The relay object on a square, or nil.
function Pump.findRelay(x, y, z)
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return nil end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if LiveWire.Install.isRelay(o) then return o end
    end
    return nil
end

-- Create a relay tank on the square (x, y, z) above a fixture.
function Pump.placeRelay(dev, x, y, z)
    local cell = getCell()
    local sq = cell:getGridSquare(x, y, z)
    if not sq then sq = cell:createNewGridSquare(x, y, z, true) end   -- IsoCell.java:3847
    if not sq or Pump.findRelay(x, y, z) then return end
    local relay = IsoThumpable.new(cell, sq, Defs.RELAY_SPRITE, false)
    relay:setIsThumpable(false)
    relay:setCanPassThrough(true)
    relay:setBlockAllTheSquare(false)
    relay:setIsDismantable(false)
    relay:setCanBarricade(false)
    local fc = ComponentType.FluidContainer:CreateComponent()
    fc:setCapacity(Defs.RELAY_LITRES)
    fc:setContainerName("LiveWireRelay")
    GameEntityFactory.AddComponent(relay, true, fc)
    relay:getModData()[Defs.RELAY_KEY] = { pump = dev.id }
    sq:transmitAddObjectToSquare(relay, -1)
    dev.relays[LiveWire.posKey(x, y, z)] = { x = x, y = y, z = z }
    LiveWire.log("relay placed at " .. LiveWire.posKey(x, y, z) .. " for pump " .. dev.id)
end

-- Remove one relay of the pump. An unloaded square keeps the entry (cleaned later
-- by onLoadChunk).
function Pump.removeRelay(dev, key)
    local r = dev.relays[key]
    if not r then return end
    local sq = getCell():getGridSquare(r.x, r.y, r.z)
    if not sq then return end
    local relay = Pump.findRelay(r.x, r.y, r.z)
    local m = relay and relay:getModData()[Defs.RELAY_KEY]
    if m and m.pump == dev.id then sq:transmitRemoveItemFromSquare(relay) end
    Pump.relaySynced[key] = nil
    dev.relays[key] = nil
end

-- A fixture on the public water grid needs no relay while the grid still runs.
local function gridRuns(obj)
    if obj:getUsesExternalWaterSource() then return false end
    local opt = getSandboxOptions():getOptionByName("WaterShutModifier")
    local shut = opt and opt:getValue() or 0
    return getGameTime():getWorldAgeDaysSinceBegin() < shut
end

-- Relays the pump wants: the square above each plumbed fixture (IsoFlagType.waterPiped)
-- that has no water source above it, or whose source is one of this pump's relays.
-- Other sources (vanilla barrel, other mod, another pump) take precedence.
-- The served area is a horizontal circle of PumpRange tiles (sandbox option), on the
-- floors given by Config.verticalRange().
Pump.SQUARES_PER_TICK = 250
Pump.REBUILD_HOURS = 2
Pump.inventories = {} -- session only: fixture positions, discovery cursor, dirty flag
local queue = {}

-- Called on every removed object and every placement: leave at once while no pump has
-- an inventory (Pump.inventories can be replaced, so it is read here each time).
function Pump.invalidateAt(sq, margin)
    if not sq then return end
    if not hasAny(Pump.inventories) then return end
    local range = LiveWire.Config.get("PumpRange") + (margin or 0)
    for id, entry in pairs(Pump.inventories) do
        local dev = R().device(id)
        if dev then
            local dx, dy = sq:getX() - dev.x, sq:getY() - dev.y
            if dx * dx + dy * dy <= range * range then entry.dirty = true end
        end
    end
end

local function inventory(dev)
    local entry = Pump.inventories[dev.id]
    if not entry then
        entry = { fixtures = {}, dirty = true, builtAt = -1 }
        Pump.inventories[dev.id] = entry
    end
    local range, vertical = LiveWire.Config.get("PumpRange"), LiveWire.Config.verticalRange()
    if entry.x ~= dev.x or entry.y ~= dev.y or entry.z ~= dev.z
        or entry.range ~= range or entry.vertical ~= vertical then entry.dirty = true end
    local now = getGameTime():getWorldAgeHours()
    if (entry.dirty or now - entry.builtAt >= Pump.REBUILD_HOURS) and not entry.job then
        entry.x, entry.y, entry.z = dev.x, dev.y, dev.z
        entry.range, entry.vertical = range, vertical
        entry.job = LiveWire.SquareScan.new(dev.x, dev.y, dev.z, range, vertical)
        entry.found, entry.dirty = {}, false
        queue[#queue + 1] = dev.id
    end
    return entry
end

-- Candidates are read from nearby chunk buckets once per maintenance, never from
-- the whole server registry for each tap. Power/fuel do not change ownership.
local function candidates(dev)
    local reach = LiveWire.Config.get("PumpRange") * 2 + 2
    local out = {}
    for cx = math.floor((dev.x - reach) / 8), math.floor((dev.x + reach) / 8) do
        for cy = math.floor((dev.y - reach) / 8), math.floor((dev.y + reach) / 8) do
            local list = R().devicesInChunk(cx, cy)
            for i = 1, #list do
                local p = list[i]
                if p.role == "pump" and p.grid and R().grid(p.grid)
                    and (p.cond or 100) > 0 and hasAny(p.barrels) then
                    out[#out + 1] = p
                end
            end
        end
    end
    return out
end

-- A shared relay is assigned from the fixture square directly below it. This
-- canonical point prevents neighbouring taps from transferring it back and forth.
local function closest(list, x, y, z)
    local best, distance
    local range, vertical = LiveWire.Config.get("PumpRange"), LiveWire.Config.verticalRange()
    for i = 1, #list do
        local p = list[i]
        local dx, dy, dz = p.x - x, p.y - y, p.z - z
        local d = dx * dx + dy * dy + dz * dz
        if dx * dx + dy * dy <= range * range and math.abs(dz) <= vertical
            and (not best or d < distance or (d == distance and p.id < best.id)) then
            best, distance = p, d
        end
    end
    return best
end

local function claimRelay(dev, relay)
    local sq = relay:getSquare()
    local key = LiveWire.posKey(sq:getX(), sq:getY(), sq:getZ())
    local mark = relay:getModData()[Defs.RELAY_KEY]
    local previous = mark and R().device(mark.pump)
    if previous and previous.id ~= dev.id and previous.relays then
        previous.relays[key] = nil
        LiveWire.Devices.syncMark(previous)
    end
    dev.relays[key] = { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
    if not mark or mark.pump ~= dev.id then
        relay:getModData()[Defs.RELAY_KEY] = { pump = dev.id }
        if isServer() then relay:transmitModData() end
    end
end

-- True when a wanted relay already stands on the square above (x, y), or above one of
-- its 8 neighbours (one relay serves the taps around it).
local function sharedAbove(wanted, x, y, z)
    for ox = -1, 1 do
        for oy = -1, 1 do
            if wanted[LiveWire.posKey(x + ox, y + oy, z + 1)] then return true end
        end
    end
    return false
end

-- True when the square holds a plumbed fixture that the public water grid does not serve.
local function hasPipedFixture(sq)
    local objs = sq:getObjects()
    for j = 0, objs:size() - 1 do
        local o = objs:get(j)
        local spr = o:getSprite()
        local props = spr and spr:getProperties()
        if not instanceof(o, "IsoWorldInventoryObject") and props
            and props:has(IsoFlagType.waterPiped) and not gridRuns(o) then
            return true
        end
    end
    return false
end

-- The relay wanted for the fixture standing on (x, y, z), added to `wanted` when this
-- pump is the one that owns it.
local function addWanted(dev, wanted, nearby, sq, x, y, z)
    local src = IsoObject.FindExternalWaterSource(sq)
    local owner = closest(nearby, x, y, z)
    if not src and z < 31 and owner and owner.id == dev.id then
        wanted[LiveWire.posKey(x, y, z + 1)] = { x = x, y = y, z = z + 1 }
    elseif src and LiveWire.Install.isRelay(src) then
        local ss = src:getSquare()
        owner = ss and closest(nearby, ss:getX(), ss:getY(), ss:getZ() - 1)
        if owner and owner.id == dev.id then
            wanted[LiveWire.posKey(ss:getX(), ss:getY(), ss:getZ())] =
                { x = ss:getX(), y = ss:getY(), z = ss:getZ() }
        end
    end
end

-- Re-evaluate only known fixtures; source ownership and public water can change
-- without furniture moving. Preserve the original stable x/y/z discovery order.
local function wantedRelays(dev, linked, nearby)
    local wanted = {}
    if not linked then return wanted end
    local entry = inventory(dev)
    -- On reload the saved relays are valid, but the session inventory is empty.
    -- An unfinished first discovery must never be mistaken for "no more taps".
    if entry.job and #entry.fixtures == 0 then return nil end
    for i = 1, #entry.fixtures do
        local pos = entry.fixtures[i]
        local x, y, z = pos.x, pos.y, pos.z
        local sq = getCell():getGridSquare(x, y, z)
        local dx, dy = x - dev.x, y - dev.y
        if sq and sq:getRoom() and dx * dx + dy * dy <= entry.range * entry.range
            and math.abs(z - dev.z) <= entry.vertical
            and hasPipedFixture(sq) and not sharedAbove(wanted, x, y, z) then
            addWanted(dev, wanted, nearby, sq, x, y, z)
        end
    end
    return wanted
end

function Pump.tickDiscovery()
    if not R() or not R().ready or R().readOnly then return end
    local budget = Pump.SQUARES_PER_TICK
    while budget > 0 and #queue > 0 do
        local id = queue[1]
        local dev, entry = R().device(id), Pump.inventories[id]
        if not dev or not entry or not entry.job or Pump.disabled() then
            table.remove(queue, 1)
            Pump.inventories[id] = nil
        else
            local done, used = LiveWire.SquareScan.step(entry.job, budget, function(x, y, z)
                local sq = getCell():getGridSquare(x, y, z)
                if not sq or not sq:getRoom() then return end
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local obj = objs:get(i)
                    local spr = obj:getSprite()
                    local props = spr and spr:getProperties()
                    if not instanceof(obj, "IsoWorldInventoryObject") and props
                        and props:has(IsoFlagType.waterPiped) then
                        entry.found[#entry.found + 1] = { x = x, y = y, z = z }
                        break
                    end
                end
            end)
            budget = budget - used
            if done then
                entry.job = nil
                entry.fixtures, entry.found = entry.found, nil
                entry.builtAt = getGameTime():getWorldAgeHours()
                table.remove(queue, 1)
                Pump.maintain(dev)
            end
        end
    end
end

-- Place the wanted relays, remove the loaded ones that are no longer wanted.
function Pump.maintain(dev)
    if not dev or dev.role ~= "pump" or not dev.relays then return end
    if Pump.disabled() then return end
    if not getCell():getGridSquare(dev.x, dev.y, dev.z) then return end
    local before = countOf(dev.relays)
    local grid = dev.grid and R().grid(dev.grid)
    local linked = grid ~= nil and hasAny(dev.barrels) and (dev.cond or 100) > 0
    local nearby = candidates(dev)
    local wanted = wantedRelays(dev, linked, nearby)
    if not wanted then return end
    local keys = {}
    for key in pairs(wanted) do keys[#keys + 1] = key end
    table.sort(keys)
    for i = 1, #keys do
        local w = wanted[keys[i]]
        local relay = Pump.findRelay(w.x, w.y, w.z)
        if relay then claimRelay(dev, relay) else Pump.placeRelay(dev, w.x, w.y, w.z) end
        dev.relays[keys[i]] = { x = w.x, y = w.y, z = w.z }
    end
    local old = {}
    for key in pairs(dev.relays) do old[#old + 1] = key end
    for i = 1, #old do
        if not wanted[old[i]] then
            local pos = dev.relays[old[i]]
            local relay = pos and Pump.findRelay(pos.x, pos.y, pos.z)
            local owner = pos and closest(nearby, pos.x, pos.y, pos.z - 1)
            if relay and owner and owner.id ~= dev.id then
                claimRelay(owner, relay)
                LiveWire.Devices.syncMark(owner)
            else
                Pump.removeRelay(dev, old[i])
            end
        end
    end
    -- The mark shows the relay count (nr) to the clients.
    if countOf(dev.relays) ~= before then LiveWire.Devices.syncMark(dev) end
end

-- A pump is removed: its inventory goes, and each of its relays passes to the closest
-- other pump that can serve it, or is removed.
function Pump.releaseRelays(dev)
    Pump.inventories[dev.id] = nil
    local nearby, remaining = candidates(dev), {}
    for i = 1, #nearby do
        if nearby[i].id ~= dev.id then remaining[#remaining + 1] = nearby[i] end
    end
    local keys = {}
    for key in pairs(dev.relays or {}) do keys[#keys + 1] = key end
    for i = 1, #keys do
        Pump.relaySynced[keys[i]] = nil
        local pos = dev.relays[keys[i]]
        local owner = closest(remaining, pos.x, pos.y, pos.z - 1)
        local relay = Pump.findRelay(pos.x, pos.y, pos.z)
        if owner and relay then
            claimRelay(owner, relay)
            LiveWire.Devices.syncMark(owner)
        else
            Pump.removeRelay(dev, keys[i])
        end
    end
end

Events.OnTick.Add(Pump.tickDiscovery)

-- Told by the placement wrappers (LW_EventBus.lua).
LiveWire.Events.on(LiveWire.Events.SQUARE_CHANGED, function(sq) return LiveWire.Pump.invalidateAt(sq) end)
