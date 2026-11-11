-- LiveWire Extended: boards already in the map's buildings (D-40, D-42), pure rules
-- shared by the authority and the tests. One draw per building, seeded by the building
-- key (same map, same result, nothing stored); the sandbox option HouseBoardPercent sets
-- the share of buildings that get one. Prewired circuits per room: one 20 A breaker per
-- room (its lights and appliances), the stove and the dryer each on their own 30 A
-- breaker (D-43); the smallest board that fits (8, 16, 24 modules), rooms beyond its
-- capacity share the room breakers. No label: the player finds out what is where.
require "LiveWireExtended/LWX_Core"

local X = LiveWire.Extended
local H = {}
X.Houses = H

H.SIZES = { 8, 16, 24 }
H.ROOM_BREAKER = "Base.LWXBreaker20"
H.HEAVY_BREAKER = "Base.LWXBreaker30"

-- Deterministic 31-bit hash of a building key (no random generator involved).
function H.hash(key)
    local h = 5381
    for i = 1, #key do h = (h * 33 + key:byte(i)) % 2147483647 end
    return h
end

function H.drawn(key, percent)
    return H.hash(key) % 100 < (percent or X.option("HouseBoardPercent"))
end

-- A bare section of a north wall for a board: on the square, nothing but its floor, rugs
-- and walls (with the wall pieces sharing their edge: trims, low partitions). A shelf, a
-- window, a door, a switch or a painting there would overlap the board; items lying on
-- the floor (their sprite has no name) do not.
local FLOORISH = { "floors_", "blends_" }
local WALL_FLAGS = { "WallN", "WallNTrans", "WallNW", "WallNWTrans", "WallW", "WallWTrans" }

local function isWallPiece(spr)
    local props = spr and spr:getProperties()
    if not props then return false end
    for _, f in ipairs(WALL_FLAGS) do
        if props:has(f) then return true end
    end
    return false
end

function H.bareWall(sq)
    local north = sq:getWall(true)
    if not north or not sq:isFree(false) then return false end
    local floor, west, objs = sq:getFloor(), sq:getWall(false), sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o ~= floor and o ~= north and o ~= west then
            local spr = o:getSprite()
            local name = spr and spr:getName() or ""
            local ok = name == "" or isWallPiece(spr)
            for _, prefix in ipairs(FLOORISH) do
                if name:sub(1, #prefix) == prefix then ok = true end
            end
            if not ok then return false end
        end
    end
    return true
end

-- Where a board goes, as in a real house: the garage first, then a utility room, then the
-- entrance, then any room (lower is better).
H.ROOM_RANK = { garage = 1, laundry = 2, storage = 2, utility = 2, hall = 3, hallway = 3, lobby = 3, entry = 3 }

function H.roomRank(name)
    return H.ROOM_RANK[name or ""] or 4
end

function H.modules(plan)
    local n = 0
    for _ in ipairs(plan.slots) do n = n + 1 end  -- one module per breaker
    return n
end

-- rooms: array (stable order) of { key, points = { { key, heavy } } }; maxSize: modules
-- of the board when it is given (a vanilla box), else up to 24.
-- Returns { size, slots = { { type, points = { pointKey... } } } }.
function H.plan(rooms, maxSize)
    local roomSlots, heavy = {}, {}
    for _, r in ipairs(rooms) do
        local light = {}
        for _, p in ipairs(r.points or {}) do
            if p.heavy then heavy[#heavy + 1] = p.key else light[#light + 1] = p.key end
        end
        if #light > 0 then roomSlots[#roomSlots + 1] = light end
    end
    local max = maxSize or H.SIZES[#H.SIZES]
    -- Heavy appliances keep their own breaker while one module is left for the rooms.
    local heavySlots = {}
    for i, key in ipairs(heavy) do
        if #heavySlots + 1 <= max - 1 then heavySlots[#heavySlots + 1] = key
        else
            -- beyond capacity: shares a room breaker (or opens one when there is none)
            if #roomSlots == 0 then roomSlots[1] = {} end
            local t = roomSlots[(i - 1) % #roomSlots + 1]
            t[#t + 1] = key
        end
    end
    local roomCap = max - #heavySlots
    while #roomSlots > roomCap do
        local extra = table.remove(roomSlots)
        local t = roomSlots[(#roomSlots % roomCap) + 1]
        for _, key in ipairs(extra) do t[#t + 1] = key end
    end
    local plan = { slots = {} }
    for _, pts in ipairs(roomSlots) do plan.slots[#plan.slots + 1] = { type = H.ROOM_BREAKER, points = pts } end
    for _, key in ipairs(heavySlots) do plan.slots[#plan.slots + 1] = { type = H.HEAVY_BREAKER, points = { key } } end
    local modules = H.modules(plan)
    plan.size = max
    for _, s in ipairs(H.SIZES) do
        if modules <= s then plan.size = s; break end
    end
    return plan
end
