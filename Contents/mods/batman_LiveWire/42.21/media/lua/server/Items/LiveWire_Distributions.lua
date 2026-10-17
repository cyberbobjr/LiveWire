if isClient() then return end

-- Live Wire: loot. Solar cells and solar panels in garages, workshops and hardware
-- stores; the management software disk only when the Computer Mod is active (it
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
    if LiveWire and LiveWire.Compat and LiveWire.Compat.computerMod() then
        add(DISK_LISTS, "LiveWire.MonitorDisk")
    end
end

Events.OnPreDistributionMerge.Add(onPreDistributionMerge)
