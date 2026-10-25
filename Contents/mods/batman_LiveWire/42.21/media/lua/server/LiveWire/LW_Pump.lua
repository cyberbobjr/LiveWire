-- Live Wire: water pump service (authority only, docs/annexes/conception/choix-et-extensions.md section 2).
-- A pump moves water from the water barrels linked to it into invisible relay tanks
-- (IsoThumpable with a FluidContainer) placed on the square ABOVE each plumbed fixture
-- it serves: vanilla plumbing finds the relay as an external water source
-- (IsoObject.FindExternalWaterSource). Only water is moved; the barrels' own
-- FluidContainer is never replaced. Runs every game minute (tickMinute) and on link
-- changes (maintain).
if isClient() then return end
require "LiveWire/LW_SquareScan"

LiveWire = LiveWire or {}

local Pump = {}
LiveWire.Pump = Pump

local Defs = LiveWire.Defs

local function R() return LiveWire.Registry end

-- `next` does not exist in Kahlua 42.21 (knowledge/kahlua-lua.md).
local function hasAny(t)
    if not t then return false end
    for _ in pairs(t) do return true end
    return false
end

local function countOf(t)
    local n = 0
    if t then
        for _ in pairs(t) do n = n + 1 end
    end
    return n
end

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

function Pump.invalidateAt(sq, margin)
    if not sq then return end
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
            and math.abs(z - dev.z) <= entry.vertical then
            local objs = sq:getObjects()
            for j = 0, objs:size() - 1 do
                local o = objs:get(j)
                local spr = o:getSprite()
                local props = spr and spr:getProperties()
                if not instanceof(o, "IsoWorldInventoryObject") and props
                    and props:has(IsoFlagType.waterPiped) and not gridRuns(o) then
                    local shared = false
                    for ox = -1, 1 do
                        for oy = -1, 1 do
                            if wanted[LiveWire.posKey(x + ox, y + oy, z + 1)] then shared = true end
                        end
                    end
                    if not shared then
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
                    break
                end
            end
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

