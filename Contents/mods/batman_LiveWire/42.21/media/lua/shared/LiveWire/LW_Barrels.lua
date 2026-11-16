-- Live Wire: water barrels of the water pump (docs/annexes/conception/choix-et-extensions.md,
-- section 2). Any world object with a FluidContainer of at least MIN_BARREL_CAPACITY
-- litres: vanilla rain collectors and modded barrels alike. Our own tiles, relays and
-- plumbed fixtures are never barrels. Barrels never join the inverter lists
-- (LiveWire.Install.linkKind is not changed). LiveWire.Install keeps every name below
-- for its callers.
require "LiveWire/LW_Inventory"

LiveWire = LiveWire or {}

local Barrels = {}
LiveWire.Barrels = Barrels

function Barrels.isRelay(obj)
    if not obj or not obj.getModData then return false end
    return obj:getModData()[LiveWire.Defs.RELAY_KEY] ~= nil
end

function Barrels.isPump(obj)
    if not LiveWire.Marks.isOurs(obj) then return false end
    local m = LiveWire.Marks.get(obj)
    local def = m and LiveWire.Defs.devices[m.model]
    return def ~= nil and def.role == "pump"
end

function Barrels.isBarrelObject(obj)
    if not obj or instanceof(obj, "IsoWorldInventoryObject") then return false end
    if LiveWire.Marks.isOurs(obj) or Barrels.isRelay(obj) then return false end
    local spr = obj:getSprite()
    local props = spr and spr:getProperties()
    if props and props:has(IsoFlagType.waterPiped) then return false end
    if obj:getUsesExternalWaterSource() then return false end
    local fc = obj:getFluidContainer()
    return fc ~= nil and fc:getCapacity() >= LiveWire.Defs.MIN_BARREL_CAPACITY
end

-- "ok" when the barrel holds only water (Water and/or TaintedWater) or nothing,
-- "notwater" otherwise, nil when obj is not a barrel.
function Barrels.barrelState(obj)
    if not Barrels.isBarrelObject(obj) then return nil end
    local fc = obj:getFluidContainer()
    local total = fc:getAmount()
    local water = fc:getSpecificFluidAmount(Fluid.Water) + fc:getSpecificFluidAmount(Fluid.TaintedWater)
    if total <= 0.001 or total - water <= 0.001 then return "ok" end
    return "notwater"
end

-- Judges the pump mark left on `obj` and writes nothing. Returns nil when there is no
-- mark (or no square); else mark, valid, fillPosition, x, y, z. A mark is valid when
-- its stored position (if any) is the barrel square and, on the authority once the
-- registry is ready, when its pump still lists that square. `fillPosition` is true for
-- a valid legacy mark (no stored position) that the authority should complete.
local function judge(obj)
    if not obj or not obj.getModData then return nil end
    local m = obj:getModData()[LiveWire.Defs.BARREL_KEY]
    if type(m) ~= "table" or m.pump == nil then return nil end
    local sq = obj:getSquare()
    if not sq then return nil end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local valid = m.x == nil or (m.x == x and m.y == y and m.z == z)
    local fillPosition = false
    local R = LiveWire.Registry
    if not isClient() and R and R.ready then
        local dev = R.device(m.pump)
        valid = valid and dev ~= nil and dev.role == "pump" and dev.barrels ~= nil
            and dev.barrels[LiveWire.posKey(x, y, z)] ~= nil
        fillPosition = valid and m.x == nil
    end
    return m, valid, fillPosition, x, y, z
end

-- Pure read, safe on both sides: the pump mark of a barrel, or nil when it is absent
-- or no longer valid (barrel moved, pump or entry gone). Writes nothing.
function Barrels.mark(obj)
    local m, valid = judge(obj)
    if valid then return m end
    return nil
end

-- Authority only (server and single player; a pure client just reads): same answer as
-- Barrels.mark, and also completes a valid legacy mark with its position or clears an
-- invalid one, then transmits the ModData on a server.
function Barrels.repairMark(obj)
    if isClient() then return Barrels.mark(obj) end
    local m, valid, fillPosition, x, y, z = judge(obj)
    if m == nil then return nil end
    if valid then
        if fillPosition then
            m.x, m.y, m.z = x, y, z
            if isServer() then obj:transmitModData() end
        end
        return m
    end
    obj:getModData()[LiveWire.Defs.BARREL_KEY] = nil
    if isServer() then obj:transmitModData() end
    return nil
end

-- Chebyshev distance on the same floor: a square is "near" when it is the pump
-- square or one of its 8 neighbours (PUMP_BARREL_RANGE), diagonals included.
function Barrels.nearSquares(sq1, sq2)
    local dx, dy = math.abs(sq1:getX() - sq2:getX()), math.abs(sq1:getY() - sq2:getY())
    local near = math.max(dx, dy) <= LiveWire.Defs.PUMP_BARREL_RANGE and sq1:getZ() == sq2:getZ()
    return near, math.sqrt(dx * dx + dy * dy)
end

