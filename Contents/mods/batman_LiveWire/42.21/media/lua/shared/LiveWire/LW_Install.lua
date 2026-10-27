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

-- Primary is the working/right hand in the native rig (Prop1), secondary the
-- left (Prop2). If the tool is in a bag, timed actions show it in primary.
function Install.screwdriverHand(character)
    local primary = character:getPrimaryHandItem()
    if primary and primary:hasTag(ItemTag.SCREWDRIVER) and not primary:isBroken() then
        return BodyPartType.Hand_R
    end
    local secondary = character:getSecondaryHandItem()
    if secondary and secondary:hasTag(ItemTag.SCREWDRIVER) and not secondary:isBroken() then
        return BodyPartType.Hand_L
    end
    return BodyPartType.Hand_R
end

function Install.showScrewdriver(action)
    local character = action.character
    local hand = Install.screwdriverHand(character)
    local held = hand == BodyPartType.Hand_L and character:getSecondaryHandItem()
        or character:getPrimaryHandItem()
    local tool = held and held:hasTag(ItemTag.SCREWDRIVER) and not held:isBroken() and held
        or Install.screwdriver(character)
    -- Use the actual item so modded screwdrivers keep their own model.
    if hand == BodyPartType.Hand_L then action:setOverrideHandModels(nil, tool)
    else action:setOverrideHandModels(tool, nil) end
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

-- linked to inverterObj? Returns true, nil, wires; or false, key, arg1, arg2.
-- `target` is one of our devices, a vanilla generator or a vanilla computer.
function Install.checkLink(character, target, inverterObj)
    if not target or not inverterObj then return false, "Tooltip_LW_Invalid" end
    local im = LiveWire.Marks.get(inverterObj)
    if not im or not LiveWire.Defs.devices[im.model]
        or LiveWire.Defs.devices[im.model].role ~= "inverter" then
        return false, "Tooltip_LW_NoInverterInRange"
    end
    if im.cpl then return false, "Tooltip_LW_CoupledInverter" end
    local ts, is = target:getSquare(), inverterObj:getSquare()
    if not ts or not is then return false, "Tooltip_LW_Invalid" end
    local dist, dz = Install.distance(ts:getX(), ts:getY(), ts:getZ(), is:getX(), is:getY(), is:getZ())
    local floors = LiveWire.Config.get("LinkVerticalRange")
    if dz > floors then
        return false, "Tooltip_LW_TooManyFloors", tostring(dz), tostring(floors)
    end
    local range = LiveWire.Config.get("LinkRange")
    if dist > range then
        return false, "Tooltip_LW_TooFarForCable", tostring(math.ceil(dist - 1e-9)), tostring(range)
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

-- Can `character` couple `slaveObj` (clicked inverter) to `masterObj`?
-- Returns true, nil, wires; or false, key, arg1, arg2. Client tooltips and the
-- authority (LWCoupleAction:complete) use the same rules. The registry-only conditions
-- (slave has equipment or slaves, master full) are checked by the authority.
function Install.checkCouple(character, slaveObj, masterObj)
    local sm, mm = LiveWire.Marks.get(slaveObj), LiveWire.Marks.get(masterObj)
    local sdef = sm and LiveWire.Defs.devices[sm.model]
    local mdef = mm and LiveWire.Defs.devices[mm.model]
    if not sdef or not mdef or sdef.role ~= "inverter" or mdef.role ~= "inverter"
        or sm.id == mm.id then
        return false, "Tooltip_LW_Invalid"
    end
    if sm.cpl then return false, "Tooltip_LW_AlreadyCoupled" end
    if mm.cpl then return false, "Tooltip_LW_MasterIsSlave" end
    local ss, ms = slaveObj:getSquare(), masterObj:getSquare()
    if not ss or not ms then return false, "Tooltip_LW_Invalid" end
    local dist, dz = Install.distance(ss:getX(), ss:getY(), ss:getZ(), ms:getX(), ms:getY(), ms:getZ())
    local floors = LiveWire.Config.get("LinkVerticalRange")
    if dz > floors then
        return false, "Tooltip_LW_TooManyFloors", tostring(dz), tostring(floors)
    end
    local range = LiveWire.Config.get("LinkRange")
    if dist > range then
        return false, "Tooltip_LW_TooFarForCable", tostring(math.ceil(dist - 1e-9)), tostring(range)
    end
    local coupling = LiveWire.Defs.COUPLING_LEVEL
    if not Install.hasLevel(character, coupling) then
        return false, "Tooltip_LW_NeedLevel", LiveWire.Config.requiredLevel(coupling)
    end
    if Install.countType(character, LiveWire.Defs.COUPLING_KIT) < 1 then
        return false, "Tooltip_LW_NeedCouplingKit"
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
    local floors = LiveWire.Config.get("LinkVerticalRange")
    for z = math.max(-32, z0 - floors), math.min(31, z0 + floors) do
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

