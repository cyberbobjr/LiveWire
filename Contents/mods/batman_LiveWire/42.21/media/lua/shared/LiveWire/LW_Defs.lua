-- Live Wire: static definitions of devices and batteries (pure data).
-- Values come from docs/specifications-fonctionnelles.md (sections 2 to 5). The tiles are
-- geometric placeholders until the final models exist (the inverter cabinet has its final model).

LiveWire = LiveWire or {}

local Defs = {}
LiveWire.Defs = Defs

-- Placed devices, keyed by model name (stored in the registry: never rename).
-- Each device is a tile of the mod tileset (source/tiles/build_livewire_tiles.py):
-- `tile` is the index of its first sprite, `facings` the number of sprites (S, E,
-- N, W; wall objects: S = north wall, E = west wall). Placing and picking up use
-- the vanilla furniture cursor: placing needs nothing, picking up a screwdriver
-- (tile PickUpTool = Electrician, no PickUpLevel). `level` is the Electrical level
-- needed to link the device to an inverter, or for an inverter to put it in
-- service (first link). `xp` is awarded once, at the device's first link. `item` is
-- the placeable inventory item made by the recipe.
-- `overlays` (D-50) declares the state lights and moving parts drawn over the tile by
-- client/LW_Visuals.lua. Every value is the ABSOLUTE index of the first sprite of a light
-- in the sheet Defs.SHEET (the sprite drawn for facing f is value + f, like the tile), and
-- only the sprites listed in LW_Visuals EXISTS are drawn. A light exists when its key is
-- present; the condition comes from the device mark (m.st state, m.inv linked to an
-- inverter, m.pw supplied, m.cond, m.muf soundproofed, m.br braked):
--   on = m.st is "on"                  fault = m.st is "tripped" or "broken"
--   muffle = m.muf                     linked = m.inv
--   blinkWhenBraked = true: the `linked` light blinks (500 ms) while m.br
--   tripped = m.st is "tripped"        powered = m.inv and m.pw and m.cond > 0, only when not tripped
--   ringing = m.st is "ringing"        rotor = first of 4 blade frames (4 sprites per frame, + facing)
-- A device without `overlays` (every source registered by API.registerSource, whose sprites
-- live in another sheet) shows no light; letting the API pass `overlays` is a possible next step.
Defs.SHEET = "batman_livewire_01"

Defs.devices = {
    SolarPanel = {
        role = "source", kind = "solar",
        item = "Base.Mov_LiveWire_SolarPanel", tile = 0, facings = 4,
        nominalW = 100, level = 3, xp = 10,
        wearDays = 10, needsOutside = true,
        overlays = { linked = 36 },
    },
    WindTurbine = {
        role = "source", kind = "wind",
        item = "Base.Mov_LiveWire_WindTurbine", tile = 4, facings = 4,
        nominalW = 400, level = 2, xp = 20,
        wearDays = 4, needsOutside = true,
        overlays = { linked = 40, blinkWhenBraked = true, rotor = 48 },
    },
    WaterWheel = {
        role = "source", kind = "hydro",
        item = "Base.Mov_LiveWire_WaterWheel", tile = 8, facings = 4,
        nominalW = 120, level = 2, xp = 20,
        wearDays = 6, needsOutside = true, needsRiver = true,
        overlays = { linked = 44 },
    },
    Inverter = {
        role = "inverter",
        item = "Base.Mov_LiveWire_Inverter", tile = 12, facings = 4,
        maxW = 1500, idleW = 20, level = 3, xp = 25,
        wearDays = 5,
        -- Overlays (first sprite of each, + facing): running, fault, soundproofed.
        overlays = { on = 24, fault = 28, muffle = 68 },
    },
    -- Large inverter built from an inverter (model contributed by PewPewCricket).
    InverterCabinet = {
        role = "inverter",
        item = "Base.Mov_LiveWire_InverterCabinet", tile = 88, facings = 4,
        maxW = 4500, idleW = 60, level = 3, xp = 35,
        wearDays = 5,
        overlays = { on = 92, fault = 96, muffle = 100 },
        lcdBrand = "IGUI_LW_LCD_BrandCabinet",
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
        overlays = { linked = 32 },
    },
    Breaker = {
        role = "option", kind = "breaker",
        item = "Base.Mov_LiveWire_Breaker", tile = 20, facings = 2,
        level = 3, xp = 5,
        wearDays = 15,
        overlays = { tripped = 64, powered = 84 },
    },
    BatteryAlarm = {
        role = "option", kind = "alarm",
        item = "Base.Mov_LiveWire_BatteryAlarm", tile = 22, facings = 2,
        level = 2, xp = 5,
        wearDays = 30,
        overlays = { ringing = 66 },
    },
    WaterPump = {
        role = "pump",
        item = "Base.Mov_LiveWire_WaterPump", tile = 72, facings = 4,
        pumpW = 250, level = 3, xp = 20,
        wearDays = 10,
        -- LCD glow while supplied, including an idle pump with no linked fixture.
        overlays = { powered = 80 },
    },
}

