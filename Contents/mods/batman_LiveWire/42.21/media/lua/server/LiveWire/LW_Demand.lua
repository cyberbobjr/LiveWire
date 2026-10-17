-- Live Wire: demand measured by the mod (authority only).
-- Without a real IsoGenerator there is no getTotalPowerUsing: we reproduce the engine
-- rule of IsoGenerator.setSurroundingElectricity (IsoGenerator.java:251-290): objects
-- in range whose couldBePoweredByGenerator() is true, getGeneratorPowerConsumption()
-- > 0, and not already powered by the public grid.
if isClient() then return end

LiveWire = LiveWire or {}

local Demand = {}
LiveWire.Demand = Demand

-- inventories[inverterId] = { builtAt = hours, objects = { IsoObject... } }
Demand.inventories = {}
-- OnObjectAdded only fires on MP clients (AddItemToMapPacket.java:59,90), so new
-- appliances are found by this periodic rebuild.
Demand.REBUILD_HOURS = 0.5

function Demand.invalidate(inverterId)
    if inverterId then
        Demand.inventories[inverterId] = nil
    else
        Demand.inventories = {}
    end
end

local function allowExterior()
    local opts = getSandboxOptions()
    local opt = opts and opts:getOptionByName("AllowExteriorGenerator")
    if opt then return opt:getValue() end
    return true
end

-- Full scan of the disc (cost: about pi * R^2 * levels squares).
local function build(inv)
    local cell = getCell()
    local R = LiveWire.Config.tileRange()
    local V = LiveWire.Config.verticalRange()
    local R2 = R * R
    local list = {}
    local zmin = math.max(-32, inv.z - V)
    local zmax = math.min(31, inv.z + V)
    for z = zmin, zmax do
        for dy = -R, R do
            for dx = -R, R do
                if dx * dx + dy * dy <= R2 then
                    local sq = cell:getGridSquare(inv.x + dx, inv.y + dy, z)
                    if sq then
                        local objs = sq:getObjects()
                        for i = 0, objs:size() - 1 do
                            local o = objs:get(i)
                            if o:couldBePoweredByGenerator() then list[#list + 1] = o end
                        end
                    end
                end
            end
        end
    end
    return list
end

-- Demand in W for a loaded inverter device. Returns nil when the inverter square
-- is not loaded (the caller then keeps the last measured value).
function Demand.measure(inv)
    local cell = getCell()
    if not cell:getGridSquare(inv.x, inv.y, inv.z) then return nil end
    local now = getGameTime():getWorldAgeHours()
    local entry = Demand.inventories[inv.id]
    if not entry or now - entry.builtAt >= Demand.REBUILD_HOURS then
        entry = { builtAt = now, objects = build(inv) }
        Demand.inventories[inv.id] = entry
    end
    -- Same filters as IsoGenerator.setSurroundingElectricity (IsoGenerator.java:274-286):
    -- not already on the public grid, exterior squares only if AllowExteriorGenerator.
    -- While our anchor is on, only count squares the engine really powers
    -- (the engine generator range is a static value, notes-moteur.md note 27).
    local anchor = LiveWire.Registry.anchors and LiveWire.Registry.anchors[inv.id]
    local anchorOn = anchor and anchor.on
    local exteriorOk = allowExterior()
    local total = 0
    for i = 1, #entry.objects do
        local o = entry.objects[i]
        local sq = o:getSquare()
        if sq and o:getObjectIndex() ~= -1 and not ItemContainer.isObjectPowered(o, false)
            and (exteriorOk or not sq:getProperties():has(IsoFlagType.exterior))
            and (not anchorOn or sq:haveElectricity()) then
            local p = o:getGeneratorPowerConsumption()
            if p and p > 0 then total = total + p end
        end
    end
    return total * 1000 * (LiveWire.Config.get("PowerScale") or 1)
end

-- Rebuild the inventory of every inverter in range when an object appears or vanishes.
local function onObjectChanged(obj)
    if not obj or not obj.getSquare then return end
    local sq = obj:getSquare()
    if not sq or not LiveWire.Registry or not LiveWire.Registry.ready then return end
    local R = LiveWire.Config.tileRange()
    for id, entry in pairs(Demand.inventories) do
        local inv = LiveWire.Registry.device(id)
        if inv then
            local dx, dy = sq:getX() - inv.x, sq:getY() - inv.y
            if dx * dx + dy * dy <= R * R then Demand.inventories[id] = nil end
        end
    end
end

Events.OnObjectAboutToBeRemoved.Add(onObjectChanged)
