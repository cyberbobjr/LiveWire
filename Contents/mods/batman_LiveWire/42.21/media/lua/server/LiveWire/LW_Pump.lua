-- Live Wire: water pump service (authority only, docs/annexes/recherches/idees-initiales.md section 2).
-- A pump moves water from the water barrels linked to it into invisible relay tanks
-- (IsoThumpable with a FluidContainer) placed on the square ABOVE each plumbed fixture
-- it serves: vanilla plumbing finds the relay as an external water source
-- (IsoObject.FindExternalWaterSource). Only water is moved; the barrels' own
-- FluidContainer is never replaced. Runs every game minute (tickMinute) and on link
-- changes (maintain).
if isClient() then return end

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
    if relay then sq:transmitRemoveItemFromSquare(relay) end
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
local function wantedRelays(dev, linked)
    local wanted = {}
    if not linked then return wanted end
    local cell = getCell()
    local range = LiveWire.Config.get("PumpRange")
    local r = math.floor(range)
    local vertical = LiveWire.Config.verticalRange()
    for z = dev.z - vertical, dev.z + vertical do
        for x = dev.x - r, dev.x + r do
            for y = dev.y - r, dev.y + r do
                local dx, dy = x - dev.x, y - dev.y
                if dx * dx + dy * dy <= range * range then
                    local sq = cell:getGridSquare(x, y, z)
                    if sq and sq:getRoom() ~= nil then
                        local objs = sq:getObjects()
                        for i = 0, objs:size() - 1 do
                            local o = objs:get(i)
                            local spr = o:getSprite()
                            local props = spr and spr:getProperties()
                            if not instanceof(o, "IsoWorldInventoryObject") and props
                                and props:has(IsoFlagType.waterPiped) and not gridRuns(o) then
                                local src = IsoObject.FindExternalWaterSource(sq)
                                -- One relay serves the 3x3 below it: a fixture already covered by
                                -- a relay wanted earlier in this scan needs no other one (this also
                                -- merges relays placed side by side by an older version).
                                local shared = false
                                for ox = -1, 1 do
                                    for oy = -1, 1 do
                                        if wanted[LiveWire.posKey(x + ox, y + oy, z + 1)] then shared = true end
                                    end
                                end
                                if shared then
                                    -- covered
                                elseif src == nil then
                                    wanted[LiveWire.posKey(x, y, z + 1)] = { x = x, y = y, z = z + 1 }
                                elseif LiveWire.Install.isRelay(src) then
                                    -- Keep the relay vanilla found (it may stand above a
                                    -- neighbouring fixture).
                                    local m = src:getModData()[Defs.RELAY_KEY]
                                    local ss = src:getSquare()
                                    if m and m.pump == dev.id and ss then
                                        wanted[LiveWire.posKey(ss:getX(), ss:getY(), ss:getZ())] =
                                            { x = ss:getX(), y = ss:getY(), z = ss:getZ() }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return wanted
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
    local linked = grid ~= nil and hasAny(dev.barrels)
    local wanted = wantedRelays(dev, linked)
    local keys = {}
    for key in pairs(wanted) do keys[#keys + 1] = key end
    table.sort(keys)
    for i = 1, #keys do
        local w = wanted[keys[i]]
        if not Pump.findRelay(w.x, w.y, w.z) then Pump.placeRelay(dev, w.x, w.y, w.z) end
        dev.relays[keys[i]] = { x = w.x, y = w.y, z = w.z }
    end
    local old = {}
    for key in pairs(dev.relays) do old[#old + 1] = key end
    for i = 1, #old do
        if not wanted[old[i]] then Pump.removeRelay(dev, old[i]) end
    end
    -- The mark shows the relay count (nr) to the clients.
    if countOf(dev.relays) ~= before then LiveWire.Devices.syncMark(dev) end
end

-- Link a barrel (a water container next to the pump) to this pump.
function Pump.linkBarrel(dev, barrel)
    local sq = barrel:getSquare()
    if not sq then return end
    local key = LiveWire.posKey(sq:getX(), sq:getY(), sq:getZ())
    barrel:getModData()[Defs.BARREL_KEY] = { pump = dev.id }
    if isServer() then barrel:transmitModData() end
    dev.barrels[key] = { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
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
        if relay then
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
    local powered = grid ~= nil and grid.powered == true and inv ~= nil and inv.state == "on"
    if (dev.cond or 0) <= 0 then return setState(dev, "broken") end
    if not hasAny(dev.barrels) then return setState(dev, "nobarrel") end
    if not powered then return setState(dev, "nopower") end

    dev.budget = math.min(10, (dev.budget or 0) + Defs.PUMP_LITRES_PER_MINUTE)

    local needs, total = needsOf(dev)
    if total < 0.01 then return setState(dev, "idle") end

    local sources = sourcesOf(dev)
    if #sources == 0 then return setState(dev, "nobarrel") end

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
    local keys = {}
    for key in pairs(dev.relays or {}) do keys[#keys + 1] = key end
    for i = 1, #keys do Pump.removeRelay(dev, keys[i]) end
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
    local zMin = math.max(-1, chunk:getMinLevel())
    local zMax = math.min(7, chunk:getMaxLevel())
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
                            local m = o:getModData()[Defs.BARREL_KEY]
                            local dev = type(m) == "table" and Rg.device(m.pump)
                            if not dev or dev.role ~= "pump" then clear[#clear + 1] = o end
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
