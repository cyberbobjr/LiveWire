-- Live Wire: static definitions of devices and batteries (pure data).
-- Values come from docs/fonctionnel.md (sections 2 to 5). Sprites are vanilla
-- placeholders until the final tiles exist.

LiveWire = LiveWire or {}

local Defs = {}
LiveWire.Defs = Defs

-- Placed devices, keyed by model name (stored in the registry: never rename).
Defs.devices = {
    SolarPanel = {
        role = "source", kind = "solar",
        kit = "LiveWire.SolarPanelKit",
        sprite = "appliances_com_01_20",      -- placeholder: Mov_SatelliteDish
        nominalW = 100, level = 3, xp = 10,
        wearDays = 10, needsOutside = true,
    },
    WindTurbine = {
        role = "source", kind = "wind",
        kit = "LiveWire.WindTurbineKit",
        sprite = "industry_01_4",             -- placeholder: Mov_AirConditioner
        nominalW = 400, level = 6, xp = 20,
        wearDays = 4, needsOutside = true,
    },
    Inverter = {
        role = "inverter",
        kit = "LiveWire.InverterKit",
        sprite = "location_business_machinery_01_32", -- placeholder: Mov_CabinetTool
        maxW = 1500, idleW = 20, level = 5, xp = 25,
        wearDays = 5,
    },
    HeavyInverter = {
        role = "inverter",
        kit = "LiveWire.HeavyInverterKit",
        sprite = "location_business_machinery_01_32", -- placeholder: Mov_CabinetTool
        maxW = 3000, idleW = 30, level = 8, xp = 30,
        wearDays = 5,
    },
    Breaker = {
        role = "option", kind = "breaker",
        kit = "LiveWire.BreakerKit",
        -- Wall-mounted, like a real breaker panel. Placeholder: Mov_SquareWallClock.
        -- The facing variant is picked at install time from the attachedN / attachedW
        -- flags of these candidates (variant names are an assumption, see prototype P1).
        sprite = "walls_decoration_01_105",
        wallSprites = { "walls_decoration_01_104", "walls_decoration_01_105",
                        "walls_decoration_01_106", "walls_decoration_01_107" },
        wallMounted = true,
        level = 3, xp = 5,
        wearDays = 15,
    },
}

-- Batteries: placed on the floor as normal items, then linked. Keyed by full type.
Defs.batteries = {
    ["Base.CarBattery1"] = { capacityKWh = 0.40, lifeCycles = 150 },
    ["Base.CarBattery2"] = { capacityKWh = 0.60, lifeCycles = 150 },
    ["Base.CarBattery3"] = { capacityKWh = 0.90, lifeCycles = 150 },
    ["LiveWire.DeepCycleBattery"] = { capacityKWh = 1.50, lifeCycles = 600 },
}

Defs.BATTERY_LINK_LEVEL = 2
Defs.CHARGE_EFFICIENCY = 0.90
Defs.SELF_DISCHARGE_PER_DAY = 0.002
Defs.DEEP_DISCHARGE_THRESHOLD = 0.20
Defs.RESTART_STOCK_RATIO = 0.02
Defs.SMOOTHING_TAU_HOURS = 0.5
Defs.TRIP_CONDITION_LOSS = 3
Defs.HEAVY_LOAD_RATIO = 0.80

-- Kit full type -> device model.
Defs.kitToModel = {}
for model, def in pairs(Defs.devices) do
    Defs.kitToModel[def.kit] = model
end

-- Installation efficiency from the installer's Electrical level.
function Defs.installEfficiency(level)
    if level >= 9 then return 1.0 end
    if level >= 7 then return 0.95 end
    return 0.85
end

-- Battery wear multiplier from the Electrical level of whoever linked it.
function Defs.batteryWearSkillFactor(level)
    if level >= 6 then return 0.90 end
    if level >= 2 then return 0.95 end
    return 1.0
end

-- Device wear multiplier at levels 9-10.
function Defs.deviceWearSkillFactor(level)
    if level >= 9 then return 0.75 end
    return 1.0
end

-- Install failure chance in percent.
function Defs.installFailChance(level, required)
    local c = 30 - 5 * (level - required)
    if c < 0 then c = 0 end
    return c
end

-- Repair failure chance in percent (halved from level 8).
function Defs.repairFailChance(level)
    local c = 40 - 5 * level
    if c < 5 then c = 5 end
    if level >= 8 then c = c / 2 end
    return c
end

function Defs.isBattery(fullType)
    return Defs.batteries[fullType] ~= nil
end
