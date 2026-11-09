-- LiveWire Extended: points wired to a breaker (D-36, D-37, D-41), rules shared by
-- client menus and the authority. A point is what an adapter calls one appliance: a
-- single object, every piece of a multi-tile appliance, or a room with its wall
-- switches (LWX_Adapters identity).
--   points[identity] = { board = "x,y,z", pos = module, x, y, z, adapter }
--   and the breaker slot lists it: slot.points[identity] = true
-- D-37: a linked board serves the building it stands in (or, outdoors, the terminal
-- zone around it). In a served region, an appliance wired to no breaker has no
-- current; outside any served region the usual rule applies (everything powered).
require "LiveWireExtended/LWX_Breakers"
require "LiveWireExtended/LWX_Adapters"
require "LiveWireExtended/LWX_Buildings"

local X = LiveWire.Extended
local D = X.Data
local PT = {}
X.Points = PT

PT.LEVEL = 3   -- D-41: every point
PT.XP = 5      -- D-41: per connection (once per point and day)

function PT.table()
    local t = D.table()
    t.points = t.points or {}
    return t.points
end

function PT.point(key) return key and PT.table()[key] or nil end

local function boards() return D.table().panels or {} end

-- Region keys of a square: the building it belongs to, then the terminal zones that
-- hold it (chunk rectangle, terminal floor +/- the vertical range).
function PT.regionsAt(x, y, z)
    local out = {}
    local def = getWorld():getMetaGrid():getBuildingAt(x, y, z)
    if def then out[#out + 1] = X.Buildings.key(def) end
    local cx, cy, V = math.floor(x / X.CHUNK), math.floor(y / X.CHUNK), LiveWire.Config.verticalRange()
    for _, e in pairs(D.table().inverters or {}) do
        for _, a in pairs(e.areas or {}) do
            local r = a.kind == "zone" and a.rect
            if r and a.terminal and cx >= r.cx0 and cx <= r.cx1 and cy >= r.cy0 and cy <= r.cy1
                and math.abs(z - (a.label and a.label.z or z)) <= V then
                out[#out + 1] = "t:" .. a.terminal
            end
        end
    end
    return out
end

-- Region served by a board record: its building, else the first zone holding it.
function PT.regionOf(record)
    return PT.regionsAt(record.x, record.y, record.z)[1]
end

-- Served regions (region key -> board key), rebuilt when the boards change.
local served, servedRev = nil, nil
PT.rev = 0
function PT.changed() PT.rev = PT.rev + 1 end
function PT.servedIndex()
    if served and servedRev == PT.rev then return served end
    served, servedRev = {}, PT.rev
    for key, r in pairs(boards()) do
        local region = PT.regionOf(r)
        if region then served[region] = key end
    end
    return served
end

-- Is the square in a region served by a board?
function PT.servedAt(x, y, z)
    local index = PT.servedIndex()
    for _, region in ipairs(PT.regionsAt(x, y, z)) do
        if index[region] then return true end
    end
    return false
end

-- Breaker slot of a point, or nil when its board or breaker is gone.
function PT.slotOf(p)
    local board = p and boards()[p.board]
    return board and X.Breakers.slotAt(board, p.pos) or nil
end

-- Has point `key` (standing at x, y, z) no current because of a breaker or of D-37?
function PT.blockedKey(key, x, y, z)
    local p = PT.point(key)
    local slot = p and PT.slotOf(p)
    if slot then return slot.off == true or slot.tripped == true end
    return PT.servedAt(x, y, z)
end

function PT.blocked(o)
    local key = X.Adapters.identity(o)
    local sq = key and o:getSquare()
    if not sq then return false end
    return PT.blockedKey(key, sq:getX(), sq:getY(), sq:getZ())
end

-- Can `character` wire object `o` to the breaker of module `pos` of board `boardObj`?
-- true, wires; or false, key, arg1, arg2.
function PT.checkConnect(character, o, boardObj, pos)
    local a = X.Adapters.find(o)
    if not a then return false, "Tooltip_LWX_NotAnAppliance" end
    local record = X.Panel.isPanel(boardObj) and X.Panel.recordAt(boardObj:getSquare())
    if not record then return false, "Tooltip_LWX_PanelNotLinked" end
    if not X.Breakers.slotAt(record, tonumber(pos)) then return false, "Tooltip_LWX_NoBreakerThere" end
    if PT.point(X.Adapters.identity(o)) then return false, "Tooltip_LWX_PointConnected" end
    local I = LiveWire.Install
    if not I.screwdriver(character) then return false, "Tooltip_LW_NeedScrewdriver" end
    if not I.hasLevel(character, PT.LEVEL) then
        return false, "Tooltip_LWX_NeedLevel", tostring(LiveWire.Config.requiredLevel(PT.LEVEL))
    end
    local os_, bs = o:getSquare(), boardObj:getSquare()
    local dist, dz = I.distance(os_:getX(), os_:getY(), os_:getZ(), bs:getX(), bs:getY(), bs:getZ())
    local floors = LiveWire.Config.get("LinkVerticalRange")
    if dz > floors then return false, "Tooltip_LW_TooManyFloors", tostring(dz), tostring(floors) end
    local range = LiveWire.Config.get("LinkRange")
    if dist > range then
        return false, "Tooltip_LW_TooFarForCable", tostring(math.ceil(dist - 1e-9)), tostring(range)
    end
    local wires = I.wiresFor(dist)
    if I.countType(character, "Base.ElectricWire") < wires then return false, "Tooltip_LW_NeedWire", wires end
    return true, wires
end

-- Loaded objects of point `key` recorded at p.x, p.y, p.z (both sides).
function PT.objectsOf(key, p)
    local out = {}
    local sq = p and getCell():getGridSquare(p.x, p.y, p.z)
    local objs = sq and sq:getObjects()
    for i = 0, objs and objs:size() - 1 or -1 do
        local o = objs:get(i)
        if X.Adapters.find(o) and X.Adapters.identity(o) == key then out[#out + 1] = o end
    end
    return out
end