-- Water barrels for the water pump (docs/annexes/conception/choix-et-extensions.md, section 2). Any world object
-- with a FluidContainer of at least MIN_BARREL_CAPACITY litres: vanilla rain
-- collectors and modded barrels alike. Our own tiles, relays and plumbed fixtures
-- are never barrels. Install.linkKind is NOT changed: barrels never join the
-- inverter lists.
function Install.isRelay(obj)
    if not obj or not obj.getModData then return false end
    return obj:getModData()[LiveWire.Defs.RELAY_KEY] ~= nil
end

function Install.isPump(obj)
    if not LiveWire.Marks.isOurs(obj) then return false end
    local m = LiveWire.Marks.get(obj)
    local def = m and LiveWire.Defs.devices[m.model]
    return def ~= nil and def.role == "pump"
end

function Install.isBarrelObject(obj)
    if not obj or instanceof(obj, "IsoWorldInventoryObject") then return false end
    if LiveWire.Marks.isOurs(obj) or Install.isRelay(obj) then return false end
    local spr = obj:getSprite()
    local props = spr and spr:getProperties()
    if props and props:has(IsoFlagType.waterPiped) then return false end
    if obj:getUsesExternalWaterSource() then return false end
    local fc = obj:getFluidContainer()
    return fc ~= nil and fc:getCapacity() >= LiveWire.Defs.MIN_BARREL_CAPACITY
end

-- "ok" when the barrel holds only water (Water and/or TaintedWater) or nothing,
-- "notwater" otherwise, nil when obj is not a barrel.
function Install.barrelState(obj)
    if not Install.isBarrelObject(obj) then return nil end
    local fc = obj:getFluidContainer()
    local total = fc:getAmount()
    local water = fc:getSpecificFluidAmount(Fluid.Water) + fc:getSpecificFluidAmount(Fluid.TaintedWater)
    if total <= 0.001 or total - water <= 0.001 then return "ok" end
    return "notwater"
end

-- Validate moved barrels on both sides; only the authority clears/migrates marks.
function Install.barrelMark(obj)
    if not obj or not obj.getModData then return nil end
    local m = obj:getModData()[LiveWire.Defs.BARREL_KEY]
    if type(m) == "table" and m.pump ~= nil then
        local sq = obj:getSquare()
        if not sq then return nil end
        local x, y, z = sq:getX(), sq:getY(), sq:getZ()
        local valid = m.x == nil or (m.x == x and m.y == y and m.z == z)
        local R = LiveWire.Registry
        if not isClient() and R and R.ready then
            local dev = R.device(m.pump)
            valid = valid and dev ~= nil and dev.role == "pump" and dev.barrels ~= nil
                and dev.barrels[LiveWire.posKey(x, y, z)] ~= nil
            if valid and m.x == nil then
                m.x, m.y, m.z = x, y, z
                if isServer() then obj:transmitModData() end
            end
        end
        if valid then return m end
        if not isClient() then
            obj:getModData()[LiveWire.Defs.BARREL_KEY] = nil
            if isServer() then obj:transmitModData() end
        end
    end
    return nil
