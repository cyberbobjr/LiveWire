-- Live Wire: sturdy equipment and its wreckage (authority only, LW_Wreckage.lua).
-- Health: set when the equipment is placed (placement wrappers, SQUARE_OBJECTS_CHANGED)
-- and on the equipment already in a save when its chunk is walked (chunk visitor). The
-- engine saves the health of an IsoThumpable, and only the authority applies weapon and
-- zombie damage (IsoThumpable.WeaponHit returns at once on an MP client), so nothing is sent.
-- Wreckage: OnDestroyIsoThumpable fires on the authority for a weapon (WeaponHit) and for
-- zombies (IsoThumpable.destroy); the vanilla handler (ISBuildingObject.onDestroy) has
-- already dropped the contents and removed the object, which keeps its square. The
-- registry drops the device when its square is checked (Devices.validate).
if isClient() then return end
require "LiveWire/LW_Wreckage"
require "LiveWire/LW_Circuits"
require "LiveWire/LW_EventBus"

LiveWire = LiveWire or {}

local Wreckage = LiveWire.Wreckage

-- Raise a weaker listed equipment to full HEALTH. Returns true when it changed.
function Wreckage.harden(obj)
    if not instanceof(obj, "IsoThumpable") or not Wreckage.partsOf(obj) then return false end
    if obj:getMaxHealth() >= Wreckage.HEALTH then return false end
    obj:setMaxHealth(Wreckage.HEALTH)
    obj:setHealth(Wreckage.HEALTH)
    return true
end

function Wreckage.hardenSquare(sq)
    if not sq then return end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do Wreckage.harden(objs:get(i)) end
end

-- Leave the parts of a destroyed equipment on its square.
function Wreckage.onDestroyed(obj)
    local parts = Wreckage.partsOf(obj)
    local sq = parts and obj:getSquare()
    if not sq then return end
    for _, part in ipairs(parts) do
        for _ = 1, part[2] do
            sq:AddWorldInventoryItem(part[1], ZombRandFloat(0.2, 0.8), ZombRandFloat(0.2, 0.8), 0)
        end
    end
    LiveWire.log("equipment " .. tostring(Wreckage.itemOf(obj)) .. " destroyed at "
        .. LiveWire.posKey(sq:getX(), sq:getY(), sq:getZ()) .. ", parts left on the ground")
end

LiveWire.Events.on(LiveWire.Events.SQUARE_OBJECTS_CHANGED, function(sq) return LiveWire.Wreckage.hardenSquare(sq) end)
LiveWire.Circuits.addChunkVisitor(function(obj) return LiveWire.Wreckage.harden(obj) end)
Events.OnDestroyIsoThumpable.Add(function(obj) return LiveWire.Wreckage.onDestroyed(obj) end)
