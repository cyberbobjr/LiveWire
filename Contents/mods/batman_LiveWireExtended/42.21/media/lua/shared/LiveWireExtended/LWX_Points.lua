-- LiveWire Extended: points wired to a breaker (D-36, D-37, D-41), rules shared by
-- client menus and the authority. A point is what an adapter calls one appliance: a
-- single object, every piece of a multi-tile appliance, or a room with its wall
-- switches (LWX_Adapters identity).
--   points[identity] = { board = "x,y,z", pos = module, x, y, z, adapter }
--   and the breaker slot lists it: slot.points[identity] = true
-- D-37, D-62: a linked board serves the site of the wall face it hangs on (X.Sites). In a
-- served site, an appliance wired to no breaker has no current; outside any served site the
-- usual rule applies (everything powered).
require "LiveWireExtended/LWX_Panel"
require "LiveWireExtended/LWX_Breakers"
require "LiveWireExtended/LWX_Adapters"

local X = LiveWire.Extended
local D = X.Data
local PT = {}
X.Points = PT

PT.XP = 5      -- D-41: per connection (once per point and day)

function PT.table()
    local t = D.table()
    t.points = t.points or {}
    return t.points
end

function PT.point(key) return key and PT.table()[key] or nil end

local function boards() return D.table().panels or {} end

-- Calls fn(x, y, z) for every square of the site served by board `record` (X.Panel.siteOf):
-- the rooms of its building (every floor), or the floor of its enclosure (X.Sites). Returns
-- false when the board serves no site (fn never called). Several boards may serve the same
-- site; each one walks it whole.
function PT.eachRegionSquare(record, fn)
    local site = record and X.Panel.siteOf(record)
    if not site then return false end
    X.Sites.eachSquare(site, fn)
    return true
end

-- Points of the region served by board `record`, one entry per point (a multi-tile appliance
-- or a room's switches count once): { key, o, d2 } with o its first loaded object found and d2
-- the squared distance from the board to its nearest square. nil when the board serves no
-- region. The one region query of the views (window tint, wiring menu); wired or not, the
-- caller decides with PT.point(key).
function PT.regionPoints(record)
    local cell, Ad, list, byKey = getCell(), X.Adapters, {}, {}
    local served = PT.eachRegionSquare(record, function(x, y, z)
        local sq = cell:getGridSquare(x, y, z)
        local objs = sq and sq:getObjects()
        for i = 0, objs and objs:size() - 1 or -1 do
            local o = objs:get(i)
            local key = Ad.find(o) and Ad.identity(o)
            if key then
                local d2 = (x - record.x) * (x - record.x) + (y - record.y) * (y - record.y)
                local e = byKey[key]
                if not e then
                    e = { key = key, o = o, d2 = d2 }
                    byKey[key], list[#list + 1] = e, e
                elseif d2 < e.d2 then
                    e.d2 = d2
                end
            end
        end
    end)
    return served and list or nil
end

-- Served sites, rebuilt when the boards change: building key -> board key, and the boards
-- that serve an enclosure (an enclosure is compared live: X.Sites never keeps a region).
local served, servedRev = nil, nil
PT.rev = 0
function PT.changed() PT.rev = PT.rev + 1 end
function PT.servedIndex()
    if served and servedRev == PT.rev then return served end
    served, servedRev = { buildings = {}, enclosures = {} }, PT.rev
    for key, r in pairs(boards()) do
        local site = X.Panel.siteOf(r)
        if site and site.kind == "building" then
            served.buildings[X.Sites.key(site)] = key
        elseif site then
            served.enclosures[#served.enclosures + 1] = r
        end
    end
    return served
end

-- Is the square in a site served by a board?
function PT.servedAt(x, y, z)
    local site = X.Sites.at(x, y, z)
    if not site then return false end
    local index = PT.servedIndex()
    if site.kind == "building" then return index.buildings[X.Sites.key(site)] ~= nil end
    for _, r in ipairs(index.enclosures) do
        if X.Sites.same(site, X.Panel.siteOf(r)) then return true end
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
    if slot then return X.Breakers.isOpen(slot) end
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
    local API = LiveWire.API
    if not API.screwdriver(character) then return false, "Tooltip_LW_NeedScrewdriver" end
    -- the voltage tester checks the circuit is dead before wiring (kept, not used up)
    if API.countType(character, "LiveWire.VoltageTester") < 1 then return false, "Tooltip_LWX_NeedTester" end
    if not API.hasLevel(character, X.LEVEL) then
        return false, "Tooltip_LWX_NeedLevel", tostring(LiveWire.Config.requiredLevel(X.LEVEL))
    end
    -- the level was checked above (before the distance, as always): no level asked here
    local ok, why, arg1, arg2 = API.cableCheck(character, o:getSquare(), boardObj:getSquare())
    if not ok then return false, why, arg1, arg2 end
    return true, arg1
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
