-- LiveWire Extended: power terminal rules shared by client tooltips and the authority.
require "LiveWireExtended/LWX_Data"

local X = LiveWire.Extended
local T = {}
X.Terminal = T

T.SHEET = "batman_livewireext_01"   -- tiles 0..3 (source/tiles/build_extended_tiles.py)
T.LEVEL = 3                          -- make and link a terminal (D-34 defaults)
local SPRITES = {}
for i = 0, 3 do SPRITES[T.SHEET .. "_" .. i] = true end

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

function T.key(x, y, z) return x .. "," .. y .. "," .. z end

function T.isTerminal(obj)
    local spr = obj and obj.getSprite and obj:getSprite()
    local name = spr and spr:getName()
    return name ~= nil and SPRITES[name] == true
end

function T.onSquare(sq)
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        if T.isTerminal(objs:get(i)) then return objs:get(i) end
    end
    return nil
end

-- Public record of the terminal standing on square `sq`, or nil when not linked.
function T.recordAt(sq)
    local terminals = X.Data.table().terminals
    return terminals and terminals[T.key(sq:getX(), sq:getY(), sq:getZ())] or nil
end

-- Can `character` link terminal `obj` to inverter object `invObj`? Live Wire's cable
-- rules (LW_Install). Returns true, wires; or false, key, arg1, arg2.
function T.checkLink(character, obj, invObj)
    local I = LiveWire.Install
    if not T.isTerminal(obj) or not invObj then return false, "Tooltip_LWX_NoInverter" end
    local im = LiveWire.Marks.get(invObj)
    local def = im and LiveWire.Defs.devices[im.model]
    if not def or def.role ~= "inverter" or im.cpl then return false, "Tooltip_LWX_NoInverter" end
    local ts, is = obj:getSquare(), invObj:getSquare()
    if not ts or not is then return false, "Tooltip_LWX_NoInverter" end
    if T.recordAt(ts) then return false, "Tooltip_LWX_TerminalLinked" end
    local dist, dz = I.distance(ts:getX(), ts:getY(), ts:getZ(), is:getX(), is:getY(), is:getZ())
    local floors = LiveWire.Config.get("LinkVerticalRange")
    if dz > floors then return false, "Tooltip_LW_TooManyFloors", tostring(dz), tostring(floors) end
    local range = LiveWire.Config.get("LinkRange")
    if dist > range then
        return false, "Tooltip_LW_TooFarForCable", tostring(math.ceil(dist - 1e-9)), tostring(range)
    end
    if not I.hasLevel(character, T.LEVEL) then
        return false, "Tooltip_LWX_NeedLevel", tostring(LiveWire.Config.requiredLevel(T.LEVEL))
    end
    local wires = I.wiresFor(dist)
    if I.countType(character, "Base.ElectricWire") < wires then
        return false, "Tooltip_LW_NeedWire", wires
    end
    return true, nil, wires
end
