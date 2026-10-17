-- Live Wire: our devices are tiles placed and picked up with the vanilla furniture
-- cursor (ISMoveableSpriteProps). The Electrical level and the screwdriver come
-- from the tile properties. This file adds our own placement rules (open sky,
-- river bank) and tells the authority when one of our tiles is placed, picked up or
-- rotated (LW_Devices.lua). Every wrapper keeps the vanilla arguments and results.
--
-- Vanilla paths (Build 42.21, shared/Moveables/ISMoveableSpriteProps.lua):
--   place:  ISMoveablesAction:complete -> placeMoveable -> canPlaceMoveableInternal,
--           placeMoveableInternal (server in MP);
--   pickup: pickUpMoveable -> pickUpMoveableInternal, which copies movableData
--           into the item before removing the object (:1400-1404, :1491-1494);
--   rotate: rotateMoveable = pickUpMoveable then placeMoveable on the same square.

require "Moveables/ISMoveableSpriteProps"

LiveWire = LiveWire or {}

local Placement = {}
LiveWire.Placement = Placement

local function modelOfSprite(name)
    if not name then return nil end
    return LiveWire.Defs.spriteToModel[name]
end
Placement.modelOfSprite = modelOfSprite

-- A neighbour of `sq` (8 directions) is river water: water flag
-- (FishingUtils.lua:4-9) inside a river zone of the fishing code
-- (FishingZones.lua:40-47). Lakes and ponds are refused (docs/fonctionnel.md 3.4).
function Placement.nextToRiver(sq)
    local cell = getCell()
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x, y = sq:getX() + dx, sq:getY() + dy
                local n = cell:getGridSquare(x, y, sq:getZ())
                if n and n:has(IsoFlagType.water)
                    and (not Fishing or not Fishing.isRiver or Fishing.isRiver(x, y)) then
                    return true
                end
            end
        end
    end
    return false
end

-- Our rules on top of the vanilla ones. Returns true, or false and a tooltip key.
function Placement.check(model, sq)
    local def = LiveWire.Defs.devices[model]
    if not def or not sq then return false, "Tooltip_LW_Invalid" end
    if def.needsOutside and not sq:isOutside() then return false, "Tooltip_LW_NeedOutdoor" end
    if def.needsRiver and (sq:getZ() ~= 0 or not Placement.nextToRiver(sq)) then
        return false, "Tooltip_LW_NeedWaterSide"
    end
    return true
end

local function authority()
    return LiveWire.isAuthority() and LiveWire.Devices ~= nil
end

local MP = ISMoveableSpriteProps

local origCanPlace = MP.canPlaceMoveableInternal
function MP:canPlaceMoveableInternal(_character, _square, _item, _forceTypeObject, ...)
    local ok = origCanPlace(self, _character, _square, _item, _forceTypeObject, ...)
    if ok and _square then
        local model = modelOfSprite(self.spriteName)
        if model and not Placement.check(model, _square) then return false end
    end
    return ok
end

-- Explain a refusal in the cursor info panel (only for our tiles).
local origInfo = MP.getInfoPanelDescription
function MP:getInfoPanelDescription(_square, _object, _player, _mode, ...)
    local info = origInfo(self, _square, _object, _player, _mode, ...)
    if _mode == "place" and _square and type(info) == "table" then
        local model = modelOfSprite(self.spriteName)
        if model then
            local ok, why = Placement.check(model, _square)
            if not ok then
                info = MP.addLineToInfoTable(info, getText(why), 255, 60, 60)
            end
        end
    end
    return info
end

local origPlace = MP.placeMoveableInternal
function MP:placeMoveableInternal(_character, _square, _item, _spriteName, ...)
    local r = origPlace(self, _character, _square, _item, _spriteName, ...)
    if _square and modelOfSprite(_spriteName) and authority() then
        LiveWire.Devices.onPlaced(_character, _square, _spriteName)
    end
    return r
end

local origPickUp = MP.pickUpMoveableInternal
function MP:pickUpMoveableInternal(_character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating, ...)
    local id = nil
    if _object and not _sprInstance and authority() and LiveWire.Defs.modelOfObject(_object) then
        id = LiveWire.Devices.beforePickUp(_object)
    end
    local r = origPickUp(self, _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating, ...)
    if id and _object:getObjectIndex() == -1 then
        LiveWire.Devices.onPickedUp(id)
    end
    return r
end

local origRotate = MP.rotateMoveable
function MP:rotateMoveable(_character, _square, _origSpriteName, ...)
    local ours = authority() and modelOfSprite(_origSpriteName) ~= nil
    if ours then LiveWire.Devices.beginRotation() end
    local r = origRotate(self, _character, _square, _origSpriteName, ...)
    if ours then LiveWire.Devices.endRotation() end
    return r
end
