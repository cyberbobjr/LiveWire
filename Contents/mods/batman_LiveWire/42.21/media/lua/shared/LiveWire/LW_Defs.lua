-- Live Wire: static definitions of devices and batteries (pure data).
-- Values come from docs/fonctionnel.md (sections 2 to 5). The tiles are
-- geometric placeholders until the final models exist.

LiveWire = LiveWire or {}

local Defs = {}
LiveWire.Defs = Defs

-- Placed devices, keyed by model name (stored in the registry: never rename).
-- Each device is a tile of the mod tileset (source/tiles/build_livewire_tiles.py):
-- `tile` is the index of its first sprite, `facings` the number of sprites (S, E,
-- N, W; wall objects: S = north wall, E = west wall). Placing and picking up use
-- the vanilla furniture cursor; the Electrical level and the screwdriver come from
-- the tile properties (PickUpLevel, PickUpTool = Electrician). `item` is the
-- placeable inventory item made by the recipe.
Defs.SHEET = "batman_livewire_01"

Defs.devices = {
    SolarPanel = {
        role = "source", kind = "solar",
        item = "Base.Mov_LiveWire_SolarPanel", tile = 0, facings = 4,
        nominalW = 100, level = 3, xp = 10,
        wearDays = 10, needsOutside = true,
    },
    WindTurbine = {
        role = "source", kind = "wind",
        item = "Base.Mov_LiveWire_WindTurbine", tile = 4, facings = 4,
        nominalW = 400, level = 6, xp = 20,
        wearDays = 4, needsOutside = true,
    },
    WaterWheel = {
        role = "source", kind = "hydro",
        item = "Base.Mov_LiveWire_WaterWheel", tile = 8, facings = 4,
        nominalW = 120, level = 7, xp = 20,
        wearDays = 6, needsOutside = true, needsRiver = true,
    },
    Inverter = {
        role = "inverter",
        item = "Base.Mov_LiveWire_Inverter", tile = 12, facings = 4,
        maxW = 1500, idleW = 20, level = 5, xp = 25,
        wearDays = 5,
    },
    PowerBank = {
        role = "storage",
        item = "Base.Mov_LiveWire_PowerBank", tile = 16, facings = 4,
        -- The container comes from the tile (container = livewirepowerbank,
        -- ContainerCapacity = 50): vanilla creates it at placement and marks it
        -- explored, so no loot is generated in it.
        slots = 4,
        level = 2, xp = 5,
        wearDays = 30,
    },
    Breaker = {
        role = "option", kind = "breaker",
        item = "Base.Mov_LiveWire_Breaker", tile = 20, facings = 2,
        level = 3, xp = 5,
        wearDays = 15,
    },
    BatteryAlarm = {
        role = "option", kind = "alarm",
        item = "Base.Mov_LiveWire_BatteryAlarm", tile = 22, facings = 2,
        level = 2, xp = 5,
        wearDays = 30,
    },
}

-- Sprite name -> model, and model of an inventory item.
Defs.spriteToModel = {}
Defs.itemToModel = {}
for model, def in pairs(Defs.devices) do
    for i = 0, def.facings - 1 do
        Defs.spriteToModel[Defs.SHEET .. "_" .. tostring(def.tile + i)] = model
    end
    Defs.itemToModel[def.item] = model
end

-- Model of a placed object from its sprite, or nil.
function Defs.modelOfObject(obj)
    if not obj or not obj.getSprite then return nil end
    local spr = obj:getSprite()
    local name = spr and spr:getName()
    if not name then return nil end
    return Defs.spriteToModel[name]
end

-- Vanilla objects wired to an inverter. Their link is stored in their own ModData
-- under these keys (never the device mark), so vanilla actions stay available.
Defs.BACKUP_KEY = "LiveWireBackup"
Defs.BACKUP_LEVEL = 3          -- vanilla generator as backup power
Defs.COMPUTER_KEY = "LiveWireComputer"
Defs.COMPUTER_LEVEL = 6        -- vanilla desktop computer as management computer
Defs.SHED_LEVEL = 7            -- load shedding by the management computer
Defs.ALARM_BELOW = 0.20
Defs.ALARM_RESET = 0.25
Defs.ALARM_REPEAT_HOURS = 2

-- Batteries stored in a power bank. Keyed by full type.
Defs.batteries = {
    ["Base.CarBattery1"] = { capacityKWh = 0.40, lifeCycles = 150 },
    ["Base.CarBattery2"] = { capacityKWh = 0.60, lifeCycles = 150 },
    ["Base.CarBattery3"] = { capacityKWh = 0.90, lifeCycles = 150 },
    ["LiveWire.DeepCycleBattery"] = { capacityKWh = 1.50, lifeCycles = 600 },
}

Defs.CHARGE_EFFICIENCY = 0.90
Defs.SELF_DISCHARGE_PER_DAY = 0.002
Defs.DEEP_DISCHARGE_THRESHOLD = 0.20
Defs.RESTART_STOCK_RATIO = 0.02
Defs.SMOOTHING_TAU_HOURS = 0.5
Defs.TRIP_CONDITION_LOSS = 3
Defs.HEAVY_LOAD_RATIO = 0.80
Defs.SOUNDPROOF_KIT = "LiveWire.SoundproofKit"
Defs.MUFFLED_WEAR = 1.25   -- a soundproofed inverter runs warmer

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
