-- Live Wire: sturdiness and wreckage of the placed equipment (Steam report 2026-11-16).
-- A solid moveable placed with the vanilla cursor becomes an IsoThumpable whose health is
-- its weight x 10 (ISMoveableSpriteProps.lua:322-324 and 2379-2384). On a 42.22.2 dedicated
-- server that weight reads 0 for our tiles (CustomItem), so they were placed with 0 health and
-- vanished at the first hit, leaving nothing behind (IsoThumpable.java:1047-1095; measured
-- in runs/20261116-112630-mp-9d8189cc3616). The authority raises the health of every equipment listed
-- here to HEALTH, and a destroyed one leaves PARTS on its square (LW_Sturdy.lua).
-- PARTS are the parts that always survive the matching dismantling recipe (its script
-- outputs, tests/test_wreckage.py): the electronic parts are lost with the device.
-- An equipment is found by the CustomItem property of its tile (the moveable item the
-- tile gives back), so a sub-mod adds its own through LiveWire.API.registerWreckage.
require "LiveWire/LW_Extension"

LiveWire = LiveWire or {}

local Wreckage = LiveWire.Wreckage or {}
LiveWire.Wreckage = Wreckage

-- A sledgehammer (DoorDamage 55, the strongest vanilla weapon) needs 55 hits, a pipe
-- wrench 300; a lone zombie removes 1 point per thump.
Wreckage.HEALTH = 3000
Wreckage.MAX_PARTS = 50

Wreckage.PARTS = Wreckage.PARTS or {}
local PARTS = Wreckage.PARTS
PARTS["Base.Mov_LiveWire_SolarPanel"] = { { "Base.SheetMetal", 1 }, { "Base.Screws", 2 } }
PARTS["Base.Mov_LiveWire_WindTurbine"] = { { "LiveWire.WindTurbineBlades", 1 },
                                           { "LiveWire.WindTurbineMast", 1 }, { "Base.Screws", 1 } }
PARTS["Base.Mov_LiveWire_WaterWheel"] = { { "Base.Plank", 6 }, { "Base.Nails", 10 }, { "Base.MetalBar", 1 } }
PARTS["Base.Mov_LiveWire_Inverter"] = { { "Base.SmallSheetMetal", 1 }, { "Base.Screws", 2 } }
PARTS["Base.Mov_LiveWire_InverterCabinet"] = { { "Base.SheetMetal", 1 }, { "Base.SmallSheetMetal", 1 },
                                               { "Base.Screws", 6 } }
PARTS["Base.Mov_LiveWire_PowerBank"] = { { "Base.SheetMetal", 1 }, { "Base.Screws", 2 } }
PARTS["Base.Mov_LiveWire_Breaker"] = { { "Base.SmallSheetMetal", 1 }, { "Base.Screws", 1 } }
PARTS["Base.Mov_LiveWire_BatteryAlarm"] = { { "Base.ElectricWire", 1 } }
PARTS["Base.Mov_LiveWire_WaterPump"] = { { "Base.MetalPipe", 2 }, { "Base.SmallSheetMetal", 1 },
                                         { "Base.Screws", 2 } }

local function identifier(v)
    return type(v) == "string" and #v <= 120 and string.match(v, "^[%w_]+%.[%w_]+$") ~= nil
end

-- Add the wreckage of a moveable item (`parts`: list of { fullType, count }). Returns true,
-- or false and "invalid_definition" / "duplicate_type". Registration is closed with the
-- other extension points (LW_Extension.lua).
function Wreckage.register(itemType, parts)
    if LiveWire.Extension.isSealed() then return false, "registration_closed" end
    if not identifier(itemType) or type(parts) ~= "table" or #parts == 0 then
        return false, "invalid_definition"
    end
    if PARTS[itemType] then return false, "duplicate_type" end
    local list, total = {}, 0
    for i = 1, #parts do
        local p = parts[i]
        local fullType, count = type(p) == "table" and p[1], type(p) == "table" and p[2]
        if not identifier(fullType) or type(count) ~= "number" or count ~= math.floor(count) or count < 1
            or not getScriptManager():FindItem(fullType) then
            return false, "invalid_definition"
        end
        total = total + count
        list[i] = { fullType, count }
    end
    if total > Wreckage.MAX_PARTS then return false, "invalid_definition" end
    PARTS[itemType] = list
    return true
end

-- The moveable item type of a placed equipment listed here, or nil.
function Wreckage.itemOf(obj)
    local spr = obj and obj.getSprite and obj:getSprite()
    local props = spr and spr:getProperties()
    local item = props and props:has("CustomItem") and props:get("CustomItem")
    if item and PARTS[item] then return item end
    return nil
end

function Wreckage.partsOf(obj)
    local item = Wreckage.itemOf(obj)
    return item and PARTS[item] or nil
end
