-- LiveWire Extended: registry of appliance adapters (D-38). An adapter tells what an
-- appliance is to a breaker: is it one, which objects form it, its draw, its state,
-- and how to cut and restore it. Vanilla families reuse Live Wire's I21 service
-- adapters through the circuit extension point (LW_CircuitProvider): their cut is
-- decided here and carried out by LiveWire.Circuits, nothing is copied.
--
-- Adapter contract (table):
--   id                    unique name ("vanilla", a mod id...)
--   recognize(o) -> bool  is this world object one of mine?
--   pieces(o)    -> array of the world objects forming the point (all the pieces of a
--                   multi-tile appliance, the live wall switches of a room)
--   watts(o)     -> current draw of the whole point, W (multi-tile counted once, D-31)
--   isOn(o)      -> is the point's service running?
--   apply(o, off)   cut (off = true) or restore (off = false) the point, authority only
--   identity(o)  -> optional: stable key of the point; default: grid origin + sprite
-- Mod adapters are tried before the vanilla one, in registration order.
require "LiveWire/LW_CircuitProvider"
require "LiveWireExtended/LWX_Core"

local X = LiveWire.Extended
local Ad = { list = {} }
X.Adapters = Ad

local REQUIRED = { "recognize", "pieces", "watts", "isOn", "apply" }
local vanilla

function Ad.register(a)
    if type(a) ~= "table" or type(a.id) ~= "string" then return false, "invalid_adapter" end
    for i = 1, #REQUIRED do
        if type(a[REQUIRED[i]]) ~= "function" then return false, "invalid_adapter" end
    end
    for i = 1, #Ad.list do
        if Ad.list[i].id == a.id then return false, "already_registered" end
    end
    if a.id == "vanilla" then vanilla = a else Ad.list[#Ad.list + 1] = a end
    return true
end

function Ad.find(o)
    if not o then return nil end
    for i = 1, #Ad.list do
        if Ad.list[i].recognize(o) then return Ad.list[i] end
    end
    if vanilla and vanilla.recognize(o) then return vanilla end
    return nil
end

-- ---------------------------------------------------------------- identity
-- Grid origin of a multi-tile object: its own square minus its position in the sprite
-- grid, and the name of the grid's first sprite. The same key from every piece, even
-- when the origin square is not loaded.
local function gridKey(o)
    local sq, spr = o:getSquare(), o:getSprite()
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local name = spr and spr:getName() or "?"
    local g = o:getSpriteGrid()
    if g and g:getSpriteCount() > 1 and spr then
        x, y, z = x - g:getSpriteGridPosX(spr), y - g:getSpriteGridPosY(spr), z - g:getSpriteGridPosZ(spr)
        local first = g:getSprite(0, 0)
        if first then name = first:getName() end
    end
    return x .. "," .. y .. "," .. z .. ":" .. name
end
Ad.gridKey = gridKey

-- A native wall switch commands its whole room (IsoLightSwitch.switchLight): one point
-- per room, keyed by its RoomDef corner and floor.
local function roomSwitch(o)
    return instanceof(o, "IsoLightSwitch") and not o:getCanBeModified() and o:getSquare():getRoom() ~= nil
end
local function roomKey(o)
    local def = o:getSquare():getRoom():getRoomDef()
    return "room:" .. def:getX() .. "," .. def:getY() .. "," .. def:getZ()
end

function Ad.identity(o)
    local a = Ad.find(o)
    if not a then return nil end
    if a.identity then return a.identity(o) end
    return gridKey(o)
end

-- Loaded world object (not a stale copy left by an older chunk load, E12).
local function live(o)
    local sq = o and o:getSquare()
    return sq ~= nil and o:getObjectIndex() ~= -1 and getCell():getGridSquare(sq:getX(), sq:getY(), sq:getZ()) == sq
end
Ad.live = live

-- ---------------------------------------------------------------- cut state
-- cuts[identity] = true while the point's breaker is open. Session table here; the
-- persistent state of points and breakers replaces Ad.isCutKey (E17).
Ad.cuts = {}
function Ad.isCutKey(key) return Ad.cuts[key] == true end
function Ad.isCut(o)
    local key = Ad.identity(o)
    return key ~= nil and Ad.isCutKey(key)
end

-- Cut or restore a point on the authority, whatever its adapter.
function Ad.set(o, off)
    local a = Ad.find(o)
    if not a then return false end
    Ad.cuts[Ad.identity(o)] = off and true or nil
    a.apply(o, off)
    return true
end

-- ---------------------------------------------------------------- vanilla families
local A = function() return LiveWire.Appliances end
local pieceList

local V = { id = "vanilla" }
function V.recognize(o) return A().kind(o) ~= nil end
function V.identity(o)
    if roomSwitch(o) then return roomKey(o) end
    return gridKey(o)
end
function V.pieces(o)
    local out = {}
    if roomSwitch(o) then
        local sw = o:getSquare():getRoom():getLightSwitches()
        for i = 0, sw:size() - 1 do
            local s = sw:get(i)
            if live(s) then out[#out + 1] = s end
        end
        return out
    end
    local g = o:getSpriteGrid()
    if g and g:getSpriteCount() > 1 then
        pieceList = pieceList or ArrayList.new()
        o:getSpriteGridObjectsIncludingSelf(pieceList)
        for i = 0, pieceList:size() - 1 do
            local p = pieceList:get(i)
            if A().kind(p) then out[#out + 1] = p end
        end
        pieceList:clear()
        if #out > 0 then return out end
    end
    return { o }
end
function V.watts(o)
    local w = 0
    for _, p in ipairs(V.pieces(o)) do w = w + LiveWire.Consumption.watts(p) end
    return w
end
function V.isOn(o)
    for _, p in ipairs(V.pieces(o)) do
        local s = A().saved(p)
        if not (s and s.cut) then return true end
    end
    return false
end
-- The decision is read back by LiveWire.Circuits through the provider below.
function V.apply(o, off)
    if not LiveWire.Circuits then return end
    for _, p in ipairs(V.pieces(o)) do LiveWire.Circuits.applyObject(p) end
end
Ad.register(V)
Ad.vanilla = V

-- Live Wire asks, for each native appliance: is it cut by a breaker of Extended?
X.circuitProvider = { blocked = function(o) return Ad.isCut(o) end }
X.circuitProviderRegistered = LiveWire.CircuitProvider.register(X.circuitProvider) == true
