-- Live Wire: placement rules and shared helpers for timed actions.
-- Used by the client (menu tooltips) and re-checked by the authority in complete().

LiveWire = LiveWire or {}

local Install = {}
LiveWire.Install = Install

local function notBroken(item)
    return not item:isBroken()
end

function Install.screwdriver(character)
    return character:getInventory():getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, notBroken)
end

function Install.level(character)
    return character:getPerkLevel(Perks.Electricity)
end

function Install.hasLevel(character, required)
    return Install.level(character) >= LiveWire.Config.requiredLevel(required)
end

function Install.countType(character, fullType)
    return character:getInventory():getCountTypeRecurse(fullType)
end

-- Remove `n` items of a type from the character's inventory (bags included).
function Install.consume(character, fullType, n)
    if n <= 0 then return true end
    local list = character:getInventory():getSomeTypeRecurse(fullType, n)
    if list:size() < n then return false end
    for i = 0, list:size() - 1 do
        local item = list:get(i)
        local container = item:getContainer()
        if container then
            character:removeFromHands(item)
            container:DoRemoveItem(item)
            sendRemoveItemFromContainer(container, item)
        end
    end
    return true
end

function Install.removeItem(character, item)
    local container = item:getContainer()
    if not container then return false end
    character:removeFromHands(item)
    container:DoRemoveItem(item)
    sendRemoveItemFromContainer(container, item)
    return true
end

function Install.giveItem(character, fullType)
    local item = character:getInventory():AddItem(fullType)
    if item then sendAddItemToContainer(character:getInventory(), item) end
    return item
end

-- Wall used by a wall-mounted device placed ON `sq` (the device stays on the clicked
-- square, like vanilla wall objects, ISMoveableSpriteProps.lua:2651-2661):
--   "N" / "W": the square's own north / west wall (IsoGridSquare.getWall, :3962);
--   "S" / "E": the north wall of the south neighbour / west wall of the east neighbour.
function Install.wallFacing(sq)
    if not sq then return nil end
    if sq:getWall(true) then return "N" end
    if sq:getWall(false) then return "W" end
    local cell = getCell()
    local south = cell:getGridSquare(sq:getX(), sq:getY() + 1, sq:getZ())
    if south and south:getWall(true) then return "S" end
    local east = cell:getGridSquare(sq:getX() + 1, sq:getY(), sq:getZ())
    if east and east:getWall(false) then return "E" end
    return nil
end

local FACING_FLAG = { N = "attachedN", W = "attachedW", S = "attachedS", E = "attachedE" }

-- Pick the sprite variant whose attached flag matches the wall.
function Install.wallSprite(def, facing)
    local flag = IsoFlagType[FACING_FLAG[facing] or "attachedN"]
    for i = 1, #(def.wallSprites or {}) do
        local spr = getSprite(def.wallSprites[i])
        if spr and spr:getProperties():has(flag) then return def.wallSprites[i] end
    end
    return def.sprite
end

-- Can `character` install `model` on `sq`? Returns true or false, tooltip key, arg.
function Install.check(character, model, sq)
    local def = LiveWire.Defs.devices[model]
    if not def then return false, "Tooltip_LW_Invalid" end
    if not sq then return false, "Tooltip_LW_Invalid" end
    if not Install.hasLevel(character, def.level) then
        return false, "Tooltip_LW_NeedLevel", LiveWire.Config.requiredLevel(def.level)
    end
    if not Install.screwdriver(character) then return false, "Tooltip_LW_NeedScrewdriver" end
    if def.wallMounted then
        if not Install.wallFacing(sq) then return false, "Tooltip_LW_NeedWall" end
    else
        if not sq:isSolidFloor() or sq:HasStairs() or not sq:isFree(false) then
            return false, "Tooltip_LW_NeedFloor"
        end
        if def.needsOutside and not sq:isOutside() then
            return false, "Tooltip_LW_NeedOutdoor"
        end
    end
    if LiveWire.Marks.firstOnSquare(sq) then return false, "Tooltip_LW_Occupied" end
    return true
end

-- Distance between two squares in tiles (horizontal) and floors.
function Install.distance(x1, y1, z1, x2, y2, z2)
    local dx, dy = x1 - x2, y1 - y2
    return math.sqrt(dx * dx + dy * dy), math.abs(z1 - z2)
