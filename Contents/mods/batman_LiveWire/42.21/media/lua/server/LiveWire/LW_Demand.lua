-- Live Wire: demand measured by the mod (authority only).
-- Without a real IsoGenerator there is no getTotalPowerUsing: we reproduce the engine
-- rule of IsoGenerator.setSurroundingElectricity (IsoGenerator.java:251-290): objects
-- in range whose couldBePoweredByGenerator() is true, getGeneratorPowerConsumption()
-- > 0, and not already powered by the public grid.
if isClient() then return end

LiveWire = LiveWire or {}

local Demand = {}
LiveWire.Demand = Demand

-- inventories[inverterId] = { builtAt = hours, objects = { IsoObject... },
--   dirty = bool, dirtySince = hours, gen = n, queued = bool }
-- The list of objects that can draw power is rebuilt by a job spread over ticks
-- (SQUARES_PER_TICK squares, one inverter at a time), never in one frame. OnObjectAdded
-- only fires on MP clients (AddItemToMapPacket.java:59,90): new appliances are found
-- by the periodic rebuild, by placements (LW_Placement.lua) and by chunk loads.
Demand.inventories = {}
Demand.REBUILD_HOURS = 2.0
Demand.SQUARES_PER_TICK = 500
Demand.DIRTY_GRACE_HOURS = 1.0  -- keep the last measured value this long while rebuilding
Demand.queue = {}
Demand.job = nil

