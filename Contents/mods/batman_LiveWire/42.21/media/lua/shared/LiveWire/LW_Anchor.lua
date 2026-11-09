-- Live Wire: power anchors (runs on the authority AND on every client).
-- An anchor is the inverter square registered as a generator position on every
-- loaded chunk of its range, exactly like IsoGenerator.setSurroundingElectricity
-- (IsoGenerator.java:251-272). The engine purges such positions when a chunk loads
-- (IsoChunk.java:3526, 4785-4797) and LoadChunk fires right after on both sides
-- (IsoChunk.java:3613), so we re-apply there. Positions do not travel to clients
-- that already hold the chunk: clients apply the public anchor table themselves.
-- See docs/architecture.md section 1.4.

require "LiveWire/LW_SquareScan"
require "LiveWire/LW_Coverage"
require "LiveWire/LW_Compat"

LiveWire = LiveWire or {}

local Anchor = {}
LiveWire.Anchor = Anchor

local CHUNK = 8 -- IsoChunkMap.CHUNK_SIZE_IN_SQUARES (IsoChunkMap.java:61)

-- anchors[inverterId] = { x, y, z, on }
function Anchor.table()
    return ModData.getOrCreate(LiveWire.ANCHOR_KEY)
end

-- Does the disc of radius R around the anchor touch chunk (cx, cy)? (LW_Coverage)
function Anchor.touches(cx, cy, a, R)
    return LiveWire.Coverage.touchesDisc(cx, cy, a, R)
end

local function setPos(chunk, x, y, z, on)
    if on then
        chunk:addGeneratorPos(x, y, z)
    else
        chunk:removeGeneratorPos(x, y, z)
    end
end

-- Add or remove the anchor position on every loaded chunk of its disc, then the
-- positions of the extra coverage of a registered provider (none by default).
function Anchor.apply(a, on, id)
    local cell = getCell()
    if not cell then return end
    local R = LiveWire.Config.tileRange()
    local cx0, cx1 = math.floor((a.x - R) / CHUNK), math.floor((a.x + R) / CHUNK)
    local cy0, cy1 = math.floor((a.y - R) / CHUNK), math.floor((a.y + R) / CHUNK)
    for cy = cy0, cy1 do
        for cx = cx0, cx1 do
            if Anchor.touches(cx, cy, a, R) then
                -- getChunkForGridSquare goes through ServerMap on a server (IsoCell.java:361-364).
                local chunk = cell:getChunkForGridSquare(cx * CHUNK, cy * CHUNK, a.z)
                if chunk then setPos(chunk, a.x, a.y, a.z, on) end
            end
        end
    end
    local extra = LiveWire.Coverage.extraPositions(id, a)
    for i = 1, #extra do
        local p = extra[i]
        local chunk = cell:getChunkForGridSquare(p.cx * CHUNK, p.cy * CHUNK, p.z)
        if chunk then setPos(chunk, p.x, p.y, p.z, on) end
    end
end

-- Client side: wake fridge hum, ambient sounds and light sources of the powered
-- objects, as the engine does on generator activation (IsoGenerator.java:279,
-- IsoObject.java:4800-4812). checkHaveElectricity does nothing on a server.
Anchor.VISUAL_SQUARES_PER_TICK = 250
local visualQueue = {}
local visualJobs = {}

