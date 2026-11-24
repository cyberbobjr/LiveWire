if isClient() then return end

-- Live Wire: loot. Mod-only solar cells and ready-made equipment in garages, workshops,
-- electricians, hardware stores and electrician or metalworker vehicles; the management software disk only
-- when the Computer Mod is active (it is useless without it).
require "Items/ProceduralDistributions"
-- VehicleDistributions is read from the events only: requiring it here would run it before the vehicle
-- junk tables (server/Vehicles/VehicleDistribution_*Junk.lua) and leave its junk entries empty.
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
    GarageTools = 0.3, CrateTools = 0.3, GarageMetalwork = 0.5, ToolStoreMisc = 0.5, ToolStoreTools = 0.3,
    CrateElectronics = 0.5, ElectronicStoreMisc = 0.5, CrateMetalwork = 0.3, ToolStoreMetalwork = 0.3,
    GarageMechanics = 0.3,
}

-- Ready-made Live Wire equipment: electricians, electrical shelves, hardware stores, garages
-- (tool, mechanics and metalwork shelves).
local EQUIPMENT = {
    -- Rare outside electricians (it was found far too often); it is also crafted (Electrical 1).
    ["LiveWire.VoltageTester"] = {
        ElectricianTools = 1, WireFactoryElectric = 0.5, ToolStoreTools = 0.3, ElectronicStoreMisc = 0.3,
        CrateElectronics = 0.3, MechanicShelfElectric = 0.3, GarageTools = 0.2, CrateTools = 0.2,
    },
    ["LiveWire.DeepCycleBattery"] = {
        MechanicShelfElectric = 1, CarSupplyBatteries = 2, GarageMechanics = 0.3,
        CrateMechanics = 0.7, CrateElectronics = 0.5, ElectronicStoreMisc = 0.5, CampingStoreGear = 0.3,
    },
    ["Base.Mov_LiveWire_Inverter"] = {
        ElectricianTools = 0.5, WireFactoryElectric = 0.5, ToolStoreMisc = 0.2, GarageTools = 0.1,
        CrateElectronics = 0.5, ElectronicStoreMisc = 0.5, ElectronicStoreAppliances = 0.3,
        MechanicShelfElectric = 0.3, CrateTools = 0.2, GarageMechanics = 0.3,
    },
    ["Base.Mov_LiveWire_Breaker"] = {
        ElectricianTools = 1, WireFactoryElectric = 1, ToolStoreMisc = 0.5, GarageTools = 0.3, CrateTools = 0.3,
        CrateElectronics = 0.7, ElectronicStoreMisc = 0.5, ToolStoreTools = 0.5, CrateMetalwork = 0.3,
        GarageMechanics = 0.3, GarageMetalwork = 0.3,
    },
    ["Base.Mov_LiveWire_PowerBank"] = {
        ElectricianTools = 0.5, MechanicShelfElectric = 0.5, ToolStoreMisc = 0.3, GarageTools = 0.2,
        CrateElectronics = 0.5, ElectronicStoreMisc = 0.4, CrateMechanics = 0.3,
        GarageMechanics = 0.2, CrateTools = 0.2,
    },
    ["Base.Mov_LiveWire_BatteryAlarm"] = {
        ElectricianTools = 1, WireFactoryElectric = 1, ToolStoreMisc = 0.5,
        CrateElectronics = 0.7, ElectronicStoreMisc = 0.5, CrateTools = 0.3, GarageTools = 0.3,
        GarageMechanics = 0.3,
    },
    ["Base.Mov_LiveWire_WindTurbine"] = {
        ToolStoreMisc = 0.3, WireFactoryElectric = 0.5,
        CrateElectronics = 0.3, CrateMetalwork = 0.3, ToolStoreMetalwork = 0.5,
        CrateTools = 0.3, WireFactoryTools = 0.5, CrateFarming = 0.3,
        ToolStoreFarming = 0.3, MechanicShelfTools = 0.3, GarageMetalwork = 0.2,
    },
    ["Base.Mov_LiveWire_WaterWheel"] = {
        CrateCarpentry = 0.5, ToolStoreCarpentry = 0.5, CrateFarming = 0.5,
        ToolStoreFarming = 0.3, CrateTools = 0.3, CrateMechanics = 0.3, CrateMetalwork = 0.3,
    },
    ["LiveWire.WindTurbineBlades"] = {
        CrateMetalwork = 1, ToolStoreMetalwork = 1, CrateTools = 0.7,
        CrateFarming = 0.7, ToolStoreFarming = 0.7, WireFactoryTools = 0.7, GarageMetalwork = 0.7,
    },
    ["LiveWire.WindTurbineMast"] = {
        CrateMetalwork = 1, ToolStoreMetalwork = 1, CrateTools = 0.7,
        CrateMechanics = 0.7, CrateFarming = 0.7, ToolStoreFarming = 0.7, GarageMetalwork = 0.7,
    },
}

