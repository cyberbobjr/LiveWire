-- Live Wire: keep vanilla scrap and destroy away from our placed devices. Picking
-- up, placing and rotating them is vanilla on purpose (LW_Placement.lua).
-- Display side: ISMoveableSpriteProps:canScrapObject and ISDestroyCursor:canDestroy.
-- Authority side: ISMoveablesAction:complete and ISDestroyStuffAction:complete,
-- because the server never calls isValid (knowledge/multiplayer.md:43-49, 230).
-- Wrappers keep vanilla arguments and returns. Three classes are shared vanilla files
-- (media/lua/shared), required here and wrapped once while this file loads, like
-- LW_Placement.lua. ISDestroyCursor lives in media/lua/server/BuildingObjects, which
-- the game adds to the require path only when the world starts loading
-- (GameLoadingState.enter), after this shared file ran: a require would find nothing.
-- It is wrapped once at OnGameStart (and at load when the class is already there, as
-- after a Lua reload); a client in multiplayer runs it too, so it cannot move into a
-- server/ file that returns on a client.
require "LiveWire/LW_Marks"
require "LiveWire/LW_Defs"
require "Moveables/ISMoveableSpriteProps"
require "Moveables/ISMoveablesAction"
require "TimedActions/ISDestroyStuffAction"

LiveWire = LiveWire or {}

local Guards = {}
LiveWire.Guards = Guards

local function isOurs(obj)
    return obj ~= nil and LiveWire.Marks.isOurs(obj)
end

-- Is there one of our devices on `sq` drawn with `spriteName`?
local function oursOnSquareWithSprite(sq, spriteName)
    if not sq then return false end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if isOurs(o) then
            local spr = o:getSprite()
            if not spriteName or (spr and spr:getName() == spriteName) then return true end
        end
    end
    return false
end

-- Destroying a wall also removes the objects attached to it
-- (ISDestroyStuffAction.lua:163-200). Our wall devices (breaker, alarm) are
-- placed on the square of their wall: refuse when the square holds one.
local function carriesOurDevice(obj)
    local sq = obj and obj.getSquare and obj:getSquare()
    if not sq or isOurs(obj) then return false end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local model = isOurs(o) and LiveWire.Defs.modelOfObject(o)
        if model and LiveWire.Defs.devices[model].facings == 2 then return true end
    end
    return false
end

do
    local originalScrap = ISMoveableSpriteProps.canScrapObject
    ISMoveableSpriteProps.canScrapObject = function(self, _character)
        if self.isFromObject and isOurs(self.object) then
            return { canScrap = false, craftValid = false }, 0, nil
        end
        return originalScrap(self, _character)
    end
end

do
    local original = ISMoveablesAction.complete
    ISMoveablesAction.complete = function(self)
        if self.mode == "scrap"
            and (isOurs(self.object) or oursOnSquareWithSprite(self.square, self.origSpriteName)) then
            LiveWire.log("refused vanilla " .. tostring(self.mode) .. " on a Live Wire device")
            return false
        end
        return original(self)
    end
end

do
    local original = ISDestroyStuffAction.complete
    ISDestroyStuffAction.complete = function(self)
        if isOurs(self.item) or carriesOurDevice(self.item) then
            LiveWire.log("refused vanilla destroy on a Live Wire device")
            return false
        end
        return original(self)
    end
end

-- Display side of the destroy tool. Idempotent: wraps ISDestroyCursor.canDestroy once.
local cursorWrapped = false
function Guards.installCursor()
    if cursorWrapped or not ISDestroyCursor then return end
    local original = ISDestroyCursor.canDestroy
    ISDestroyCursor.canDestroy = function(self, object)
        if isOurs(object) or carriesOurDevice(object) then return false end
        return original(self, object)
    end
    cursorWrapped = true
end

Guards.installCursor()
Events.OnGameStart.Add(Guards.installCursor)