-- Own fields of a source kind (D-50), kept on its registry entry and in its mark. `field` is
-- the registry entry field, `mark` the key in the mark kept by a picked-up kit; a numeric
-- field falls back to `default`, a `flag` field is only set when the mark holds true.
Defs.SOURCE_FIELDS = {}
Defs.SOURCE_FIELDS.solar = {
    { field = "dirt", mark = "dirt", default = 0 },
    { field = "snow", mark = "snow", default = 0 },
}
Defs.SOURCE_FIELDS.wind = { { field = "brake", mark = "br", flag = true } }

-- Source kinds whose facing (sprite offset from the tile) matters: the cursor names it and
-- the registry entry keeps it.
Defs.ORIENTED_KINDS = { solar = true }

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
Defs.BACKUP_LEVEL = 2          -- vanilla generator as backup power
Defs.COMPUTER_KEY = "LiveWireComputer"
Defs.COMPUTER_LEVEL = 3        -- vanilla desktop computer as management computer
Defs.ALARM_BELOW = 0.20
Defs.ALARM_RESET = 0.25
Defs.ALARM_REPEAT_HOURS = 2

-- Water pump (docs/annexes/conception/choix-et-extensions.md, section 2).
Defs.RELAY_SPRITE = Defs.SHEET .. "_76"   -- transparent tile, never in spriteToModel
Defs.RELAY_KEY = "LiveWireRelay"          -- ModData of a relay: { pump = deviceId }
Defs.BARREL_KEY = "LiveWireBarrel"        -- ModData of a linked barrel: { pump = deviceId }
Defs.RELAY_LITRES = 25                    -- capacity of one relay tank
Defs.PUMP_LITRES_PER_MINUTE = 5           -- flow of one pump
Defs.PUMP_BUDGET_MAX = Defs.PUMP_LITRES_PER_MINUTE -- no idle flow credits
Defs.PUMP_BARREL_RANGE = 1                -- the barrel must stand next to the pump (8 neighbouring squares), same floor
Defs.PUMP_MAX_BARRELS = 8
Defs.PUMP_PIPE = "Base.MetalPipe"         -- one per linked barrel, given back on unlink
Defs.PUMP_NOISE_RADIUS = 2                -- zombies hear a running pump this far
Defs.MIN_BARREL_CAPACITY = 20             -- litres: smaller fluid objects are not barrels
Defs.PUMP_FLUID_EPSILON = 0.001           -- litres: below this a container counts as empty / full

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
-- Public grid charging (option GridCharging): the inverter draws at most this
-- share of its continuous rating from the grid (1500 W inverter: 300 W).
Defs.GRID_CHARGE_RATIO = 0.2
Defs.SMOOTHING_TAU_HOURS = 0.5
Defs.TRIP_CONDITION_LOSS = 3
Defs.HEAVY_LOAD_RATIO = 0.80
Defs.SOUNDPROOF_KIT = "LiveWire.SoundproofKit"
Defs.MUFFLED_WEAR = 1.25   -- a soundproofed inverter runs warmer

-- Weather on the sources (Sim weatherOnSource). Months are 0-based: 8..10 = September..November.
Defs.SNOW_ACCUMULATION_PER_HOUR = 0.1   -- times the snow intensity, while it snows
Defs.SNOW_MELT_PER_HOUR = 0.05          -- above 0 degrees
Defs.DIRT_PER_HOUR = 0.0005             -- dirt on a panel, per hour (SolarDirt option)
Defs.DIRT_PER_HOUR_AUTUMN = 0.001       -- leaves: faster in autumn
Defs.DIRT_AUTUMN_FIRST_MONTH = 8
Defs.DIRT_AUTUMN_LAST_MONTH = 10
Defs.DIRT_RAIN_WASH = 0.02              -- washed per hour and per unit of rain intensity
Defs.DIRT_MAX = 0.5
Defs.SOLAR_STORM_HOURS = 20             -- a panel is hit once per 20 storm hours on average
Defs.SOLAR_STORM_LOSS = 5               -- condition points lost per hit
Defs.WIND_STORM_HOURS = 6               -- a turbine over its cut-out speed is hit once per 6 hours on average
Defs.WIND_STORM_LOSS_MIN = 5            -- condition points lost per hit: ZombRand(MIN, MAX), MAX excluded
Defs.WIND_STORM_LOSS_MAX = 16
Defs.BACKUP_MAX_FUEL = 10               -- litres: vanilla generator tank, shown by the LCD

-- Parallel inverters (docs/annexes/conception/choix-et-extensions.md, section 5).
Defs.MAX_SLAVES = 3                         -- 4 inverters per network
Defs.COUPLING_KIT = "LiveWire.CouplingKit"
Defs.COUPLING_LEVEL = 3

-- Installation efficiency from the Electrical level of whoever linked the device.
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
