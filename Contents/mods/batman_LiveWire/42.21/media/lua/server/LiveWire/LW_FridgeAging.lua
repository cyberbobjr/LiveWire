-- Live Wire: food of the fridges and freezers, brought up to date before an anchor
-- changes state (authority only: solo, host or dedicated server; never a client).
-- Loaded fridge objects are indexed at chunk load and furniture placement,
-- independent of the asynchronous demand inventory: even the first power toggle
-- ages the food.
if isClient() then return end

LiveWire = LiveWire or {}

local Fridge = {}
LiveWire.FridgeAging = Fridge

local CHUNK = 8 -- IsoChunkMap.CHUNK_SIZE_IN_SQUARES (IsoChunkMap.java:61)

local fridgeChunks = {}

function Fridge.rememberSquare(sq)
    if not sq then return end
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

function Fridge.indexChunk(chunk)
    local cx, cy = LiveWire.Anchor.chunkCoords(chunk)
    if not cx then return end
    fridgeChunks[cx .. "," .. cy] = {}
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for i = 0, CHUNK * CHUNK - 1 do
            Fridge.rememberSquare(chunk:getGridSquare(i % CHUNK, math.floor(i / CHUNK), z))
        end
    end
end

function Fridge.purge()
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

-- Bring the food of the loaded fridges and freezers of the area up to date BEFORE
-- the power changes, as the engine does on generator activation
-- (IsoGenerator.updateFridgeFreezerItems, IsoGenerator.java:325-334). Food ages
-- in one go over the time elapsed since its last update, with the power state of
-- the moment (Food.updateAge, Food.java:668-702): without this, a power cut would
-- also apply to the hours spent cold before it, and the reverse.
function Fridge.age(a, id)
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

Events.EveryHours.Add(Fridge.purge)