-- Water barrels next to the pump square, same floor, nearest first:
-- { obj, dist, state }. Loaded squares only.
function Barrels.barrelsInRange(sq)
    local out = {}
    if not sq then return out end
    local range = LiveWire.Defs.PUMP_BARREL_RANGE
    local cell = getCell()
    local x0, y0, z0 = sq:getX(), sq:getY(), sq:getZ()
    for x = x0 - range, x0 + range do
        for y = y0 - range, y0 + range do
            local s = cell:getGridSquare(x, y, z0)
            if s then
                local _, dist = Barrels.nearSquares(sq, s)
                local objs = s:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    local state = Barrels.barrelState(o)
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
function Barrels.pumpsInRange(sq)
    local out = {}
    if not sq then return out end
    local range = LiveWire.Defs.PUMP_BARREL_RANGE
    local cell = getCell()
    local x0, y0, z0 = sq:getX(), sq:getY(), sq:getZ()
    for x = x0 - range, x0 + range do
        for y = y0 - range, y0 + range do
            local s = cell:getGridSquare(x, y, z0)
            if s then
                local near, dist = Barrels.nearSquares(sq, s)
                local objs = s:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    if near and Barrels.isPump(o) then out[#out + 1] = { obj = o, dist = dist } end
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

-- True when `src` is a pump relay. A client may not have received the relay ModData
-- yet: the relay tile is enough (vanilla barrels have other sprites).
function Barrels.isPumpRelay(src)
    if Barrels.isRelay(src) then return true end
    local spr = src and src.getSprite and src:getSprite()
    return spr ~= nil and spr:getName() == LiveWire.Defs.RELAY_SPRITE
end

-- Plumbed fixture `obj` (sink, bath...) fed by a water pump: returns true and the pump
-- object, or true and nil when the pump is not on a loaded square. Returns false when
-- `obj` is not plumbed, or draws its water from another source (vanilla barrel above).
-- The source is the one vanilla uses (IsoObject.FindExternalWaterSource); the pump is
-- searched in the area it serves (PumpRange, Config.verticalRange, LW_PumpRelays.lua).
function Barrels.supplyingPump(obj)
    if not obj or not obj.getUsesExternalWaterSource or not obj:getUsesExternalWaterSource() then
        return false
    end
    local sq = obj:getSquare()
    local src = sq and IsoObject.FindExternalWaterSource(sq)
    if not src or not Barrels.isPumpRelay(src) then return false end
    local m = Barrels.isRelay(src) and src:getModData()[LiveWire.Defs.RELAY_KEY] or nil
    local id = type(m) == "table" and m.pump or nil
    local range = LiveWire.Config.get("PumpRange")
    local r, floors = math.floor(range), LiveWire.Config.verticalRange()
    local cell = getCell()
    local x0, y0, z0 = sq:getX(), sq:getY(), sq:getZ()
    local best, bestD2
    for z = math.max(-32, z0 - floors), math.min(31, z0 + floors) do
        for x = x0 - r, x0 + r do
            for y = y0 - r, y0 + r do
                local d2 = (x - x0) * (x - x0) + (y - y0) * (y - y0)
                local s = d2 <= range * range and cell:getGridSquare(x, y, z)
                local objs = s and s:getObjects()
                if objs then
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if Barrels.isPump(o) then
                            -- Relay id unknown on this client: the nearest pump.
                            if id ~= nil and LiveWire.Marks.get(o).id == id then return true, o end
                            if id == nil and (not bestD2 or d2 < bestD2) then best, bestD2 = o, d2 end
                        end
                    end
                end
            end
        end
    end
    return true, best
end

-- Can `character` link `barrel` to `pumpObj`? Returns true, or false, key, arg.
function Barrels.checkBarrelLink(character, barrel, pumpObj)
    if not Barrels.isPump(pumpObj) then return false, "Tooltip_LW_Invalid" end
    if not Barrels.isBarrelObject(barrel) then return false, "Tooltip_LW_Invalid" end
    if Barrels.barrelState(barrel) ~= "ok" then return false, "Tooltip_LW_BarrelNotWater" end
    local ps, bs = pumpObj:getSquare(), barrel:getSquare()
    if not ps or not bs then return false, "Tooltip_LW_Invalid" end
    if not Barrels.nearSquares(ps, bs) then
        return false, "Tooltip_LW_BarrelTooFar"
    end
    local pm = LiveWire.Marks.get(pumpObj)
    local bm = Barrels.mark(barrel)
    if bm and bm.pump == pm.id then return false, "Tooltip_LW_AlreadyLinked" end
    if bm then return false, "Tooltip_LW_BarrelOtherPump" end
    -- Plumbing only (pipes): no Electrical level; linking the pump to the inverter needs it.
    if (pm.nb or 0) >= LiveWire.Defs.PUMP_MAX_BARRELS then
        return false, "Tooltip_LW_PumpFull", tostring(LiveWire.Defs.PUMP_MAX_BARRELS)
    end
    if LiveWire.Inventory.countType(character, LiveWire.Defs.PUMP_PIPE) < 1 then
        return false, "Tooltip_LW_NeedPipe"
    end
    return true
end