-- Vehicle containers (VehicleDistributions tables shared by the electrician profile, including the
-- electrical company vans, and by the metalworker profile).
local VEHICLE = {
    ["LiveWire.VoltageTester"] = { ElectricianTruckBed = 1, ElectricianGloveBox = 0.3 },
    ["LiveWire.SolarCell"] = { ElectricianTruckBed = 2 },
    ["Base.Mov_LiveWire_Breaker"] = { ElectricianTruckBed = 1 },
    ["Base.Mov_LiveWire_BatteryAlarm"] = { ElectricianTruckBed = 1 },
    ["Base.Mov_LiveWire_Inverter"] = { ElectricianTruckBed = 0.5 },
    ["Base.Mov_LiveWire_PowerBank"] = { ElectricianTruckBed = 0.5 },
    ["Base.Mov_LiveWire_SolarPanel"] = { ElectricianTruckBed = 0.5, MetalWelderTruckBed = 0.3 },
    ["LiveWire.WindTurbineBlades"] = { MetalWelderTruckBed = 1 },
    ["LiveWire.WindTurbineMast"] = { MetalWelderTruckBed = 1 },
    ["Base.Mov_LiveWire_WindTurbine"] = { MetalWelderTruckBed = 0.3 },
}

-- Equipment families with their own sandbox loot option (0 = never found). Universal
-- equipment (tester, battery, inverter, breaker, power bank, alarm) follows the overall
-- multiplier only.
local CATEGORY = {
    ["LiveWire.SolarCell"] = "solar",
    ["Base.Mov_LiveWire_SolarPanel"] = "solar",
    ["Base.Mov_LiveWire_WindTurbine"] = "wind",
    ["LiveWire.WindTurbineBlades"] = "wind",
    ["LiveWire.WindTurbineMast"] = "wind",
    ["Base.Mov_LiveWire_WaterWheel"] = "hydro",
}

local function proceduralList(name)
    return ProceduralDistributions.list[name]
end

local function vehicleList(name)
    return VehicleDistributions and VehicleDistributions[name]
end

-- Absolute weights, not repeated multiplication: merging or initializing twice
-- must neither duplicate entries nor compound the configured multiplier.
local function add(lists, fullType, multiplier, find)
    local changed = false
    for name, weight in pairs(lists) do
        local list = (find or proceduralList)(name)
        if list and list.items then
            local items, index = list.items, nil
            for i = 1, #items, 2 do
                if items[i] == fullType then index = i; break end
            end
            local target = weight * (multiplier or 1)
            if target <= 0 then
                -- 0 = this equipment is never found: leave no zero-weight entry behind.
                if index then
                    table.remove(items, index + 1)
                    table.remove(items, index)
                    changed = true
                end
            elseif index then
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

-- `categories` scales each family on top of the overall multiplier; absent at the
-- pre-merge event, where the sandbox options are not readable yet.
local function equipment(multiplier, categories)
    local function scale(fullType)
        local category = CATEGORY[fullType]
        if not category or not categories then return multiplier end
        return multiplier * categories[category]
    end
    local changed = add(CELL_LISTS, "LiveWire.SolarCell", scale("LiveWire.SolarCell"))
    if add(PANEL_LISTS, "Base.Mov_LiveWire_SolarPanel", scale("Base.Mov_LiveWire_SolarPanel")) then changed = true end
    for fullType, lists in pairs(EQUIPMENT) do
        if add(lists, fullType, scale(fullType)) then changed = true end
    end
    for fullType, lists in pairs(VEHICLE) do
        if add(lists, fullType, scale(fullType), vehicleList) then changed = true end
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
    local multiplier = LiveWire.Config.equipmentLoot()
    local categories = {}
    for category in pairs(LiveWire.Config.LOOT_CATEGORIES) do
        categories[category] = LiveWire.Config.lootCategory(category)
    end
    local changed = equipment(multiplier, categories)
    if changed then
        -- Parse rereads the tables without resetting vanilla sandbox loot factors.
        -- Startup only: no tick hook, container refill or world traversal.
        ItemPickerJava.Parse()
        print("[LiveWire] Equipment and parts loot multiplier applied: x" .. tostring(multiplier)
            .. ", solar x" .. tostring(categories.solar) .. ", wind x" .. tostring(categories.wind)
            .. ", hydro x" .. tostring(categories.hydro))
    end
end

Events.OnPreDistributionMerge.Add(onPreDistributionMerge)
Events.OnInitGlobalModData.Add(onInitGlobalModData)
