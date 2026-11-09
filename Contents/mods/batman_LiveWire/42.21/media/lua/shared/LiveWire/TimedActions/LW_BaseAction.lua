-- Live Wire: base class of every timed action. Classes derived from it stay global
-- (NetTimedAction finds them by name, NetTimedAction.java:145-172). The helpers are
-- exported on LWBaseAction so that other timed action files can reuse them.
--
-- A derived class declares, as class fields (never as instance fields: only the
-- parameters of new() travel over the network, NetTimedAction.java:47-55):
--   duration       ticks of the action (1 when the character acts instantly)
--   range          squares around the subject the character may stand (default 2)
--   subject        name of the field holding the object (or square) acted on
--   subjectIsSquare true when that field holds an IsoGridSquare, not an IsoObject
--   facing         true to turn towards the subject before starting
--   partners       names of other fields that must still hold a placed object

require "TimedActions/ISBaseTimedAction"

LiveWire = LiveWire or {}

LWBaseAction = ISBaseTimedAction:derive("LWBaseAction")

LWBaseAction.range = 2
LWBaseAction.duration = 1

-- Full authority test: not a client, registry ready and writable, character alive.
function LWBaseAction.authorityReady(character)
    local registry = LiveWire.Registry
    return not isClient() and registry and registry.ready and not registry.readOnly
        and character and not character:isDead()
end

function LWBaseAction.instant(character)
    return character:isTimedActionInstant()
end

function LWBaseAction.objectStillThere(obj)
    return obj and obj:getSquare() and obj:getObjectIndex() ~= -1
end

function LWBaseAction.near(character, sq, range)
    if not sq then return false end
    if math.floor(character:getZ()) ~= sq:getZ() then return false end
    return math.abs(character:getX() - (sq:getX() + 0.5)) <= range + 0.5
        and math.abs(character:getY() - (sq:getY() + 0.5)) <= range + 0.5
end

function LWBaseAction.allowed(character, sq)
    if not SafeHouse then return true end
    return SafeHouse.isSafehouseAllowInteract(sq, character)
end

-- Sets the fields of the action (the parameters of the derived new()), then its length.
function LWBaseAction.new(class, character, fields)
    local o = ISBaseTimedAction.new(class, character)
    for k, v in pairs(fields) do o[k] = v end
    o.maxTime = o:getDuration()
    return o
end

function LWBaseAction:getDuration()
    if LWBaseAction.instant(self.character) then return 1 end
    return self.duration
end

function LWBaseAction:waitToStart()
    if not self.facing then return false end
    local subject = self[self.subject]
    if self.subjectIsSquare then
        self.character:faceLocation(subject:getX(), subject:getY())
    else
        self.character:faceThisObject(subject)
    end
    return self.character:shouldBeTurning()
end

-- Common start of complete(), authority side: authority ready (not a client, registry
-- ready and writable, character alive), objects still placed, character near enough,
-- safehouse rule. False when any test fails.
function LWBaseAction:guard()
    local ch = self.character
    if not LWBaseAction.authorityReady(ch) then return false end
    if not self.subject then return true end
    local sq
    if self.subjectIsSquare then
        sq = self[self.subject]
    else
        if not LWBaseAction.objectStillThere(self[self.subject]) then return false end
        sq = self[self.subject]:getSquare()
    end
    if self.partners then
        for _, name in ipairs(self.partners) do
            if not LWBaseAction.objectStillThere(self[name]) then return false end
        end
    end
    return LWBaseAction.near(ch, sq, self.range) and LWBaseAction.allowed(ch, sq)
end
