-- Live Wire: sandbox options (media/sandbox-options.txt).
-- getOptionByName() reads the live value; SandboxVars can be stale in single player
-- after the in-game editor (knowledge/mod-loading.md:152).

LiveWire = LiveWire or {}

local Config = {}
LiveWire.Config = Config

local DEFAULTS = {
    PowerScale = 1.0,
    SolarMultiplier = 1.0,
    WindMultiplier = 1.0,
    BatteryCapacityMultiplier = 1.0,
    BatteryWearMultiplier = 1.0,
    DeviceWearMultiplier = 1.0,
    InverterNoiseRadius = 2,
    LinkRange = 12,
    WirePerTiles = 4,
    StormDamage = false,
    XPMultiplier = 1.0,
    SkillGates = true,
    SimulateUnloaded = true,
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

-- Required Electrical level, or 0 when skill gates are disabled.
function Config.requiredLevel(level)
    if Config.get("SkillGates") then return level end
    return 0
end
