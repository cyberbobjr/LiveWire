-- Live Wire: the ModData mark that identifies our placed devices.
-- The mark lives in modData.movableData, the only part of the ModData that
-- vanilla carries over when a plain IsoObject is picked up and placed again
-- (ISMoveableSpriteProps.lua:1403-1404, 2423-2424; an IsoThumpable keeps its
-- whole ModData). It carries the device state that must follow the object
-- (condition, installation efficiency). The server registry stays authoritative:
-- a client can rewrite an object's ModData (docs/annexes/recherches/notes-moteur.md, note 11).

LiveWire = LiveWire or {}

local Marks = {}
LiveWire.Marks = Marks

Marks.KEY = "LiveWire"
Marks.VERSION = 2

local function markOf(holder)
    if not holder or not holder.getModData then return nil end
    if holder.hasModData and not holder:hasModData() then return nil end
    local md = holder:getModData()
    local mv = md and md.movableData
    local m = type(mv) == "table" and mv[Marks.KEY]
    if type(m) == "table" and type(m.id) == "string" then return m end
    return nil
end

-- Placed device (IsoObject).
function Marks.get(obj)
    return markOf(obj)
end

-- True when the object is one of our devices (its tile) with a registry mark.
function Marks.isOurs(obj)
    return markOf(obj) ~= nil and LiveWire.Defs.modelOfObject(obj) ~= nil
end

-- Raw mark table even without an id (state carried by a picked-up device).
function Marks.raw(holder)
    if not holder or not holder.getModData then return nil end
    local md = holder:getModData()
    local mv = md and md.movableData
    local m = type(mv) == "table" and mv[Marks.KEY]
    if type(m) == "table" then return m end
    return nil
end

-- Write the mark (fields: id, model, cond, eff, level).
function Marks.set(holder, fields)
    local md = holder:getModData()
    if type(md.movableData) ~= "table" then md.movableData = {} end
    local m = {}
    for k, v in pairs(fields) do m[k] = v end
    m.s = Marks.VERSION
    md.movableData[Marks.KEY] = m
end

-- Find our device object on a square by id.
function Marks.findOnSquare(sq, id)
    if not sq then return nil end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local m = markOf(o)
        if m and m.id == id then return o end
    end
    return nil
end

-- First of our device objects on a square (any id).
function Marks.firstOnSquare(sq)
    if not sq then return nil end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if markOf(o) then return o end
    end
    return nil
end
