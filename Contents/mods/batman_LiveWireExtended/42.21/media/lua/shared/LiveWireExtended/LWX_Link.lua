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

-- Registry inverter behind a placed Live Wire object (authority only).
function X.inverterOf(obj)
    local m = LiveWire.Marks.get(obj)
    local R = LiveWire.Registry
    if not m or not R or not R.ready or isClient() then return nil end
    local dev = R.device(m.id)
    local sq = obj:getSquare()
    if not dev or dev.role ~= "inverter" or dev.coupled or not sq
        or dev.x ~= sq:getX() or dev.y ~= sq:getY() or dev.z ~= sq:getZ() then return nil end
    return dev
end

-- Can `character` link object `obj` to inverter object `invObj`? Returns true, wires;
-- or false, key, arg1, arg2.
function L.check(character, obj, invObj)
    local I = LiveWire.Install
    local kind = L.kindOf(obj)
    if not kind or not invObj then return false, "Tooltip_LWX_NoInverter" end
    local im = LiveWire.Marks.get(invObj)
    local def = im and LiveWire.Defs.devices[im.model]
    if not def or def.role ~= "inverter" or im.cpl then return false, "Tooltip_LWX_NoInverter" end
    local ts, is = obj:getSquare(), invObj:getSquare()
    if not ts or not is then return false, "Tooltip_LWX_NoInverter" end
    if L.recordAt(kind, ts) then return false, kind.linkedKey end
    local dist, dz = I.distance(ts:getX(), ts:getY(), ts:getZ(), is:getX(), is:getY(), is:getZ())
    local floors = LiveWire.Config.get("LinkVerticalRange")
    if dz > floors then return false, "Tooltip_LW_TooManyFloors", tostring(dz), tostring(floors) end
    local range = LiveWire.Config.get("LinkRange")
    if dist > range then
        return false, "Tooltip_LW_TooFarForCable", tostring(math.ceil(dist - 1e-9)), tostring(range)
    end
    if not I.hasLevel(character, kind.level) then
        return false, "Tooltip_LWX_NeedLevel", tostring(LiveWire.Config.requiredLevel(kind.level))
    end
    local wires = I.wiresFor(dist)
    if I.countType(character, "Base.ElectricWire") < wires then
        return false, "Tooltip_LW_NeedWire", wires
    end
    return true, nil, wires
end
