-- Live Wire: sandbox options (media/sandbox-options.txt).
-- getOptionByName() reads the live value; SandboxVars can be stale in single player
-- after the in-game editor (knowledge/mod-loading.md:152).

LiveWire = LiveWire or {}

local Config = {}
LiveWire.Config = Config

local DEFAULTS = {
    EquipmentLootMultiplier = 5.0,
    SolarLootMultiplier = 1.0,
    WindLootMultiplier = 1.0,
    HydroLootMultiplier = 1.0,
    PowerScale = 1.0,
    ConsumptionProfile = 3,
    SolarMultiplier = 1.0,
    WindMultiplier = 1.0,
    HydroMultiplier = 1.0,
    BatteryCapacityMultiplier = 1.0,
    BatteryWearMultiplier = 1.0,
    DeviceWearMultiplier = 1.0,
    InverterNoiseRadius = 2,
    LinkRange = 12,
    LinkVerticalRange = 3,
    PumpRange = 15,
    PumpTankSize = 1,
    WirePerTiles = 4,
    StormDamage = false,
    SolarOrientation = true,
    SolarDirt = true,
    BatteryCold = false,
    LiveWorkRisk = true,
    XPMultiplier = 1.0,
    SkillGates = true,
    SimulateUnloaded = true,
    GridCharging = true,
    BackupStartPercent = 20,
    BackupStopPercent = 90,
}
Config.DEFAULTS = DEFAULTS

function Config.get(name)
    local opts = getSandboxOptions and getSandboxOptions()
    if opts then
        local opt = opts:getOptionByName("LiveWire." .. name)
        if opt then return opt:getValue() end
    end
    if SandboxVars and SandboxVars.LiveWire and SandboxVars.LiveWire[name] ~= nil then
        return SandboxVars.LiveWire[name]
    end
    return DEFAULTS[name]
end

-- Equipment loot: one overall multiplier (0 = none at all) and one per family
-- (0 = none at all). A family only holds what it names: universal equipment and
-- LiveWire Extended follow the overall multiplier alone.
Config.LOOT_CATEGORIES = { solar = "SolarLootMultiplier", wind = "WindLootMultiplier", hydro = "HydroLootMultiplier" }

-- Clamp that also rejects a missing value and NaN (a NaN would break every weight).
local function bounded(name, low, high, fallback)
    local value = tonumber(Config.get(name))
    if not value or value ~= value then return fallback end
    return math.max(low, math.min(high, value))
end

function Config.equipmentLoot()
    return bounded("EquipmentLootMultiplier", 0, 20, 5)
end

function Config.lootCategory(category)
    local option = Config.LOOT_CATEGORIES[category]
    if not option then return 1 end
    return bounded(option, 0, 10, 1)
end

-- Vanilla generator ranges also define the inverter range.
function Config.tileRange()
    local opts = getSandboxOptions()
    local opt = opts and opts:getOptionByName("GeneratorTileRange")
    if opt then return opt:getValue() end
    return 20
end

function Config.verticalRange()
    local opts = getSandboxOptions()
    local opt = opts and opts:getOptionByName("GeneratorVerticalPowerRange")
    if opt then return opt:getValue() end
    return 3
end

-- Litres of the relay tank a water pump keeps above each plumbed fixture, from the
-- PumpTankSize enum (1 = 25 L, the former fixed size). Unknown values give 25 L.
Config.PUMP_TANK_LITRES = { 25, 80, 150, 300 }
function Config.pumpTankLitres()
    return Config.PUMP_TANK_LITRES[Config.get("PumpTankSize")] or Config.PUMP_TANK_LITRES[1]
end

-- Required Electrical level, or 0 when skill gates are disabled.
function Config.requiredLevel(level)
    if Config.get("SkillGates") then return level end
    return 0
end
