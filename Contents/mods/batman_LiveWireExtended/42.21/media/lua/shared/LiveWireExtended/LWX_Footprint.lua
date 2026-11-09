-- LiveWire Extended: footprint of a building (pure, no world access), D-33.
-- Input: the rooms of a building, { z = level, rects = { { x, y, w, h }, ... } } per
-- RoomDef (RoomDef.getRects, every floor, basement included). The ground floor gets an
-- outdoor strip of `band` squares. The engine powers by chunk: a generator position
-- declared on a chunk powers the squares of THAT chunk within GeneratorTileRange (R)
-- of it, on +/- GeneratorVerticalPowerRange (V) floors (IsoChunk.java:4773-4783,
-- IsoGenerator.java:637-644). So the footprint is rounded to chunks and each chunk gets
-- one position per vertical slice of 2V+1 floors.
-- A position must stand on a square that exists: the engine then purges it at the next
-- load once the sub-mod is gone (IsoChunk.java:4785-4797). Ground squares always exist;
-- above or below ground, a room square of that floor is used.
require "LiveWireExtended/LWX_Core"
LiveWire = LiveWire or {}
LiveWire.Extended = LiveWire.Extended or {}
local F = {}
LiveWire.Extended.Footprint = F

local CHUNK = LiveWire.Extended.CHUNK
local GROUND = 0

local function chunkKey(cx, cy) return cx .. "," .. cy end
local function sqKey(x, y, z) return x .. "," .. y .. "," .. z end

local function chunkOf(area, cx, cy)
    local key = chunkKey(cx, cy)
    local c = area.chunks[key]
    if not c then
        c = { cx = cx, cy = cy, levels = {}, rooms = {} }
        area.chunks[key] = c
    end
    return c
end

-- Mark the squares of rectangle (x, y, w, h) on floor z; `isRoom` keeps room squares
-- per floor and chunk (positions above or below ground stand on them).
local function addRect(area, footprint, x, y, w, h, z, isRoom)
    for yy = y, y + h - 1 do
        for xx = x, x + w - 1 do
            local c = chunkOf(area, math.floor(xx / CHUNK), math.floor(yy / CHUNK))
            c.levels[z] = true
            footprint[sqKey(xx, yy, z)] = true
            if isRoom then
                c.rooms[z] = c.rooms[z] or {}
                table.insert(c.rooms[z], { x = xx, y = yy })
            end
        end
    end
end

