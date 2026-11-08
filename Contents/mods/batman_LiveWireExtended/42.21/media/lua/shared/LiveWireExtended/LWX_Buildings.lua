-- LiveWire Extended: read buildings from the map metadata (IsoMetaGrid, BuildingDef,
-- RoomDef). Works without loaded squares. Player-built houses only have a BuildingDef
-- outside a dedicated server (IsoRegions.java:217, clientProcessBuildings): on a server
-- they are reached with an outdoor terminal and its zone (D-34).
require "LiveWireExtended/LWX_Core"

local X = LiveWire.Extended
local B = {}
X.Buildings = B

-- Rooms of a building: { { z, rects = { { x, y, w, h } } } } (every floor, basement too).
function B.roomsOf(def)
    local out = {}
    local rooms = def:getRooms()
    for i = 0, rooms:size() - 1 do
        local room = rooms:get(i)
        local rects, list = room:getRects(), {}
        for j = 0, rects:size() - 1 do
            local r = rects:get(j)
            list[#list + 1] = { x = r:getX(), y = r:getY(), w = r:getW(), h = r:getH() }
        end
        out[#out + 1] = { z = room:getZ(), rects = list }
    end
    return out
end

-- Stable key of a building: its bounding rectangle corner (same map, same key).
function B.key(def)
    return "b:" .. def:getX() .. "," .. def:getY()
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

-- Footprint of a building for inverter `id` (salt from the id keeps two areas apart).
function B.area(def, id)
    local salt = 0
    for i = 1, #tostring(id) do salt = salt + string.byte(tostring(id), i) end
    local area = X.Footprint.compute(B.roomsOf(def), { band = X.option("BuildingBand"),
        R = LiveWire.Config.tileRange(), V = LiveWire.Config.verticalRange(), salt = salt })
    if not area then return nil end
    local out = X.Footprint.public(area)
    out.kind = "building"
    out.label = { x = def:getX(), y = def:getY() }
    return out
end
