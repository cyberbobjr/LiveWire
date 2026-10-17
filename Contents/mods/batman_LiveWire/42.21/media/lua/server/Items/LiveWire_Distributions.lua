if isClient() then return end

-- Live Wire: loot. Solar cells, solar panels and ready-made equipment in garages, workshops,
-- electricians and hardware stores; the management software disk only when the Computer Mod is active (it
-- is useless without it).
require "Items/ProceduralDistributions"

-- Management software disk (only with the Computer Mod).
local DISK_LISTS = {
    ElectronicStoreComputers = 2, CrateComputer = 2, BookstoreComputer = 1,
    UniversityDesk_Computer = 1, UniversityDesk_Electrical = 2, OfficeDesk = 0.3,
}

-- Solar cells: garages, workshops, electricians.
local CELL_LISTS = {
    GarageTools = 2, CrateTools = 1, GarageMetalwork = 1, MechanicShelfElectric = 2,
    ElectricianTools = 3, MetalShopTools = 1, WireFactoryElectric = 2, ToolStoreMisc = 2,
}

-- Ready-made solar panels (placeable): garages, workshops, hardware stores.
local PANEL_LISTS = {
    GarageTools = 0.3, CrateTools = 0.3, GarageMetalwork = 0.2, ToolStoreMisc = 0.5, ToolStoreTools = 0.3,
}

-- Ready-made Live Wire equipment: electricians, electrical shelves, hardware stores, garages.
local EQUIPMENT = {
    ["LiveWire.VoltageTester"] = {
        ElectricianTools = 3, ToolStoreTools = 1, GarageTools = 1, CrateTools = 1, WireFactoryElectric = 1,
    },
    ["LiveWire.DeepCycleBattery"] = { MechanicShelfElectric = 1, CarSupplyBatteries = 2, GarageMechanics = 0.3 },
    ["Base.Mov_LiveWire_Inverter"] = {
        ElectricianTools = 0.5, WireFactoryElectric = 0.5, ToolStoreMisc = 0.2, GarageTools = 0.1,
    },
    ["Base.Mov_LiveWire_Breaker"] = {
        ElectricianTools = 1, WireFactoryElectric = 1, ToolStoreMisc = 0.5, GarageTools = 0.3, CrateTools = 0.3,
    },
    ["Base.Mov_LiveWire_PowerBank"] = {
        ElectricianTools = 0.5, MechanicShelfElectric = 0.5, ToolStoreMisc = 0.3, GarageTools = 0.2,
    },
    ["Base.Mov_LiveWire_BatteryAlarm"] = { ElectricianTools = 1, WireFactoryElectric = 1, ToolStoreMisc = 0.5 },
    ["Base.Mov_LiveWire_WindTurbine"] = { ToolStoreMisc = 0.1, WireFactoryElectric = 0.1 },
}

local function add(lists, fullType)
    for name, weight in pairs(lists) do
        local list = ProceduralDistributions.list[name]
        if list and list.items then
            table.insert(list.items, fullType)
            table.insert(list.items, weight)
        end
    end
end

local function onPreDistributionMerge()
    add(CELL_LISTS, "LiveWire.SolarCell")
    add(PANEL_LISTS, "Base.Mov_LiveWire_SolarPanel")
    for fullType, lists in pairs(EQUIPMENT) do
        add(lists, fullType)
    end
    if LiveWire and LiveWire.Compat and LiveWire.Compat.computerMod() then
        add(DISK_LISTS, "LiveWire.MonitorDisk")
    end
end

Events.OnPreDistributionMerge.Add(onPreDistributionMerge)
