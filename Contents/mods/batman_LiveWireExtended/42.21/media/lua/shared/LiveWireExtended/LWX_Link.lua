-- LiveWire Extended: objects of this sub-mod linked to a Live Wire inverter with
-- electric wire (power terminal D-34, breaker board D-35). Live Wire's cable rules
-- (LW_Install: LinkRange, LinkVerticalRange, WirePerTiles) and the sub-mod's ModData
-- only: Live Wire's registry gets no new role. Shared by tooltips and the authority.
--   kind = { name, field, sprites = { [spriteName] = true }, level, linkedKey }
--   records: Data.table()[kind.field]["x,y,z"] = { x, y, z, inv = inverterId, ... }
require "LiveWireExtended/LWX_Data"

local X = LiveWire.Extended
local L = { kinds = {} }
X.Link = L

function L.key(x, y, z) return x .. "," .. y .. "," .. z end

function L.register(kind)
    L.kinds[#L.kinds + 1] = kind
    return kind
end

-- Kind of a placed object, from its sprite.
function L.kindOf(obj)
    local spr = obj and obj.getSprite and obj:getSprite()
    local name = spr and spr:getName()
    if not name then return nil end
    for i = 1, #L.kinds do
        if L.kinds[i].sprites[name] then return L.kinds[i] end
    end
    return nil
end

function L.objectOn(kind, sq)
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        if L.kindOf(objs:get(i)) == kind then return objs:get(i) end
    end
    return nil
end

function L.records(kind)
    local t = X.Data.table()
    t[kind.field] = t[kind.field] or {}
    return t[kind.field]
end

-- Public record of the `kind` object standing on square `sq`, or nil when not linked.
function L.recordAt(kind, sq)
    local list = X.Data.table()[kind.field]
    return list and list[L.key(sq:getX(), sq:getY(), sq:getZ())] or nil
end

-- Can `character` link object `obj` to inverter object `invObj`? Returns true, wires;
-- or false, key, arg1, arg2.
function L.check(character, obj, invObj)
    local API = LiveWire.API
    local kind = L.kindOf(obj)
    if not kind or not invObj then return false, "Tooltip_LWX_NoInverter" end
    local im = API.mark(invObj)
    local def = im and API.model(im.model)
    if not def or def.role ~= "inverter" or im.cpl then return false, "Tooltip_LWX_NoInverter" end
    local ts, is = obj:getSquare(), invObj:getSquare()
    if not ts or not is then return false, "Tooltip_LWX_NoInverter" end
    if L.recordAt(kind, ts) then return false, kind.linkedKey end
    -- floors, reach, level, wire: Live Wire's cable rules, with this sub-mod's own level key
    return API.cableCheck(character, ts, is, kind.level, "Tooltip_LWX_NeedLevel")
end