function Anchor.refreshVisuals(a, id)
    if isServer() then return end
    local key = LiveWire.posKey(a.x, a.y, a.z)
    if not visualJobs[key] then visualQueue[#visualQueue + 1] = key end
    -- Coalesce repeated toggles: effects read the current world power state.
    visualJobs[key] = LiveWire.Coverage.scan(id, a)
end

function Anchor.tickVisuals()
    local cell = getCell()
    if not cell then return end
    local budget = Anchor.VISUAL_SQUARES_PER_TICK
    while budget > 0 and #visualQueue > 0 do
        local key = visualQueue[1]
        local done, used = LiveWire.Coverage.step(visualJobs[key], budget, function(x, y, z)
            local sq = cell:getGridSquare(x, y, z)
            if not sq then return end
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do
                local o = objs:get(i)
                if o:couldBePoweredByGenerator() then o:checkHaveElectricity() end
            end
        end)
        budget = budget - used
        if done then visualJobs[key] = nil; table.remove(visualQueue, 1) end
    end
end

-- Loaded fridge objects indexed at chunk load and furniture placement, independent
-- of the asynchronous demand inventory: even the first power toggle ages the food.
local fridgeChunks = {}
function Anchor.rememberSquare(sq)
    if isClient() or not sq then return end
    local key = math.floor(sq:getX() / CHUNK) .. "," .. math.floor(sq:getY() / CHUNK)
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o:getContainerByType("fridge") or o:getContainerByType("freezer") then
            fridgeChunks[key] = fridgeChunks[key] or {}
            fridgeChunks[key][o] = true
        end
    end
end

local function indexFridges(chunk)
    if isClient() then return end
    local cx, cy = Anchor.chunkCoords(chunk)
    if not cx then return end
    fridgeChunks[cx .. "," .. cy] = {}
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for i = 0, CHUNK * CHUNK - 1 do
            Anchor.rememberSquare(chunk:getGridSquare(i % CHUNK, math.floor(i / CHUNK), z))
        end
    end
end

function Anchor.purgeFridges()
    local cell = getCell()
    if not cell then return end
    local empty = {}
    for key, bucket in pairs(fridgeChunks) do
        local stale = {}
        for obj in pairs(bucket) do
            local sq = obj:getSquare()
            if not sq or obj:getObjectIndex() == -1
                or cell:getGridSquare(sq:getX(), sq:getY(), sq:getZ()) ~= sq then
                stale[#stale + 1] = obj
            end
        end
        for i = 1, #stale do bucket[stale[i]] = nil end
        local any = false
        for _ in pairs(bucket) do any = true; break end
        if not any then empty[#empty + 1] = key end
    end
    for i = 1, #empty do fridgeChunks[empty[i]] = nil end
end

-- Authority: bring the food of the loaded fridges and freezers of the area up to
-- date BEFORE the power changes, as the engine does on generator activation
-- (IsoGenerator.updateFridgeFreezerItems, IsoGenerator.java:325-334). Food ages
-- in one go over the time elapsed since its last update, with the power state of
-- the moment (Food.updateAge, Food.java:668-702): without this, a power cut would
-- also apply to the hours spent cold before it, and the reverse.
function Anchor.ageFridges(a, id)
    if isClient() then return end
    local cell = getCell()
    if not cell then return end
    local radius, vertical = LiveWire.Config.tileRange(), LiveWire.Config.verticalRange()
    local Cov = LiveWire.Coverage
    local cx0, cy0, cx1, cy1 = Cov.chunkRange(id, a, radius)
    for cx = cx0, cx1 do
        for cy = cy0, cy1 do
            local bucket = fridgeChunks[cx .. "," .. cy] or {}
            for o in pairs(bucket) do
                local sq = o:getSquare()
                if sq and o:getObjectIndex() ~= -1
                    and cell:getGridSquare(sq:getX(), sq:getY(), sq:getZ()) == sq then
                    if Cov.covers(id, a, sq:getX(), sq:getY(), sq:getZ(), radius, vertical) then
                        for c = 0, o:getContainerCount() - 1 do
                            local cont = o:getContainerByIndex(c)
                            local t = cont and cont:getType()
                            if t == "fridge" or t == "freezer" then
                                local items = cont:getItems()
                                for k = 0, items:size() - 1 do
                                    local it = items:get(k)
                                    if instanceof(it, "Food") then it:updateAge() end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Apply an anchor and refresh visuals when its state changed on this side.
Anchor.appliedState = {}  -- id -> last state applied on this machine

function Anchor.set(id, a, on)
    local changed = Anchor.appliedState[id] ~= nil and Anchor.appliedState[id] ~= on
    if changed then Anchor.ageFridges(a, id) end
    Anchor.apply(a, on, id)
    if Anchor.appliedState[id] ~= on then
        Anchor.appliedState[id] = on
        Anchor.refreshVisuals(a, id)
    end
end

-- A provider changes the extra coverage of inverter `id` on this side: withdraw the
-- old positions, age the food of both areas with the power state of the moment,
-- run `mutate`, then declare the new positions and refresh the visuals.
function Anchor.reshape(id, mutate)
    local a = Anchor.table()[id]
    if not a then mutate(); return end
    local on = a.on == true
    if on then Anchor.ageFridges(a, id) end
    Anchor.apply(a, false, id)
    mutate()
    if on then Anchor.ageFridges(a, id) end
    Anchor.apply(a, on, id)
    Anchor.refreshVisuals(a, id)
end

-- World chunk coordinates of an IsoChunk (its wx/wy fields are not readable from Lua).
function Anchor.chunkCoords(chunk)
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for i = 0, CHUNK * CHUNK - 1 do
            local sq = chunk:getGridSquare(i % CHUNK, math.floor(i / CHUNK), z)
            if sq then
                return math.floor(sq:getX() / CHUNK), math.floor(sq:getY() / CHUNK)
            end
        end
    end
    return nil
end

-- Chunks the engine purges when one chunk loads: the square of +/- generatorChunkRange
-- chunks around it (IsoGenerator.chunkLoaded, IsoGenerator.java:593-603). That range is
-- a static field: 2 until an IsoGenerator exists in the session, then radius / 8 + 1
-- (IsoGenerator.java:67, 115-119), so take the larger of the two.
function Anchor.purgeChunkRange(R)
    return math.max(2, math.floor(R / CHUNK) + 1)
end

-- Can loading chunk (cx, cy) purge the anchor from one of the chunks of its disc?
-- Square (Chebyshev) test on chunk coordinates, like the engine: a circle around
-- the anchor misses the diagonal neighbours of the disc.
function Anchor.purgedBy(a, cx, cy, R, id)
    local g = Anchor.purgeChunkRange(R)
    local cx0, cy0, cx1, cy1 = LiveWire.Coverage.chunkRange(id, a, R)
    return cx >= cx0 - g and cx <= cx1 + g and cy >= cy0 - g and cy <= cy1 + g
end

-- Re-apply every anchor the loaded chunk may have purged, on its whole disc.
Anchor.pendingPasses = 0

local function onLoadChunk(chunk)
    indexFridges(chunk)
    local cx, cy = Anchor.chunkCoords(chunk)
    if not cx then return end
    local R = LiveWire.Config.tileRange()
    for id, a in pairs(Anchor.table()) do
        if Anchor.purgedBy(a, cx, cy, R, id) then
            Anchor.apply(a, a.on == true, id)
            Anchor.pendingPasses = 2
        end
    end
end

-- A second and third pass a few ticks later cover neighbours loaded after us.
local tickCounter = 0
local function onTick()
    Anchor.tickVisuals()
    if Anchor.pendingPasses <= 0 then return end
    tickCounter = tickCounter + 1
    if tickCounter < 30 then return end
    tickCounter = 0
    Anchor.pendingPasses = Anchor.pendingPasses - 1
    for id, a in pairs(Anchor.table()) do
        Anchor.apply(a, a.on == true, id)
    end
end

-- Client: receive the public anchor table and apply the differences.
local function onReceiveGlobalModData(key, data)
    if key ~= LiveWire.ANCHOR_KEY or not isClient() then return end
    if type(data) ~= "table" then return end
    local old = Anchor.table()
    for id, a in pairs(old) do
        if data[id] == nil then Anchor.set(id, a, false) end
    end
    ModData.add(key, data)
    for id, a in pairs(data) do
        Anchor.set(id, a, a.on == true)
    end
end

local function onGameStart()
    if isClient() then
        ModData.request(LiveWire.ANCHOR_KEY)
    end
end

-- Past any event queue a performance mod may have installed: the generator
-- positions purged by the engine must be back before the next frame reads them
-- (LW_Compat.addLoadChunk).
LiveWire.Compat.addLoadChunk(onLoadChunk)
Events.OnTick.Add(onTick)
Events.OnReceiveGlobalModData.Add(onReceiveGlobalModData)
Events.OnGameStart.Add(onGameStart)

Events.EveryHours.Add(Anchor.purgeFridges)
