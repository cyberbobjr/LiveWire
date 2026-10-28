-- Live Wire: power anchors (runs on the authority AND on every client).
-- An anchor is the inverter square registered as a generator position on every
-- loaded chunk of its range, exactly like IsoGenerator.setSurroundingElectricity
-- (IsoGenerator.java:251-272). The engine purges such positions when a chunk loads
-- (IsoChunk.java:3526, 4785-4797) and LoadChunk fires right after on both sides
-- (IsoChunk.java:3613), so we re-apply there. Positions do not travel to clients
-- that already hold the chunk: clients apply the public anchor table themselves.
-- See docs/architecture.md section 1.4.

require "LiveWire/LW_SquareScan"
require "LiveWire/LW_Compat"

LiveWire = LiveWire or {}

local Anchor = {}
LiveWire.Anchor = Anchor

local CHUNK = 8 -- IsoChunkMap.CHUNK_SIZE_IN_SQUARES (IsoChunkMap.java:61)

-- anchors[inverterId] = { x, y, z, on }
function Anchor.table()
    return ModData.getOrCreate(LiveWire.ANCHOR_KEY)
end

-- Does the disc of radius R around the anchor touch chunk (cx, cy)?
function Anchor.touches(cx, cy, a, R)
    local px, py = a.x + 0.5, a.y + 0.5
    local minX, minY = cx * CHUNK, cy * CHUNK
    local maxX, maxY = minX + CHUNK, minY + CHUNK
    local nx = math.max(minX, math.min(px, maxX))
    local ny = math.max(minY, math.min(py, maxY))
    local dx, dy = px - nx, py - ny
    return dx * dx + dy * dy <= R * R
end

-- Add or remove the anchor position on every loaded chunk of its disc.
function Anchor.apply(a, on)
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
                if chunk then
                    if on then
                        chunk:addGeneratorPos(a.x, a.y, a.z)
                    else
                        chunk:removeGeneratorPos(a.x, a.y, a.z)
                    end
                end
            end
        end
    end
end

-- Client side: wake fridge hum, ambient sounds and light sources of the powered
-- objects, as the engine does on generator activation (IsoGenerator.java:279,
-- IsoObject.java:4800-4812). checkHaveElectricity does nothing on a server.
Anchor.VISUAL_SQUARES_PER_TICK = 250
local visualQueue = {}
local visualJobs = {}

function Anchor.refreshVisuals(a)
    if isServer() then return end
    local key = LiveWire.posKey(a.x, a.y, a.z)
    if not visualJobs[key] then visualQueue[#visualQueue + 1] = key end
    -- Coalesce repeated toggles: effects read the current world power state.
    visualJobs[key] = LiveWire.SquareScan.new(a.x, a.y, a.z,
        LiveWire.Config.tileRange(), LiveWire.Config.verticalRange())
end

function Anchor.tickVisuals()
    local cell = getCell()
    if not cell then return end
    local budget = Anchor.VISUAL_SQUARES_PER_TICK
    while budget > 0 and #visualQueue > 0 do
        local key = visualQueue[1]
        local done, used = LiveWire.SquareScan.step(visualJobs[key], budget, function(x, y, z)
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
function Anchor.ageFridges(a)
    if isClient() then return end
    local cell = getCell()
    if not cell then return end
    local radius, vertical = LiveWire.Config.tileRange(), LiveWire.Config.verticalRange()
    for cx = math.floor((a.x - radius) / CHUNK), math.floor((a.x + radius) / CHUNK) do
        for cy = math.floor((a.y - radius) / CHUNK), math.floor((a.y + radius) / CHUNK) do
            local bucket = fridgeChunks[cx .. "," .. cy] or {}
            for o in pairs(bucket) do
                local sq = o:getSquare()
                if sq and o:getObjectIndex() ~= -1
                    and cell:getGridSquare(sq:getX(), sq:getY(), sq:getZ()) == sq then
                    local dx, dy = sq:getX() - a.x, sq:getY() - a.y
                    if dx * dx + dy * dy <= radius * radius and math.abs(sq:getZ() - a.z) <= vertical then
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
    if changed then Anchor.ageFridges(a) end
    Anchor.apply(a, on)
    if Anchor.appliedState[id] ~= on then
        Anchor.appliedState[id] = on
        Anchor.refreshVisuals(a)
    end
end

function Anchor.applyAll()
    for id, a in pairs(Anchor.table()) do
        Anchor.set(id, a, a.on == true)
    end
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

-- Re-apply every anchor whose disc touches the loaded chunk (the purge also hit the
-- neighbours within generatorChunkRange, so the whole disc is re-applied).
Anchor.pendingPasses = 0

local function onLoadChunk(chunk)
    indexFridges(chunk)
    local cx, cy = Anchor.chunkCoords(chunk)
    if not cx then return end
    local R = LiveWire.Config.tileRange()
    local reach = R + 2 * CHUNK
    for id, a in pairs(Anchor.table()) do
        local px, py = cx * CHUNK + CHUNK / 2, cy * CHUNK + CHUNK / 2
        local dx, dy = px - a.x, py - a.y
        if dx * dx + dy * dy <= reach * reach then
            Anchor.apply(a, a.on == true)
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
    for _, a in pairs(Anchor.table()) do
        Anchor.apply(a, a.on == true)
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