local function enqueue(id, entry)
    if entry.queued then return end
    entry.queued = true
    Demand.queue[#Demand.queue + 1] = id
end

local function markDirty(id, entry)
    if not entry.dirty then entry.dirtySince = getGameTime():getWorldAgeHours() end
    entry.dirty = true
    entry.gen = (entry.gen or 0) + 1
    enqueue(id, entry)
end

function Demand.invalidate(inverterId)
    if inverterId then
        local e = Demand.inventories[inverterId]
        if e then markDirty(inverterId, e) end
    else
        for id, e in pairs(Demand.inventories) do markDirty(id, e) end
    end
end

-- Invalidate the inverters whose disc contains `sq`.
function Demand.invalidateAt(sq)
    if not sq or not LiveWire.Registry or not LiveWire.Registry.ready then return end
    local R = LiveWire.Config.tileRange()
    local ids = {}
    for id in pairs(Demand.inventories) do ids[#ids + 1] = id end
    for i = 1, #ids do
        local inv = LiveWire.Registry.device(ids[i])
        if inv then
            local dx, dy = sq:getX() - inv.x, sq:getY() - inv.y
            if dx * dx + dy * dy <= R * R then Demand.invalidate(ids[i]) end
        end
    end
end

local function allowExterior()
    local opts = getSandboxOptions()
    local opt = opts and opts:getOptionByName("AllowExteriorGenerator")
    if opt then return opt:getValue() end
    return true
end

-- Next queued inverter whose square is loaded becomes the job. Returns true if any.
local function startJob()
    while #Demand.queue > 0 do
        local id = table.remove(Demand.queue, 1)
        local entry = Demand.inventories[id]
        local inv = LiveWire.Registry.device(id)
        if entry then entry.queued = false end
        if not inv or inv.role ~= "inverter" then
            Demand.inventories[id] = nil
        elseif entry and getCell():getGridSquare(inv.x, inv.y, inv.z) then
            local R = LiveWire.Config.tileRange()
            local V = LiveWire.Config.verticalRange()
            entry.queued = true
            Demand.job = { id = id, x = inv.x, y = inv.y, R = R, R2 = R * R,
                           z = math.max(-32, inv.z - V), zmax = math.min(31, inv.z + V),
                           dy = -R, list = {}, gen = entry.gen or 0 }
            return true
        end
        -- Unloaded inverter: stays dirty; LW_ChunkSync invalidates it again when loaded.
    end
    return false
end

-- Scan up to SQUARES_PER_TICK squares of the disc (rows of the circle, then floors).
local function stepJob()
    local job = Demand.job
    local cell = getCell()
    local budget = Demand.SQUARES_PER_TICK
    while budget > 0 and job.z <= job.zmax do
        local w = math.floor(math.sqrt(job.R2 - job.dy * job.dy) + 1e-9)
        local y = job.y + job.dy
        for dx = -w, w do
            local sq = cell:getGridSquare(job.x + dx, y, job.z)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    if o:couldBePoweredByGenerator() then job.list[#job.list + 1] = o end
                end
            end
        end
        budget = budget - (2 * w + 1)
        job.dy = job.dy + 1
        if job.dy > job.R then
            job.dy = -job.R
            job.z = job.z + 1
        end
    end
    if job.z > job.zmax then
        Demand.job = nil
        local entry = Demand.inventories[job.id]
        if entry then
            entry.objects = job.list
            entry.builtAt = getGameTime():getWorldAgeHours()
            entry.queued = false
            if (entry.gen or 0) == job.gen then
                entry.dirty = false
            else
                enqueue(job.id, entry)  -- changed while scanning
            end
        end
    end
end

local function onTick()
    local R = LiveWire.Registry
    if not R or not R.ready or R.readOnly then return end
    if not Demand.job and not startJob() then return end
    stepJob()
end

-- Appliance family shown in the inverter interface (classes exposed to Lua).
local LAUNDRY = { "IsoClothingWasher", "IsoClothingDryer", "IsoCombinationWasherDryer", "IsoStackedWasherDryer" }
function Demand.category(o)
    if instanceof(o, "IsoLightSwitch") then return "light" end
    if instanceof(o, "IsoTelevision") then return "tv" end
    if instanceof(o, "IsoRadio") then return "radio" end
    if instanceof(o, "IsoStove") then return "stove" end
    for i = 1, #LAUNDRY do
        if instanceof(o, LAUNDRY[i]) then return "laundry" end
    end
    if instanceof(o, "IsoCarBatteryCharger") then return "charger" end
    if o:getContainerByType("fridge") or o:getContainerByType("freezer") then return "fridge" end
    return "other"
end

-- Several independent inverters whose areas overlap: count each appliance once, on
-- the nearest switched-on one (equal distance: smallest id). Slaves have no anchor.
local function closerInverter(others, inv, sx, sy, sz, R2, V)
    local ix, iy = sx - inv.x, sy - inv.y
    local d2inv = ix * ix + iy * iy
    for i = 1, #others do
        local a = others[i]
        local dx, dy = sx - a.x, sy - a.y
        local d2 = dx * dx + dy * dy
        if d2 <= R2 and math.abs(sz - a.z) <= V then
            if d2 < d2inv or (d2 == d2inv and tostring(a.id) < tostring(inv.id)) then
                return true
            end
        end
    end
    return false
end

-- Demand in W for a loaded inverter device, and its breakdown by appliance family
-- ({ fridge = { n = 1, w = 130 }, ... }). Returns nil when the inverter square is
-- not loaded, or while its list is being (re)built (the caller then keeps the last
-- measured value).
function Demand.measure(inv)
    local cell = getCell()
    if not cell:getGridSquare(inv.x, inv.y, inv.z) then return nil end
    local now = getGameTime():getWorldAgeHours()
    local entry = Demand.inventories[inv.id]
    if not entry then
        entry = { builtAt = now, objects = {}, dirty = true, dirtySince = now, gen = 0 }
        Demand.inventories[inv.id] = entry
        enqueue(inv.id, entry)
        return nil
    end
    if entry.dirty then
        enqueue(inv.id, entry)
        if now - (entry.dirtySince or now) < Demand.DIRTY_GRACE_HOURS then return nil end
    elseif now - entry.builtAt >= Demand.REBUILD_HOURS then
        enqueue(inv.id, entry)  -- refresh in the background, keep using the current list
    end
    -- Same filters as IsoGenerator.setSurroundingElectricity (IsoGenerator.java:274-286):
    -- not already on the public grid, exterior squares only if AllowExteriorGenerator.
    -- While our anchor is on, only count squares the engine really powers
    -- (the engine generator range is a static value, notes-moteur.md note 27).
    local anchor = LiveWire.Registry.anchors and LiveWire.Registry.anchors[inv.id]
    local anchorOn = anchor and anchor.on
    local exteriorOk = allowExterior()
    local total = 0
    local scale = 1000 * (LiveWire.Config.get("PowerScale") or 1)
    local breakdown = {}
    -- Other switched-on anchors, collected once per call (see closerInverter).
    local R = LiveWire.Config.tileRange()
    local V = LiveWire.Config.verticalRange()
    local others = {}
    for aid, a in pairs(LiveWire.Registry.anchors or {}) do
        if a.on == true and aid ~= inv.id then
            others[#others + 1] = { id = aid, x = a.x, y = a.y, z = a.z }
        end
    end
    for i = 1, #entry.objects do
        local o = entry.objects[i]
        local sq = o:getSquare()
        if sq and o:getObjectIndex() ~= -1 and not ItemContainer.isObjectPowered(o, false)
            and (exteriorOk or not sq:getProperties():has(IsoFlagType.exterior))
            and (not anchorOn or sq:haveElectricity()) then
            local p = o:getGeneratorPowerConsumption()
            if p and p > 0 and (#others == 0
                or not closerInverter(others, inv, sq:getX(), sq:getY(), sq:getZ(), R * R, V)) then
                total = total + p
                local cat = Demand.category(o)
                local b = breakdown[cat] or { n = 0, w = 0 }
                b.n = b.n + 1
                b.w = b.w + p * scale
                breakdown[cat] = b
            end
        end
    end
    return total * scale, breakdown
end

-- An appliance removed near an inverter: rebuild its list (a moved fridge comes back
-- through the placement wrapper).
local function onObjectChanged(obj)
    if not obj or not obj.getSquare or not obj.couldBePoweredByGenerator then return end
    if not obj:couldBePoweredByGenerator() then return end
    Demand.invalidateAt(obj:getSquare())
end

Events.OnObjectAboutToBeRemoved.Add(onObjectChanged)
Events.OnTick.Add(onTick)
