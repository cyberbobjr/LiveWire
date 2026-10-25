if isClient() then return end

-- Live Wire: loot. Mod-only solar cells and ready-made equipment in garages, workshops,
-- electricians and hardware stores; the management software disk only when the Computer Mod is active (it
-- is useless without it).
require "Items/ProceduralDistributions"
require "LiveWire/LW_Config"

-- Management software disk (only with the Computer Mod).
local DISK_LISTS = {
    ElectronicStoreComputers = 2, CrateComputer = 2, BookstoreComputer = 1,
    UniversityDesk_Computer = 1, UniversityDesk_Electrical = 2, OfficeDesk = 0.3,
}

-- Solar cells: garages, workshops, electricians.
local CELL_LISTS = {
    GarageTools = 2, CrateTools = 1, GarageMetalwork = 1, MechanicShelfElectric = 2,
    ElectricianTools = 3, MetalShopTools = 1, WireFactoryElectric = 2, ToolStoreMisc = 2,
    CrateElectronics = 2, ElectronicStoreMisc = 2, ToolStoreMetalwork = 1, CrateMetalwork = 1,
}

-- Ready-made solar panels (placeable): garages, workshops, hardware stores.
local PANEL_LISTS = {
    GarageTools = 0.3, CrateTools = 0.3, GarageMetalwork = 0.2, ToolStoreMisc = 0.5, ToolStoreTools = 0.3,
    CrateElectronics = 0.5, ElectronicStoreMisc = 0.5, CrateMetalwork = 0.3, ToolStoreMetalwork = 0.3,
}

-- Ready-made Live Wire equipment: electricians, electrical shelves, hardware stores, garages.
local EQUIPMENT = {
    ["LiveWire.VoltageTester"] = {
        ElectricianTools = 3, ToolStoreTools = 1, GarageTools = 1, CrateTools = 1, WireFactoryElectric = 1,
        ElectronicStoreMisc = 1, CrateElectronics = 1, MechanicShelfElectric = 1, MechanicShelfTools = 1,
    },
    ["LiveWire.DeepCycleBattery"] = {
        MechanicShelfElectric = 1, CarSupplyBatteries = 2, GarageMechanics = 0.3,
        CrateMechanics = 0.7, CrateElectronics = 0.5, ElectronicStoreMisc = 0.5, CampingStoreGear = 0.3,
    },
    ["Base.Mov_LiveWire_Inverter"] = {
        ElectricianTools = 0.5, WireFactoryElectric = 0.5, ToolStoreMisc = 0.2, GarageTools = 0.1,
        CrateElectronics = 0.5, ElectronicStoreMisc = 0.5, ElectronicStoreAppliances = 0.3,
        MechanicShelfElectric = 0.3, CrateTools = 0.2,
    },
    ["Base.Mov_LiveWire_Breaker"] = {
        ElectricianTools = 1, WireFactoryElectric = 1, ToolStoreMisc = 0.5, GarageTools = 0.3, CrateTools = 0.3,
        CrateElectronics = 0.7, ElectronicStoreMisc = 0.5, ToolStoreTools = 0.5, CrateMetalwork = 0.3,
    },
    ["Base.Mov_LiveWire_PowerBank"] = {
        ElectricianTools = 0.5, MechanicShelfElectric = 0.5, ToolStoreMisc = 0.3, GarageTools = 0.2,
        CrateElectronics = 0.5, ElectronicStoreMisc = 0.4, CrateMechanics = 0.3,
        GarageMechanics = 0.2, CrateTools = 0.2,
    },
    ["Base.Mov_LiveWire_BatteryAlarm"] = {
        ElectricianTools = 1, WireFactoryElectric = 1, ToolStoreMisc = 0.5,
        CrateElectronics = 0.7, ElectronicStoreMisc = 0.5, CrateTools = 0.3, GarageTools = 0.3,
    },
    ["Base.Mov_LiveWire_WindTurbine"] = {
        ToolStoreMisc = 0.3, WireFactoryElectric = 0.5,
        CrateElectronics = 0.3, CrateMetalwork = 0.3, ToolStoreMetalwork = 0.5,
        CrateTools = 0.3, WireFactoryTools = 0.5, CrateFarming = 0.3,
        ToolStoreFarming = 0.3, MechanicShelfTools = 0.3,
    },
    ["Base.Mov_LiveWire_WaterWheel"] = {
        CrateCarpentry = 0.5, ToolStoreCarpentry = 0.5, CrateFarming = 0.5,
        ToolStoreFarming = 0.3, CrateTools = 0.3, CrateMechanics = 0.3, CrateMetalwork = 0.3,
    },
    ["LiveWire.WindTurbineBlades"] = {
        CrateMetalwork = 1, ToolStoreMetalwork = 1, CrateTools = 0.7,
        CrateFarming = 0.7, ToolStoreFarming = 0.7, WireFactoryTools = 0.7,
    },
    ["LiveWire.WindTurbineMast"] = {
        CrateMetalwork = 1, ToolStoreMetalwork = 1, CrateTools = 0.7,
        CrateMechanics = 0.7, CrateFarming = 0.7, ToolStoreFarming = 0.7,
    },
}

-- Absolute weights, not repeated multiplication: merging or initializing twice
-- must neither duplicate entries nor compound the configured multiplier.
local function add(lists, fullType, multiplier)
    local changed = false
    for name, weight in pairs(lists) do
        local list = ProceduralDistributions.list[name]
        if list and list.items then
            local items, index = list.items, nil
            for i = 1, #items, 2 do
                if items[i] == fullType then index = i; break end
            end
            local target = weight * (multiplier or 1)
            if index then
                if items[index + 1] ~= target then
                    items[index + 1] = target
                    changed = true
                end
            else
                table.insert(items, fullType)
                table.insert(items, target)
                changed = true
            end
        end
    end
    return changed
end

local function equipment(multiplier)
    local changed = add(CELL_LISTS, "LiveWire.SolarCell", multiplier)
    if add(PANEL_LISTS, "Base.Mov_LiveWire_SolarPanel", multiplier) then changed = true end
    for fullType, lists in pairs(EQUIPMENT) do
        if add(lists, fullType, multiplier) then changed = true end
    end
    return changed
end

local function onPreDistributionMerge()
    equipment(1)
    if LiveWire and LiveWire.Compat and LiveWire.Compat.computerMod() then
        add(DISK_LISTS, "LiveWire.MonitorDisk")
    end
end

local function onInitGlobalModData()
    -- In SP the save's sandbox options are loaded AFTER distribution merging.
    -- At this event both SP and dedicated servers have the correct world values.
    local multiplier = tonumber(LiveWire.Config.get("EquipmentLootMultiplier")) or 5
    if multiplier ~= multiplier then multiplier = 5 end
    multiplier = math.max(1, math.min(20, multiplier))
    local changed = equipment(multiplier)
    if changed then
        -- Parse rereads the tables without resetting vanilla sandbox loot factors.
        -- Startup only: no tick hook, container refill or world traversal.
        ItemPickerJava.Parse()
        print("[LiveWire] Equipment and parts loot multiplier applied: x" .. tostring(multiplier))
    end
end

Events.OnPreDistributionMerge.Add(onPreDistributionMerge)
Events.OnInitGlobalModData.Add(onInitGlobalModData)
