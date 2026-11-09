-- LiveWire Extended: power terminal rules shared by client tooltips and the authority.
require "LiveWireExtended/LWX_Link"

local X = LiveWire.Extended
local L = X.Link
local T = {}
X.Terminal = T

T.SHEET = "batman_livewireext_01"   -- tiles 0..3 (source/tiles/build_extended_tiles.py)
local SPRITES = {}
for i = 0, 3 do SPRITES[T.SHEET .. "_" .. i] = true end
T.kind = L.register({ name = "terminal", field = "terminals", sprites = SPRITES, level = X.LEVEL,
    linkedKey = "Tooltip_LWX_TerminalLinked", linkedNote = "IGUI_LWX_TerminalLinked",
    unlinkedNote = "IGUI_LWX_TerminalUnlinked" })

T.key = L.key
function T.isTerminal(obj) return L.kindOf(obj) == T.kind end
function T.onSquare(sq) return L.objectOn(T.kind, sq) end
function T.recordAt(sq) return L.recordAt(T.kind, sq) end

-- Can `character` link terminal `obj` to inverter object `invObj`? (LWX_Link.check)
function T.checkLink(character, obj, invObj)
    if not T.isTerminal(obj) then return false, "Tooltip_LWX_NoInverter" end
    return L.check(character, obj, invObj)
end
