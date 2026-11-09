-- LiveWire Extended: core namespace of the optional sub-mod (D-32).
-- It requires Live Wire (mod.info require=) and talks to it only through LiveWire.API
-- (D-47), the extension points (LiveWire.Coverage, LiveWire.CircuitProvider,
-- LiveWire.Coupling), the reading of LiveWire.Config, LiveWire.UIScale,
-- LiveWire.notify / notifyNear and LiveWire.Anchor.reshape.
-- It never changes GeneratorTileRange nor GeneratorVerticalPowerRange, and keeps
-- its data under its own global ModData key: disabling it brings Live Wire back
-- to its disc, with no exit menu.
require "LiveWire/LW_Core"
require "LiveWire/LW_Coverage"
require "LiveWire/LW_API"

LiveWire = LiveWire or {}
local X = LiveWire.Extended or {}
LiveWire.Extended = X

X.VERSION = 1
X.DATA_KEY = "LiveWireExtended" -- global ModData: connected areas, public (no secret)
X.CHUNK = 8                       -- IsoChunkMap.CHUNK_SIZE_IN_SQUARES
X.LEVEL = 3                       -- Electrical level of every wiring job: inverter commissioning (D-29, D-33), terminal, board, breaker, point (D-41)
X.WIRE = "Base.ElectricWire"      -- the cable item of Live Wire

function X.log(msg) print("[LiveWireExtended] " .. tostring(msg)) end
function X.warn(msg) print("[LiveWireExtended] WARNING: " .. tostring(msg)) end

-- Administrator: anyone in single player; on a server or a client, an access level that is
-- neither empty nor "None". The server stays sovereign: it re-checks on every command.
function X.isAdmin(character)
    if not isServer() and not isClient() then return true end
    local level = character and character.getAccessLevel and character:getAccessLevel()
    return level ~= nil and level ~= "" and level ~= "None" and level ~= "none"
end

-- Sandbox option of this sub-mod, or its default.
local DEFAULTS = { BuildingBand = 0, HouseBoardPercent = 30 }
function X.option(name)
    local opts = getSandboxOptions and getSandboxOptions()
    local opt = opts and opts:getOptionByName("LiveWireExtended." .. name)
    if opt then return opt:getValue() end
    if SandboxVars and SandboxVars.LiveWireExtended and SandboxVars.LiveWireExtended[name] ~= nil then
        return SandboxVars.LiveWireExtended[name]
    end
    return DEFAULTS[name]
end