local function sortedLevels(set)
    local out = {}
    for z in pairs(set) do out[#out + 1] = z end
    table.sort(out)
    return out
end

-- Square of chunk c on floor z for a position: the k-th closest to the chunk centre
-- (k = salt modulo the candidates, so two areas rarely share a position).
local function pickSquare(c, z, salt)
    local cx0, cy0 = c.cx * CHUNK, c.cy * CHUNK
    local centreX, centreY = cx0 + CHUNK / 2, cy0 + CHUNK / 2
    local list = {}
    if z == GROUND then
        for _, d in ipairs({ { 3, 3 }, { 4, 3 }, { 3, 4 }, { 4, 4 } }) do
            list[#list + 1] = { x = cx0 + d[1], y = cy0 + d[2] }
        end
    else
        for _, s in ipairs(c.rooms[z] or {}) do list[#list + 1] = s end
        table.sort(list, function(a, b)
            local da = (a.x + 0.5 - centreX) ^ 2 + (a.y + 0.5 - centreY) ^ 2
            local db = (b.x + 0.5 - centreX) ^ 2 + (b.y + 0.5 - centreY) ^ 2
            if da ~= db then return da < db end
            if a.y ~= b.y then return a.y < b.y end
            return a.x < b.x
        end)
        local n = math.min(4, #list)
        local keep = {}
        for i = 1, n do keep[i] = list[i] end
        list = keep
    end
    if #list == 0 then return nil end
    return list[(salt % #list) + 1]
end

-- Greedy vertical slices: the lowest uncovered floor l gets the highest floor of the
-- chunk in [l, l + V] (it exists and reaches furthest up).
local function slices(levels, V)
    local out, covered = {}, {}
    for i = 1, #levels do
        local l = levels[i]
        if not covered[l] then
            local pz = l
            for j = i, #levels do
                if levels[j] <= l + V then pz = levels[j] end
            end
            out[#out + 1] = pz
            for j = 1, #levels do
                if math.abs(levels[j] - pz) <= V then covered[levels[j]] = true end
            end
        end
    end
    return out
end

-- Index of positions by chunk, kept outside the saved area table.
function F.index(area)
    local idx = {}
    for _, p in ipairs(area.positions) do
        local key = chunkKey(p.cx, p.cy)
        idx[key] = idx[key] or {}
        table.insert(idx[key], p)
    end
    return idx
end

-- Engine rule (IsoChunk.isGeneratorPoweringSquare + IsoGenerator.isPoweringSquare).
function F.coversIndexed(idx, x, y, z, R, V)
    local list = idx[chunkKey(math.floor(x / CHUNK), math.floor(y / CHUNK))]
    if not list then return false end
    for i = 1, #list do
        local p = list[i]
        if math.abs(z - p.z) <= V and z >= -32 and z <= 31 then
            local dx, dy = p.x + 0.5 - (x + 0.5), p.y + 0.5 - (y + 0.5)
            if dx * dx + dy * dy <= R * R then return true end
        end
    end
    return false
end

function F.covers(area, x, y, z, R, V)
    area.idx = area.idx or F.index(area)
    return F.coversIndexed(area.idx, x, y, z, R, V)
end

-- rooms: array of { z, rects = { { x, y, w, h } } }; opts: { band, R, V, salt }.
-- Returns nil for a building without rooms, else
-- { positions = { { cx, cy, x, y, z } }, bounds = { x0, y0, x1, y1 } (whole chunks),
--   chunks = { ["cx,cy"] = ... } (computation only), overflow, unpowered }.
function F.compute(rooms, opts)
    local band, R, V, salt = opts.band or 0, opts.R, opts.V, opts.salt or 0
    local area = { chunks = {}, positions = {} }
    local footprint = {}
    local any = false
    for _, room in ipairs(rooms) do
        for _, r in ipairs(room.rects or {}) do
            if r.w > 0 and r.h > 0 then
                any = true
                addRect(area, footprint, r.x, r.y, r.w, r.h, room.z, true)
                if room.z == GROUND and band > 0 then
                    addRect(area, footprint, r.x - band, r.y - band, r.w + 2 * band, r.h + 2 * band, GROUND, false)
                end
            end
        end
    end
    if not any then return nil end
    local keys = {}
    for key in pairs(area.chunks) do keys[#keys + 1] = key end
    table.sort(keys)
    local x0, y0, x1, y1
    for _, key in ipairs(keys) do
        local c = area.chunks[key]
        local levels = sortedLevels(c.levels)
        c.levelList = levels
        for _, pz in ipairs(slices(levels, V)) do
            local s = pickSquare(c, pz, salt)
            if s then
                area.positions[#area.positions + 1] = { cx = c.cx, cy = c.cy, x = s.x, y = s.y, z = pz }
            end
        end
        local bx, by = c.cx * CHUNK, c.cy * CHUNK
        x0 = x0 and math.min(x0, bx) or bx
        y0 = y0 and math.min(y0, by) or by
        x1 = x1 and math.max(x1, bx + CHUNK - 1) or bx + CHUNK - 1
        y1 = y1 and math.max(y1, by + CHUNK - 1) or by + CHUNK - 1
    end
    area.bounds = { x0 = x0, y0 = y0, x1 = x1, y1 = y1 }
    -- Overflow (powered squares outside the footprint) and unpowered footprint squares,
    -- on the floors the footprint uses in each chunk.
    local idx = F.index(area)
    local overflow, unpowered = 0, 0
    for _, key in ipairs(keys) do
        local c = area.chunks[key]
        for _, z in ipairs(c.levelList) do
            for yy = c.cy * CHUNK, c.cy * CHUNK + CHUNK - 1 do
                for xx = c.cx * CHUNK, c.cx * CHUNK + CHUNK - 1 do
                    local powered = F.coversIndexed(idx, xx, yy, z, R, V)
                    local inside = footprint[sqKey(xx, yy, z)] == true
                    if powered and not inside then overflow = overflow + 1 end
                    if inside and not powered then unpowered = unpowered + 1 end
                end
            end
        end
    end
    area.overflow, area.unpowered = overflow, unpowered
    return area
end

-- The saved, transmitted form: positions and bounds only (primitives).
function F.public(area)
    local out = { positions = {}, bounds = { x0 = area.bounds.x0, y0 = area.bounds.y0,
        x1 = area.bounds.x1, y1 = area.bounds.y1 } }
    for i, p in ipairs(area.positions) do
        out.positions[i] = { cx = p.cx, cy = p.cy, x = p.x, y = p.y, z = p.z }
    end
    return out
end
