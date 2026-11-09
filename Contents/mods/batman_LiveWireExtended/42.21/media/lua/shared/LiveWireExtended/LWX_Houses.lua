-- LiveWire Extended: boards already in the map's buildings (D-40, D-42), pure rules
-- shared by the authority and the tests. One draw per building, seeded by the building
-- key (same map, same result, nothing stored); the sandbox option HouseBoardPercent sets
-- the share of buildings that get one. Prewired circuits per room: one 20 A breaker per
-- room (its lights and appliances), the stove and the dryer each on their own double
-- 30 A breaker; the smallest board that fits (8, 16, 24 modules), rooms beyond its
-- capacity share the room breakers. No label: the player finds out what is where.
require "LiveWireExtended/LWX_Core"

local X = LiveWire.Extended
local H = {}
X.Houses = H

H.SIZES = { 8, 16, 24 }
H.ROOM_BREAKER = "Base.LWXBreaker20"
H.HEAVY_BREAKER = "Base.LWXBreaker2P30"

-- Deterministic 31-bit hash of a building key (no random generator involved).
function H.hash(key)
    local h = 5381
    for i = 1, #key do h = (h * 33 + key:byte(i)) % 2147483647 end
    return h
end

function H.drawn(key, percent)
    return H.hash(key) % 100 < (percent or X.option("HouseBoardPercent"))
end

function H.modules(plan)
    local n = 0
    for _, s in ipairs(plan.slots) do n = n + (s.type == H.HEAVY_BREAKER and 2 or 1) end
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
    -- Heavy appliances keep a double breaker while one module is left for the rooms.
    local doubles = {}
    for i, key in ipairs(heavy) do
        if 2 * (#doubles + 1) <= max - 1 then doubles[#doubles + 1] = key
        else
            -- beyond capacity: shares a room breaker (or opens one when there is none)
            if #roomSlots == 0 then roomSlots[1] = {} end
            local t = roomSlots[(i - 1) % #roomSlots + 1]
            t[#t + 1] = key
        end
    end
    local roomCap = max - 2 * #doubles
    while #roomSlots > roomCap do
        local extra = table.remove(roomSlots)
        local t = roomSlots[(#roomSlots % roomCap) + 1]
        for _, key in ipairs(extra) do t[#t + 1] = key end
    end
    local plan = { slots = {} }
    for _, pts in ipairs(roomSlots) do plan.slots[#plan.slots + 1] = { type = H.ROOM_BREAKER, points = pts } end
    for _, key in ipairs(doubles) do plan.slots[#plan.slots + 1] = { type = H.HEAVY_BREAKER, points = { key } } end
    local modules = H.modules(plan)
    plan.size = max
    for _, s in ipairs(H.SIZES) do
        if modules <= s then plan.size = s; break end
    end
    return plan
end
