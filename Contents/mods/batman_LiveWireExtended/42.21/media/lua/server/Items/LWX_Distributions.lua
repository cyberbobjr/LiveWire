if isClient() then return end

-- LiveWire Extended: its equipment in electrician, hardware and house loot (D-43), scaled
-- by Live Wire's EquipmentLootMultiplier (absolute weights: merging twice never compounds).
-- Breakers are the common find (also in garages and tool crates of houses); boards and
-- twilight switches only in professional loot and rarer.
require "Items/ProceduralDistributions"
require "LiveWire/LW_Config"

local PRO = { ElectricianTools = 1, ToolStoreMisc = 0.7, CrateElectronics = 0.7, WireFactoryElectric = 1 }
local HOUSE = { GarageTools = 0.4, CrateTools = 0.3, GarageMetalwork = 0.2 }
local ENTRIES = {
    { item = "Base.Mov_LWX_Terminal", lists = PRO, weight = 0.3, vehicle = 0.3 },
    { item = "Base.LWXBreaker15", lists = PRO, house = HOUSE, weight = 0.8, vehicle = 0.8 },
    { item = "Base.LWXBreaker20", lists = PRO, house = HOUSE, weight = 0.8, vehicle = 0.8 },
    { item = "Base.LWXBreaker30", lists = PRO, house = HOUSE, weight = 0.5, vehicle = 0.5 },
    { item = "Base.Mov_LWX_Panel8", lists = PRO, weight = 0.2, vehicle = 0.1 },
    { item = "Base.Mov_LWX_Panel16", lists = PRO, weight = 0.12, vehicle = 0.05 },
    { item = "Base.Mov_LWX_Panel24", lists = PRO, weight = 0.06 },
    { item = "Base.LWXTwilightSwitch", lists = PRO, weight = 0.15, vehicle = 0.1 },
}

-- Put `item` at `weight` in the loot list (replaces the weight of a previous merge).
local function put(list, item, weight)
    if not list or not list.items then return false end
    local items = list.items
    for i = 1, #items, 2 do
        if items[i] == item then
            if items[i + 1] == weight then return false end
            items[i + 1] = weight
            return true
        end
    end
    table.insert(items, item); table.insert(items, weight)
    return true
end

local function procedural(name) return ProceduralDistributions.list[name] end
local function vehicle(name) return VehicleDistributions and VehicleDistributions[name] end

local function apply(multiplier)
    local changed = false
    for _, e in ipairs(ENTRIES) do
        for name, factor in pairs(e.lists or {}) do
            if put(procedural(name), e.item, e.weight * factor * multiplier) then changed = true end
        end
        for name, factor in pairs(e.house or {}) do
            if put(procedural(name), e.item, e.weight * factor * multiplier) then changed = true end
        end
        if e.vehicle and put(vehicle("ElectricianTruckBed"), e.item, e.vehicle * multiplier) then changed = true end
    end
    return changed
end

Events.OnPreDistributionMerge.Add(function() apply(1) end)
Events.OnInitGlobalModData.Add(function()
    local multiplier = tonumber(LiveWire.Config.get("EquipmentLootMultiplier")) or 5
    if multiplier ~= multiplier then multiplier = 5 end
    multiplier = math.max(1, math.min(20, multiplier))
    if apply(multiplier) then
        ItemPickerJava.Parse()
        print("[LiveWireExtended] Equipment loot multiplier applied: x" .. tostring(multiplier))
    end
end)
