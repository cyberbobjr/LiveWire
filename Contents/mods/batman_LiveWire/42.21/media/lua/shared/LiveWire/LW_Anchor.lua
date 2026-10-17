-- Live Wire: power anchors (runs on the authority AND on every client).
-- An anchor is the inverter square registered as a generator position on every
-- loaded chunk of its range, exactly like IsoGenerator.setSurroundingElectricity
-- (IsoGenerator.java:251-272). The engine purges such positions when a chunk loads
-- (IsoChunk.java:3526, 4785-4797) and LoadChunk fires right after on both sides
-- (IsoChunk.java:3613), so we re-apply there. Positions do not travel to clients
-- that already hold the chunk: clients apply the public anchor table themselves.
-- See docs/architecture.md section 1.4.

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
function Anchor.refreshVisuals(a)
    if isServer() then return end
    local cell = getCell()
    if not cell then return end
    local R = LiveWire.Config.tileRange()
    local V = LiveWire.Config.verticalRange()
    local R2 = R * R
    for z = math.max(-32, a.z - V), math.min(31, a.z + V) do
        for dy = -R, R do
            for dx = -R, R do
                if dx * dx + dy * dy <= R2 then
                    local sq = cell:getGridSquare(a.x + dx, a.y + dy, z)
                    if sq then
                        local objs = sq:getObjects()
                        for i = 0, objs:size() - 1 do
                            local o = objs:get(i)
                            if o:couldBePoweredByGenerator() then o:checkHaveElectricity() end
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

Events.LoadChunk.Add(onLoadChunk)
Events.OnTick.Add(onTick)
Events.OnReceiveGlobalModData.Add(onReceiveGlobalModData)
Events.OnGameStart.Add(onGameStart)
