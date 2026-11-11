-- LiveWire Extended: read buildings from the map metadata (IsoMetaGrid, BuildingDef,
-- RoomDef). Works without loaded squares. Player-built houses only have a BuildingDef
-- outside a dedicated server (IsoRegions.java:217, clientProcessBuildings): on a server
-- they are reached with an outdoor terminal and its zone (D-34).
require "LiveWireExtended/LWX_Core"

local X = LiveWire.Extended
local B = {}
X.Buildings = B

local function cornerKey(def) return "b:" .. def:getX() .. "," .. def:getY() end
-- Bounds and lowest floor: tells a cellar from the house over it even when they share a corner.
local function bounds(def)
    return def:getX() .. "," .. def:getY() .. "," .. def:getW() .. "," .. def:getH() .. "," .. def:getMinLevel()
end

-- Calls fn(x, y, room) for every room square of `def` on floor z (all floors when z is nil).
local function eachRoomSquare(def, z, fn)
    local rooms = def:getRooms()
    for i = 0, rooms:size() - 1 do
        local room = rooms:get(i)
        if z == nil or room:getZ() == z then
            local rects = room:getRects()
            for j = 0, rects:size() - 1 do
                local r = rects:get(j)
                for y = r:getY(), r:getY() + r:getH() - 1 do
                    for x = r:getX(), r:getX() + r:getW() - 1 do
                        if fn(x, y, room) then return true end
                    end
                end
            end
        end
    end
    return false
end

-- A vanilla basement is a map building of its own: the engine never merges it into the
-- house over it (Basements.getBuildingToMergeWith gives up on a building reaching under the
-- ground, Basements.java:502-519; measured 2026-11-11, 544 basements, none merged). A
-- building whose rooms all lie under the ground counts with the map house over it (user's
-- rule, 2026-11-11: one board serves the house and its cellar). Map data: cached by the
-- cellar's bounds (a cellar dug by a mod that grows gets new bounds).
local HOUSE_OF = {}
function B.houseOf(def)
    if def:getMaxLevel() >= 0 then return def end
    local ck = bounds(def)
    local hit = HOUSE_OF[ck]
    if hit == nil then
        local meta, top = getWorld():getMetaGrid(), def:getMaxLevel()
        hit = false
        eachRoomSquare(def, top, function(x, y)
            local room = meta:getRoomAt(x, y, 0)
            local house = room and not room:isUserDefined() and room:getBuilding()
            if house and house:getMaxLevel() >= 0 then hit = house; return true end
        end)
        HOUSE_OF[ck] = hit
    end
    return hit or def
end

-- The building and the cellars under it, the building first ({ BuildingDef }).
function B.group(def)
    local house = B.houseOf(def)
    local out, seen = { house }, { [bounds(house)] = true }
    if house:getMinLevel() > 0 then return out end
    local meta, hk = getWorld():getMetaGrid(), bounds(house)
    eachRoomSquare(house, 0, function(x, y)
        local room = meta:getRoomAt(x, y, -1)
        local cellar = room and not room:isUserDefined() and room:getBuilding()
        if cellar and cellar:getMaxLevel() < 0 and not seen[bounds(cellar)]
            and bounds(B.houseOf(cellar)) == hk then
            seen[bounds(cellar)] = true
            out[#out + 1] = cellar
        end
    end)
    return out
end

-- Rooms of a building with its cellars: { { z, rects = { { x, y, w, h } } } } (every floor).
function B.roomsOf(def)
    local out = {}
    for _, d in ipairs(B.group(def)) do
        local rooms = d:getRooms()
        for i = 0, rooms:size() - 1 do
            local room = rooms:get(i)
            local rects, list = room:getRects(), {}
            for j = 0, rects:size() - 1 do
                local r = rects:get(j)
                list[#list + 1] = { x = r:getX(), y = r:getY(), w = r:getW(), h = r:getH() }
            end
            out[#out + 1] = { z = room:getZ(), rects = list }
        end
    end
    return out
end

-- Stable key of a building: its bounding rectangle corner (same map, same key); a cellar
-- has the key of the house over it.
function B.key(def)
    return cornerKey(B.houseOf(def))
end

local function rectDistance2(px, py, x, y, w, h)
    local nx = math.max(x, math.min(px, x + w - 1))
    local ny = math.max(y, math.min(py, y + h - 1))
    return (px - nx) ^ 2 + (py - ny) ^ 2
end

-- Squared distance from (px, py, pz) to the nearest room square within V floors, or nil.
function B.distance2(def, px, py, pz, V)
    local best
    local rooms = def:getRooms()
    for i = 0, rooms:size() - 1 do
        local room = rooms:get(i)
        if math.abs(room:getZ() - pz) <= V then
            local rects = room:getRects()
            for j = 0, rects:size() - 1 do
                local r = rects:get(j)
                local d = rectDistance2(px, py, r:getX(), r:getY(), r:getW(), r:getH())
                if not best or d < best then best = d end
            end
        end
    end
    return best
end

-- The building at (x, y, z), else the nearest one with a room square within `reach`
-- (and V floors). nil when none.
function B.find(x, y, z, reach, V)
    local meta = getWorld():getMetaGrid()
    local here = meta:getBuildingAt(x, y, z)
    if here and here:getRooms():size() > 0 then return here end
    local list = meta:getBuildings()
    local best, bestD
    for i = 0, list:size() - 1 do
        local def = list:get(i)
        local bx, by, bw, bh = def:getX(), def:getY(), def:getW(), def:getH()
        if rectDistance2(x, y, bx, by, bw, bh) <= reach * reach then
            local d = B.distance2(def, x, y, z, V)
            if d and d <= reach * reach and (not bestD or d < bestD) then best, bestD = def, d end
        end
    end
    return best
end

-- Powered area of rooms (B.roomsOf form) for inverter `id`, labelled { x, y } on the inverter
-- screen (salt from the id keeps two areas apart). nil when the rooms give none.
function B.footprint(rooms, label, id)
    local salt = 0
    for i = 1, #tostring(id) do salt = salt + string.byte(tostring(id), i) end
    local area = X.Footprint.compute(rooms, { band = X.option("BuildingBand"),
        R = LiveWire.Config.tileRange(), V = LiveWire.Config.verticalRange(), salt = salt })
    if not area then return nil end
    local out = X.Footprint.public(area)
    out.kind = "building"
    out.label = label
    return out
end

-- Footprint of a building for inverter `id`.
function B.area(def, id)
    local house = B.houseOf(def)
    return B.footprint(B.roomsOf(house), { x = house:getX(), y = house:getY() }, id)
end
