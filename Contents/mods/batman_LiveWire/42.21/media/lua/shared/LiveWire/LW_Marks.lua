-- Live Wire: the ModData mark that identifies our world objects and batteries.
-- The mark is only used to recognise an object; the server registry is authoritative
-- (a client can rewrite an object's ModData: docs/notes-moteur.md, note 11).

LiveWire = LiveWire or {}

local Marks = {}
LiveWire.Marks = Marks

Marks.KEY = "LiveWire"
Marks.VERSION = 1

local function markOf(holder)
    if not holder or not holder.getModData then return nil end
    local md = holder:getModData()
    local m = md and md[Marks.KEY]
    if type(m) == "table" and type(m.id) == "string" then return m end
    return nil
end

-- Placed device (IsoObject).
function Marks.get(obj)
    return markOf(obj)
end

function Marks.isOurs(obj)
    return markOf(obj) ~= nil
end

function Marks.set(holder, id, model, facing)
    holder:getModData()[Marks.KEY] = { id = id, model = model, facing = facing, s = Marks.VERSION }
end

function Marks.clear(holder)
    holder:getModData()[Marks.KEY] = nil
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
