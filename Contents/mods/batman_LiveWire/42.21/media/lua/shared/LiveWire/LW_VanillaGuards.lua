-- Live Wire: keep vanilla pick-up, scrap and destroy away from our placed devices.
-- Display side: ISMoveableSpriteProps:canPickUpMoveable / canScrapObject and
-- ISDestroyCursor:canDestroy. Authority side: ISMoveablesAction:complete and
-- ISDestroyStuffAction:complete, because the server never calls isValid
-- (knowledge/multiplayer.md:43-49, 230). Wrappers keep vanilla arguments and
-- returns. Batteries are NOT protected: picking one up is the normal way to unlink it.
-- Our file loads before the vanilla classes (lower-case path order), so wrappers
-- are installed on the first start-up event that finds each class.

LiveWire = LiveWire or {}

local Guards = {}
LiveWire.Guards = Guards
Guards.done = {}

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

local function wrapPickUp()
    if Guards.done.pickUp or not ISMoveableSpriteProps then return end
    local original = ISMoveableSpriteProps.canPickUpMoveable
    ISMoveableSpriteProps.canPickUpMoveable = function(self, _character, _square, _object)
        if isOurs(_object) or (_object == nil and oursOnSquareWithSprite(_square, self.spriteName)) then
            return false
        end
        return original(self, _character, _square, _object)
    end
    local originalScrap = ISMoveableSpriteProps.canScrapObject
    ISMoveableSpriteProps.canScrapObject = function(self, _character)
        if self.isFromObject and isOurs(self.object) then
            return { canScrap = false, craftValid = false }, 0, nil
        end
        return originalScrap(self, _character)
    end
    Guards.done.pickUp = true
end

local function wrapDestroyCursor()
    if Guards.done.destroyCursor or not ISDestroyCursor then return end
    local original = ISDestroyCursor.canDestroy
    ISDestroyCursor.canDestroy = function(self, object)
        if isOurs(object) then return false end
        return original(self, object)
    end
    Guards.done.destroyCursor = true
end

local function wrapMoveablesAction()
    if Guards.done.moveables or not ISMoveablesAction then return end
    local original = ISMoveablesAction.complete
    ISMoveablesAction.complete = function(self)
        if (self.mode == "pickup" or self.mode == "scrap")
            and (isOurs(self.object) or oursOnSquareWithSprite(self.square, self.origSpriteName)) then
            LiveWire.log("refused vanilla " .. tostring(self.mode) .. " on a Live Wire device")
            return false
        end
        return original(self)
    end
    Guards.done.moveables = true
end

local function wrapDestroyAction()
    if Guards.done.destroy or not ISDestroyStuffAction then return end
    local original = ISDestroyStuffAction.complete
    ISDestroyStuffAction.complete = function(self)
        if isOurs(self.item) then
            LiveWire.log("refused vanilla destroy on a Live Wire device")
            return false
        end
        return original(self)
    end
    Guards.done.destroy = true
end

function Guards.install()
    wrapPickUp()
    wrapDestroyCursor()
    wrapMoveablesAction()
    wrapDestroyAction()
end

Events.OnGameBoot.Add(Guards.install)
Events.OnGameStart.Add(Guards.install)
Events.OnInitGlobalModData.Add(Guards.install)
if Events.OnServerStarted then Events.OnServerStarted.Add(Guards.install) end
