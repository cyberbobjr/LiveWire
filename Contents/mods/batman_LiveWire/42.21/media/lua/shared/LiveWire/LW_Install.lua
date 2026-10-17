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
    if kind == "device" then
        local tm = LiveWire.Marks.get(target)
        local tdef = LiveWire.Defs.devices[tm.model]
        if not tdef or tdef.role == "inverter" then return false, "Tooltip_LW_Invalid" end
        if tm.inv == im.id then return false, "Tooltip_LW_AlreadyLinked" end
    else
        local vm = Install.vanillaMark(target)
        if vm and vm.inverter == im.id then return false, "Tooltip_LW_AlreadyLinked" end
    end
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

-- Our devices of role `role` (or any role when nil) and, when `vanilla` is true,
-- the vanilla generators and desktop computers, within link range of `sq`
-- (loaded squares only). Returns a list of { obj, dist, kind }, nearest first.
-- Used by the menus; the authority re-checks the chosen pair (checkLink).
function Install.objectsInRange(sq, wantRole, vanilla)
    local out = {}
    if not sq then return out end
    local range = LiveWire.Config.get("LinkRange")
    local r = math.floor(range)
    local cell = getCell()
    local x0, y0, z0 = sq:getX(), sq:getY(), sq:getZ()
    for z = z0 - 1, z0 + 1 do
        for x = x0 - r, x0 + r do
            for y = y0 - r, y0 + r do
                local dx, dy = x - x0, y - y0
                local d2 = dx * dx + dy * dy
                if d2 <= range * range then
                    local s = cell:getGridSquare(x, y, z)
                    local objs = s and s:getObjects()
                    if objs then
                        for i = 0, objs:size() - 1 do
                            local o = objs:get(i)
                            local kind = Install.linkKind(o)
                            local keep = false
                            if kind == "device" then
                                local def = LiveWire.Defs.devices[LiveWire.Marks.get(o).model]
                                keep = def ~= nil and (wantRole == nil or def.role == wantRole)
                            elseif kind then
                                keep = vanilla == true
                            end
                            if keep then
                                out[#out + 1] = { obj = o, dist = math.sqrt(d2), kind = kind }
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

-- Inverters within link range of `sq`, nearest first.
function Install.invertersInRange(sq)
    return Install.objectsInRange(sq, "inverter", false)
end

-- Inverter object with device id `id` within link range of `sq`, or nil.
function Install.inverterById(sq, id)
    if not id then return nil end
    local list = Install.invertersInRange(sq)
    for i = 1, #list do
        local m = LiveWire.Marks.get(list[i].obj)
        if m and m.id == id then return list[i].obj end
    end
    return nil
end
