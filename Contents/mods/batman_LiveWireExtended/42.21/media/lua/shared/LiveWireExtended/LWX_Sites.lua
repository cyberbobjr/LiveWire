-- LiveWire Extended: the place ("site") a square belongs to (D-62), the one rule of the
-- breaker boards: where one may hang, and what it serves. Same answer on a client, in solo
-- and on a dedicated server, from engine data only (no other mod's API):
--   1. a room of the map (IsoMetaGrid:getRoomAt, which never returns an "emptyoutside" room,
--      IsoMetaChunk.java:273) gives its building: map houses, vanilla basements merged into
--      their house (Basements.java:502-585), rooms drawn by BuildingRoomsEditor. A derelict
--      room (no public grid, IsoGridSquare.isNoPower) stays inside;
--   2. else, on the ground or above, a closed and roofed world region (IsoWorldRegion
--      isPlayerRoom) is a player enclosure; the engine has one region per floor, the site
--      joins the closed and roofed regions stacked above and below it (a player house, every
--      floor). The engine turns it into a
--      userDefined building outside a dedicated server only (IsoRegions.java:217): rooms
--      flagged RoomDef:isUserDefined() are read through their region on every side.
-- Sites are plain tables made on demand; a world region is never kept across calls (the
-- engine swaps its region buffers).
--   { kind = "building", def = BuildingDef, x, y, z }
--   { kind = "enclosure", region = IsoWorldRegion, x, y, z }
require "LiveWireExtended/LWX_Buildings"

local X = LiveWire.Extended
local S = {}
X.Sites = S

S.MAX_SQUARES = 2000   -- an enclosure walk stops there

local function regionAt(x, y, z)
    if z < 0 or not IsoRegions then return nil end
    local region = IsoRegions.getIsoWorldRegion(x, y, z)
    if region and region:isPlayerRoom() then return region end
    return nil
end

-- Site of square (x, y, z), or nil when the square is not inside.
function S.at(x, y, z)
    local room = getWorld():getMetaGrid():getRoomAt(x, y, z)
    if room and not room:isUserDefined() then
        local def = room:getBuilding()
        if def then return { kind = "building", def = def, x = x, y = y, z = z } end
    end
    local region = regionAt(x, y, z)
    if region then return { kind = "enclosure", region = region, x = x, y = y, z = z } end
    return nil
end


-- Squares of an enclosure: { { x, y, z } }, at most MAX_SQUARES. A walk over the squares of the
-- same region on a floor; a square whose square above or below lies in a closed and roofed
-- region brings that region in (the floors of one player house).
local STEPS = { { 1, 0, 0 }, { -1, 0, 0 }, { 0, 1, 0 }, { 0, -1, 0 }, { 0, 0, 1 }, { 0, 0, -1 } }
local function fill(site)
    local out, seen, queue, head = {}, {}, { { site.x, site.y, site.z, site.region } }, 1
    seen[site.x .. "," .. site.y .. "," .. site.z] = true
    while queue[head] and #out < S.MAX_SQUARES do
        local p = queue[head]
        head = head + 1
        out[#out + 1] = p
        for _, d in ipairs(STEPS) do
            local nx, ny, nz = p[1] + d[1], p[2] + d[2], p[3] + d[3]
            local k = nx .. "," .. ny .. "," .. nz
            if not seen[k] then
                local r = regionAt(nx, ny, nz)
                -- same floor: the same region only; another floor: any closed and roofed one
                if r and (d[3] ~= 0 or r == p[4]) then
                    seen[k] = true
                    queue[#queue + 1] = { nx, ny, nz, r }
                end
            end
        end
    end
    return out
end

-- First square of an enclosure (lowest floor, then smallest y, then x): its key and label.
local function corner(squares)
    local best = squares[1]
    for _, p in ipairs(squares) do
        if p[3] < best[3] or (p[3] == best[3] and (p[2] < best[2] or (p[2] == best[2] and p[1] < best[1]))) then
            best = p
        end
    end
    return best
end

-- Stable key of a site: "b:x,y" for a building (X.Buildings.key), "e:x,y,z" for an enclosure
-- (its first square).
function S.key(site)
    if site.kind == "building" then return X.Buildings.key(site.def) end
    local c = corner(fill(site))
    return "e:" .. c[1] .. "," .. c[2] .. "," .. c[3]
end

-- Is square (x, y, z) an "emptyoutside" part of a map building (yard, porch)? Map data, the
-- same on every side.
function S.mapOutside(x, y, z)
    return getWorld():getMetaGrid():getEmptyOutsideAt(x, y, z) ~= nil
end

-- Are sites a and b one place?
function S.same(a, b)
    if not a or not b or a.kind ~= b.kind then return false end
    if a.kind == "building" then return X.Buildings.key(a.def) == X.Buildings.key(b.def) end
    return S.key(a) == S.key(b)
end

-- Calls fn(x, y, z) once for every square of the site: the rooms of a building on every floor,
-- or the floor of an enclosure.
function S.eachSquare(site, fn)
    if site.kind == "building" then
        for _, room in ipairs(X.Buildings.roomsOf(site.def)) do
            for _, r in ipairs(room.rects) do
                for y = r.y, r.y + r.h - 1 do
                    for x = r.x, r.x + r.w - 1 do fn(x, y, room.z) end
                end
            end
        end
        return
    end
    for _, p in ipairs(fill(site)) do fn(p[1], p[2], p[3]) end
end

-- Set of the squares of a site ("x,y,z" -> true), for repeated membership tests.
function S.squareSet(site)
    local set = {}
    S.eachSquare(site, function(x, y, z) set[x .. "," .. y .. "," .. z] = true end)
    return set
end

-- Rooms of a site as X.Buildings.roomsOf gives them ({ { z, rects = { { x, y, w, h } } } }):
-- an enclosure gives one room per floor, of one-row rectangles.
local function rowRects(rows)
    local rects = {}
    for y, xs in pairs(rows) do
        table.sort(xs)
        local start, last = xs[1], xs[1]
        for i = 2, #xs + 1 do
            local x = xs[i]
            if x ~= last + 1 then
                rects[#rects + 1] = { x = start, y = y, w = last - start + 1, h = 1 }
                start = x
            end
            last = x
        end
    end
    return rects
end

function S.rooms(site)
    if site.kind == "building" then return X.Buildings.roomsOf(site.def) end
    local floors, out = {}, {}
    for _, p in ipairs(fill(site)) do
        local rows = floors[p[3]] or {}
        floors[p[3]] = rows
        local row = rows[p[2]] or {}
        rows[p[2]] = row
        row[#row + 1] = p[1]
    end
    for z, rows in pairs(floors) do out[#out + 1] = { z = z, rects = rowRects(rows) } end
    return out
end

-- Powered area of a site for inverter `id` (X.Buildings.footprint), or nil.
function S.area(site, id)
    if site.kind == "building" then return X.Buildings.area(site.def, id) end
    local c = corner(fill(site))
    return X.Buildings.footprint(S.rooms(site), { x = c[1], y = c[2] }, id)
end
