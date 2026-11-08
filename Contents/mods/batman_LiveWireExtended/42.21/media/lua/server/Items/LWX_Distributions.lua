if isClient() then return end

-- LiveWire Extended: the power terminal in electrician and hardware loot, scaled by
-- Live Wire's EquipmentLootMultiplier (absolute weights: merging twice never compounds).
require "Items/ProceduralDistributions"
require "LiveWire/LW_Config"

local ITEM = "Base.Mov_LWX_Terminal"
local LISTS = { ElectricianTools = 0.3, ToolStoreMisc = 0.2, CrateElectronics = 0.2, WireFactoryElectric = 0.3 }
local VEHICLE = { ElectricianTruckBed = 0.3 }

local function add(lists, multiplier, find)
    local changed = false
    for name, weight in pairs(lists) do
        local list = find(name)
        if list and list.items then
            local items, index = list.items, nil
            for i = 1, #items, 2 do
                if items[i] == ITEM then index = i; break end
            end
            local target = weight * multiplier
            if index then
                if items[index + 1] ~= target then items[index + 1] = target; changed = true end
            else
                table.insert(items, ITEM); table.insert(items, target); changed = true
            end
        end
    end
    return changed
end

local function procedural(name) return ProceduralDistributions.list[name] end
local function vehicle(name) return VehicleDistributions and VehicleDistributions[name] end

local function apply(multiplier)
    local changed = add(LISTS, multiplier, procedural)
    if add(VEHICLE, multiplier, vehicle) then changed = true end
    return changed
end

Events.OnPreDistributionMerge.Add(function() apply(1) end)
Events.OnInitGlobalModData.Add(function()
    local multiplier = tonumber(LiveWire.Config.get("EquipmentLootMultiplier")) or 5
    if multiplier ~= multiplier then multiplier = 5 end
    multiplier = math.max(1, math.min(20, multiplier))
    if apply(multiplier) then
        ItemPickerJava.Parse()
        print("[LiveWireExtended] Power terminal loot multiplier applied: x" .. tostring(multiplier))
    end
end)
