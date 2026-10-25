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
require "LiveWire/LW_Stack"

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
-- (FishingZones.lua:40-47). Lakes and ponds are refused (docs/specifications-fonctionnelles.md 3.4).
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
    if model == "PowerBank" then return LiveWire.Stack.canPlace(sq) end
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

local origCanPick = MP.canPickUpMoveableInternal
function MP:canPickUpMoveableInternal(character,square,object,isMulti,...)
    if object and not LiveWire.Stack.canMove(object) then return false end
    return origCanPick(self,character,square,object,isMulti,...)
end
local origCanRotate = MP.canRotateMoveableInternal
function MP:canRotateMoveableInternal(square,object,...)
    if object and not LiveWire.Stack.canMove(object) then return false end
    return origCanRotate(self,square,object,...)
end

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
            local def = LiveWire.Defs.devices[model]
            if def and def.kind == "solar" then
                local facing = (tonumber(string.match(self.spriteName, "_(%d+)$")) - def.tile) % 4
                info = MP.addLineToInfoTable(info, getText("IGUI_LW_Facing_" .. facing), 180, 220, 255)
            end
        end
    end
    if (_mode=="pickup" or _mode=="rotate") and _object and type(info)=="table" then
        local ok,why=LiveWire.Stack.canMove(_object)
        if not ok and why then info=MP.addLineToInfoTable(info,getText(why),255,60,60) end
    end
    return info
end

local origPlace = MP.placeMoveableInternal
function MP:placeMoveableInternal(_character, _square, _item, _spriteName, ...)
    local r = origPlace(self, _character, _square, _item, _spriteName, ...)
    if _square then
        if LiveWire.Pump then LiveWire.Pump.invalidateAt(_square) end
        if LiveWire.PumpView then LiveWire.PumpView.invalidateAt(_square) end
        if LiveWire.Anchor then LiveWire.Anchor.rememberSquare(_square) end
    end
    if _square and modelOfSprite(_spriteName) and authority() then
        LiveWire.Devices.onPlaced(_character, _square, _spriteName)
    end
    -- Any furniture placed (a fridge moved, a lamp...): rebuild the appliance list of
    -- the inverters in range (LW_Demand.lua).
    if _square and LiveWire.isAuthority() and LiveWire.Demand and LiveWire.Demand.invalidateAt then
        LiveWire.Demand.invalidateAt(_square)
        if LiveWire.Circuits then
            local objects = _square:getObjects()
            for i = 0, objects:size() - 1 do LiveWire.Circuits.applyObject(objects:get(i)) end
        end
    end
    return r
end

local origPickUp = MP.pickUpMoveableInternal
function MP:pickUpMoveableInternal(_character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating, ...)
    if _object and not _sprInstance and not LiveWire.Stack.canMove(_object) then return nil end
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
    if modelOfSprite(_origSpriteName)=="PowerBank" then
        local obj=self:findOnSquare(_square,_origSpriteName)
        if not obj or not self:canRotateMoveableInternal(_square,obj) then return end
    end
    local ours = authority() and modelOfSprite(_origSpriteName) ~= nil
    if ours then LiveWire.Devices.beginRotation() end
    local r = origRotate(self, _character, _square, _origSpriteName, ...)
    if ours then LiveWire.Devices.endRotation() end
    return r
end
