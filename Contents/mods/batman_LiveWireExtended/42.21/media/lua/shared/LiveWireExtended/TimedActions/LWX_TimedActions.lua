-- LiveWire Extended: timed actions. Global classes: NetTimedAction finds them by name
-- and new() parameter names equal the fields (NetTimedAction.java:47-55, 145-172).
-- complete() runs in single player and on the server only, and re-checks everything.
require "TimedActions/ISBaseTimedAction"
require "LiveWireExtended/LWX_Core"

local X = LiveWire.Extended

local function stillThere(obj)
    return obj and obj:getSquare() and obj:getObjectIndex() ~= -1
end

local function near(character, sq, range)
    if not sq or math.floor(character:getZ()) ~= sq:getZ() then return false end
    return math.abs(character:getX() - (sq:getX() + 0.5)) <= range + 0.5
        and math.abs(character:getY() - (sq:getY() + 0.5)) <= range + 0.5
end

local function allowed(character, sq)
    if not SafeHouse then return true end
    return SafeHouse.isSafehouseAllowInteract(sq, character)
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

--------------------------------------------------------------------------------
-- Connect the building of an inverter, or disconnect one of its areas.
--------------------------------------------------------------------------------
LWXBuildingAction = ISBaseTimedAction:derive("LWXBuildingAction")

function LWXBuildingAction:isValid() return stillThere(self.target) end

function LWXBuildingAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function LWXBuildingAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWXBuildingAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
end

function LWXBuildingAction:stop() ISBaseTimedAction.stop(self) end
function LWXBuildingAction:perform() ISBaseTimedAction.perform(self) end

function LWXBuildingAction:complete()
    local ch, obj = self.character, self.target
    if not stillThere(obj) or not X.Connect then return false end
    local sq = obj:getSquare()
    if not near(ch, sq, 2) or not allowed(ch, sq) then return false end
    local dev = X.inverterOf(obj)
    if not dev then return false end
    if self.disconnect then return X.Connect.disconnect(ch, dev, self.areaKey) end
    return X.Connect.connectBuilding(ch, dev, dev.x, dev.y, dev.z, LiveWire.Config.tileRange(), nil)
end

function LWXBuildingAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 300
end

function LWXBuildingAction:new(character, target, disconnect, areaKey)
    local o = ISBaseTimedAction.new(self, character)
    o.target = target
    o.disconnect = disconnect == true
    o.areaKey = areaKey
    o.maxTime = o:getDuration()
    return o
end