end

-- Chebyshev distance on the same floor: a square is "near" when it is the pump
-- square or one of its 8 neighbours (PUMP_BARREL_RANGE), diagonals included.
function Install.nearSquares(sq1, sq2)
    local dx, dy = math.abs(sq1:getX() - sq2:getX()), math.abs(sq1:getY() - sq2:getY())
    local near = math.max(dx, dy) <= LiveWire.Defs.PUMP_BARREL_RANGE and sq1:getZ() == sq2:getZ()
    return near, math.sqrt(dx * dx + dy * dy)
end

-- Water barrels next to the pump square, same floor, nearest first:
-- { obj, dist, state }. Loaded squares only.
function Install.barrelsInRange(sq)
    local out = {}
    if not sq then return out end
    local range = LiveWire.Defs.PUMP_BARREL_RANGE
    local cell = getCell()
    local x0, y0, z0 = sq:getX(), sq:getY(), sq:getZ()
    for x = x0 - range, x0 + range do
        for y = y0 - range, y0 + range do
            local s = cell:getGridSquare(x, y, z0)
            if s then
                local _, dist = Install.nearSquares(sq, s)
                local objs = s:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    local state = Install.barrelState(o)
                    if state then out[#out + 1] = { obj = o, dist = dist, state = state } end
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

-- Pumps next to a barrel square (PUMP_BARREL_RANGE), same floor, nearest first:
-- { obj, dist }. Loaded squares only.
function Install.pumpsInRange(sq)
    local out = {}
    if not sq then return out end
    local range = LiveWire.Defs.PUMP_BARREL_RANGE
    local cell = getCell()
    local x0, y0, z0 = sq:getX(), sq:getY(), sq:getZ()
    for x = x0 - range, x0 + range do
        for y = y0 - range, y0 + range do
            local s = cell:getGridSquare(x, y, z0)
            if s then
                local near, dist = Install.nearSquares(sq, s)
                local objs = s:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    if near and Install.isPump(o) then out[#out + 1] = { obj = o, dist = dist } end
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

-- Can `character` link `barrel` to `pumpObj`? Returns true, or false, key, arg.
function Install.checkBarrelLink(character, barrel, pumpObj)
    if not Install.isPump(pumpObj) then return false, "Tooltip_LW_Invalid" end
    if not Install.isBarrelObject(barrel) then return false, "Tooltip_LW_Invalid" end
    if Install.barrelState(barrel) ~= "ok" then return false, "Tooltip_LW_BarrelNotWater" end
    local ps, bs = pumpObj:getSquare(), barrel:getSquare()
    if not ps or not bs then return false, "Tooltip_LW_Invalid" end
    if not Install.nearSquares(ps, bs) then
        return false, "Tooltip_LW_BarrelTooFar"
    end
    local pm = LiveWire.Marks.get(pumpObj)
    local bm = Install.barrelMark(barrel)
    if bm and bm.pump == pm.id then return false, "Tooltip_LW_AlreadyLinked" end
    if bm then return false, "Tooltip_LW_BarrelOtherPump" end
    local pumpDef = LiveWire.Defs.devices.WaterPump
    if not Install.hasLevel(character, pumpDef.level) then
        return false, "Tooltip_LW_NeedLevel", LiveWire.Config.requiredLevel(pumpDef.level)
    end
    if (pm.nb or 0) >= LiveWire.Defs.PUMP_MAX_BARRELS then
        return false, "Tooltip_LW_PumpFull", tostring(LiveWire.Defs.PUMP_MAX_BARRELS)
    end
    if Install.countType(character, LiveWire.Defs.PUMP_PIPE) < 1 then
        return false, "Tooltip_LW_NeedPipe"
    end
    return true
end
