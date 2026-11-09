-- LiveWire Extended: core namespace of the optional sub-mod (D-32).
-- It requires Live Wire (mod.info require=) and only talks to it through the
-- coverage extension point (LiveWire/LW_Coverage) and the public anchor table.
-- It never changes GeneratorTileRange nor GeneratorVerticalPowerRange, and keeps
-- its data under its own global ModData key: disabling it brings Live Wire back
-- to its disc, with no exit menu.
require "LiveWire/LW_Core"
require "LiveWire/LW_Coverage"

LiveWire = LiveWire or {}
local X = LiveWire.Extended or {}
LiveWire.Extended = X

X.VERSION = 1
X.DATA_KEY = "LiveWireExtended" -- global ModData: connected areas, public (no secret)
X.CHUNK = 8                       -- IsoChunkMap.CHUNK_SIZE_IN_SQUARES

function X.log(msg) print("[LiveWireExtended] " .. tostring(msg)) end
function X.warn(msg) print("[LiveWireExtended] WARNING: " .. tostring(msg)) end

-- Sandbox option of this sub-mod, or its default.
local DEFAULTS = { BuildingBand = 1, HouseBoardPercent = 30 }
function X.option(name)
    local opts = getSandboxOptions and getSandboxOptions()
    local opt = opts and opts:getOptionByName("LiveWireExtended." .. name)
    if opt then return opt:getValue() end
    if SandboxVars and SandboxVars.LiveWireExtended and SandboxVars.LiveWireExtended[name] ~= nil then
        return SandboxVars.LiveWireExtended[name]
    end
    return DEFAULTS[name]
end