end

function Install.wiresFor(dist)
    local per = LiveWire.Config.get("WirePerTiles")
    if per <= 0 then return 0 end
    return math.max(1, math.ceil(dist / per))
end

-- Vanilla desktop computer (Mov_DesktopComputer, appliances_com_01_72:
-- media/scripts/generated/items/moveable.txt:1794-1800). The rotated variants
-- _73.._75 are an assumption; the tile CustomName is checked as well.
local COMPUTER_SPRITES = {
    appliances_com_01_72 = true, appliances_com_01_73 = true,
    appliances_com_01_74 = true, appliances_com_01_75 = true,
}

function Install.isComputer(obj)
    if not obj or instanceof(obj, "IsoWorldInventoryObject") then return false end
    local spr = obj:getSprite()
    if not spr then return false end
    if COMPUTER_SPRITES[spr:getName() or ""] then return true end
    local props = spr:getProperties()
    local name = props and props:get("CustomName")
    return name ~= nil and string.find(name, "Computer") ~= nil
end

-- What kind of link `obj` takes: "device" (ours), "backup" (vanilla generator),
-- "computer" (vanilla desktop computer), or nil.
function Install.linkKind(obj)
    if not obj then return nil end
    if LiveWire.Marks.isOurs(obj) then return "device" end
    if instanceof(obj, "IsoGenerator") then return "backup" end
    if Install.isComputer(obj) then return "computer" end
    return nil
end

-- Mark left by a link on a vanilla object ({ id, inverter? }), or nil.
function Install.vanillaMark(obj)
    local kind = Install.linkKind(obj)
    local key
    if kind == "backup" then key = LiveWire.Defs.BACKUP_KEY
    elseif kind == "computer" then key = LiveWire.Defs.COMPUTER_KEY
    else return nil end
    local m = obj:getModData()[key]
    if type(m) == "table" and type(m.id) == "string" then return m end
    return nil
end

-- Can `target` (one of our devices, a vanilla generator or a vanilla computer) be
-- linked to `inverterObj`?
function Install.checkLink(character, target, inverterObj)
    if not target or not inverterObj then return false, "Tooltip_LW_Invalid" end
    local im = LiveWire.Marks.get(inverterObj)
    if not im or not LiveWire.Defs.devices[im.model]
        or LiveWire.Defs.devices[im.model].role ~= "inverter" then
        return false, "Tooltip_LW_NoInverterInRange"
    end
    local ts, is = target:getSquare(), inverterObj:getSquare()
    if not ts or not is then return false, "Tooltip_LW_Invalid" end
    local dist, dz = Install.distance(ts:getX(), ts:getY(), ts:getZ(), is:getX(), is:getY(), is:getZ())
    if dist > LiveWire.Config.get("LinkRange") or dz > 1 then
        return false, "Tooltip_LW_NoInverterInRange"
    end
    local kind = Install.linkKind(target)
    if not kind then return false, "Tooltip_LW_Invalid" end
    local need = nil
    if kind == "backup" then need = LiveWire.Defs.BACKUP_LEVEL
    elseif kind == "computer" then need = LiveWire.Defs.COMPUTER_LEVEL end
    if need and not Install.hasLevel(character, need) then
        return false, "Tooltip_LW_NeedLevel", LiveWire.Config.requiredLevel(need)
    end
    local wires = Install.wiresFor(dist)
    if Install.countType(character, "Base.ElectricWire") < wires then
        return false, "Tooltip_LW_NeedWire", wires
    end
    return true, nil, wires
end

-- Nearest inverter object within link range of square `sq`, from the public
-- anchor table (known on clients and on the authority).
function Install.nearestInverter(sq)
    local best, bestD = nil, nil
    local range = LiveWire.Config.get("LinkRange")
    for id, a in pairs(LiveWire.Anchor.table()) do
        local d, dz = Install.distance(sq:getX(), sq:getY(), sq:getZ(), a.x, a.y, a.z)
        if d <= range and dz <= 1 and (not bestD or d < bestD) then
            local isq = getCell():getGridSquare(a.x, a.y, a.z)
            local obj = isq and LiveWire.Marks.findOnSquare(isq, id)
            if obj then best, bestD = obj, d end
        end
    end
    return best
end