-- Pumps disabled by the debug tool "remove every water relay" (before removing the
-- mod): no relay is placed and no water is moved until "enable the pumps again".
function Pump.disabled()
    local d = R() and R().data
    return d ~= nil and d.pumpsDisabled == true
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
local function checkBarrels(dev)
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
local function sourcesOf(dev)
    local list = {}
    for key in pairs(dev.barrels) do
        local obj = Pump.findBarrel(dev, key)
        if obj and LiveWire.Install.barrelState(obj) == "ok" then
            local fc = obj:getFluidContainer()
            if fc:getAmount() > 0.001 then
                list[#list + 1] = { obj = obj, fc = fc, amount = fc:getAmount() }
            end
        end
    end
    table.sort(list, function(a, b) return a.amount > b.amount end)
    return list
end

-- Loaded relays of the pump with their free capacity, and the total.
local function needsOf(dev)
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
            if need > 0.001 then
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
local relaySynced = {}    -- posKey -> litres at the last sync
local barrelSyncedAt = {} -- posKey -> world age (minutes) of the last sync

local function syncRelay(rn)
    local amount = rn.fc:getAmount()
    local last = relaySynced[rn.key]
    if rn.before <= 0.001 or rn.fc:getFreeCapacity() <= 0.001 or last == nil
        or math.abs(amount - last) >= Pump.SYNC_LITRES then
        rn.obj:sync()
        relaySynced[rn.key] = amount
    end
end

local function syncBarrel(src)
    local sq = src.obj:getSquare()
    local key = sq and LiveWire.posKey(sq:getX(), sq:getY(), sq:getZ()) or tostring(src.obj)
    local now = getGameTime():getWorldAgeHours() * 60
    local last = barrelSyncedAt[key]
    if src.fc:getAmount() <= 0.001 or last == nil or now - last >= Pump.BARREL_SYNC_MINUTES
        or now < last then
        src.obj:sync()
        barrelSyncedAt[key] = now
    end
end

local function setState(dev, state)
    if dev.state ~= state then
        dev.state = state
        LiveWire.Devices.syncMark(dev)
    end
end

-- One game minute of service for one pump.
function Pump.step(dev)
    if Pump.disabled() then return end
    if not getCell():getGridSquare(dev.x, dev.y, dev.z) then return end
    if checkBarrels(dev) then LiveWire.Devices.syncMark(dev) end

    local grid = dev.grid and R().grid(dev.grid)
    local inv = grid and R().device(grid.inverter)
    local powered = grid ~= nil and grid.powered == true and not grid.equipmentOff and inv ~= nil and inv.state == "on"
    if (dev.cond or 0) <= 0 then return setState(dev, "broken") end
    if not hasAny(dev.barrels) then return setState(dev, "nobarrel") end
    if not powered then return setState(dev, "nopower") end

    -- A minute of unused flow is not stored water. Clear legacy credits as well.
    dev.budget = 0
    local needs, total = needsOf(dev)
    if total < 0.01 then return setState(dev, "idle") end

    local sources = sourcesOf(dev)
    if #sources == 0 then return setState(dev, "nobarrel") end
    dev.budget = math.min(Defs.PUMP_BUDGET_MAX, Defs.PUMP_LITRES_PER_MINUTE)

    local moved = 0
    local touchedRelays, touchedBarrels = {}, {}
    for _, rn in ipairs(needs) do
        local want = math.min(rn.need, dev.budget - moved)
        for _, src in ipairs(sources) do
            if want <= 0.001 then break end
            local n = math.min(want, src.fc:getAmount())
            if n > 0.001 then
                -- Tainted water stays tainted in the relay: the tap purifies it, as vanilla.
                local tainted = src.fc:getSpecificFluidAmount(Fluid.TaintedWater) > 0
                src.fc:removeFluid(n)
                rn.fc:addFluid(tainted and Fluid.TaintedWater or Fluid.Water, n)
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

    if moved > 0.001 then
        setState(dev, "running")
        local radius = Defs.PUMP_NOISE_RADIUS
        if radius > 0 then addSound(nil, dev.x, dev.y, dev.z, radius, 1) end
    else
        setState(dev, "idle")
    end
end

-- Every game minute: each registry pump (loaded squares only, see Pump.step).
function Pump.tickMinute()
    local Rg = R()
    if not Rg or not Rg.ready or Rg.readOnly then return end
    local ids = {}
    for id, dev in pairs(Rg.devices()) do
        if dev.role == "pump" then ids[#ids + 1] = id end
    end
    table.sort(ids)
    for i = 1, #ids do
        local dev = Rg.device(ids[i])
        if dev then
            local ok, err = pcall(Pump.step, dev)
            if not ok then LiveWire.warn("pump " .. ids[i] .. " failed: " .. tostring(err)) end
        end
    end
end

-- Called by Sim.stepGrid: flow measured since the last step, duty and power demand
-- of the pumps (250 W at full duty). Resets the litres counter.
function Pump.demandW(pumps, dt)
    local w = 0
    for i = 1, #pumps do
        local dev = pumps[i]
        local pumped = dev.pumped or 0
        if dt > 0 then
            dev.flowLph = pumped / dt
            local duty = math.min(1, pumped / (Defs.PUMP_LITRES_PER_MINUTE * 60 * dt))
            local def = Defs.devices[dev.model]
            if def then w = w + def.pumpW * duty end
        else
            dev.flowLph = 0
        end
        dev.pumped = 0
    end
    return w
end

-- A pump is removed: its relays go, and the barrel marks of loaded barrels are cleared.
function Pump.forget(dev)
    Pump.inventories[dev.id] = nil
    local nearby, remaining = candidates(dev), {}
    for i = 1, #nearby do
        if nearby[i].id ~= dev.id then remaining[#remaining + 1] = nearby[i] end
    end
    local keys = {}
    for key in pairs(dev.relays or {}) do keys[#keys + 1] = key end
    for i = 1, #keys do
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

-- Chunk load: remove relays whose pump or entry is gone; clear barrel marks whose
-- pump no longer exists. Only the objects of the chunk are visited.
function Pump.onLoadChunk(chunk)
    local Rg = R()
    if not Rg or not Rg.ready or Rg.readOnly then return end
    local invalidated = false
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        if invalidated then break end
        for i = 0, 63 do
            local sq = chunk:getGridSquare(i % 8, math.floor(i / 8), z)
            if sq then Pump.invalidateAt(sq, 16); invalidated = true; break end
        end
    end
    local zMin = chunk:getMinLevel()
    local zMax = chunk:getMaxLevel()
    for z = zMin, zMax do
        for lx = 0, 7 do
            for ly = 0, 7 do
                local sq = chunk:getGridSquare(lx, ly, z)
                if sq then
                    local objs = sq:getObjects()
                    local doomed, clear = {}, {}
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if LiveWire.Install.isRelay(o) then
                            local m = o:getModData()[Defs.RELAY_KEY]
                            local dev = m and Rg.device(m.pump)
                            local key = LiveWire.posKey(sq:getX(), sq:getY(), sq:getZ())
                            if not dev or dev.role ~= "pump" or not dev.relays or not dev.relays[key] then
                                doomed[#doomed + 1] = o
                            end
                        elseif o.getModData and o:getModData()[Defs.BARREL_KEY] ~= nil then
                            if not LiveWire.Install.barrelMark(o) then clear[#clear + 1] = o end
                        end
                    end
                    for i = 1, #doomed do sq:transmitRemoveItemFromSquare(doomed[i]) end
                    for i = 1, #clear do
                        clear[i]:getModData()[Defs.BARREL_KEY] = nil
                        if isServer() then clear[i]:transmitModData() end
                    end
                end
            end
        end
    end
end

Events.EveryOneMinute.Add(Pump.tickMinute)

Events.OnTick.Add(Pump.tickDiscovery)
Events.OnObjectAboutToBeRemoved.Add(function(obj)
    if obj and obj.getSquare then Pump.invalidateAt(obj:getSquare()) end
end)
