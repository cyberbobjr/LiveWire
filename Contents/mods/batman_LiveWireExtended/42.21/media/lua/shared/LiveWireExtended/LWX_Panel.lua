-- LiveWire Extended: breaker board rules shared by client tooltips and the authority
-- (D-35). A wall object of 8, 16 or 24 modules, linked to an inverter with electric
-- wire like the power terminal (LWX_Link). Its breakers fill its slots (E16).
require "LiveWireExtended/LWX_Link"
require "LiveWireExtended/LWX_Terminal"

local X = LiveWire.Extended
local L = X.Link
local P = {}
X.Panel = P

P.LEVEL = 3   -- make and link a board, as the terminal (D-34 defaults)
-- Tiles of batman_livewireext_01 (source/tiles/build_extended_tiles.py): 8-9 board of 8
-- modules, 10-11 of 16, 12-13 of 24; facings S, E (north wall, west wall).
P.SIZES = { [8] = 8, [9] = 8, [10] = 16, [11] = 16, [12] = 24, [13] = 24 }
local SPRITES, SIZE_OF = {}, {}
for index, size in pairs(P.SIZES) do
    local name = X.Terminal.SHEET .. "_" .. index
    SPRITES[name], SIZE_OF[name] = true, size
end
-- The vanilla wall electrical boxes (industry_02_212..215, measured in E12) are boards of
-- 8 modules too: D-40 reuses them in the map's houses.
P.VANILLA = { "industry_02_212", "industry_02_213", "industry_02_214", "industry_02_215" }
for _, name in ipairs(P.VANILLA) do SPRITES[name], SIZE_OF[name] = true, 8 end
P.kind = L.register({ name = "panel", field = "panels", sprites = SPRITES, level = P.LEVEL,
    linkedKey = "Tooltip_LWX_PanelLinked", linkedNote = "IGUI_LWX_PanelLinked",
    unlinkedNote = "IGUI_LWX_PanelUnlinked" })

function P.isPanel(obj) return L.kindOf(obj) == P.kind end
function P.onSquare(sq) return L.objectOn(P.kind, sq) end
function P.recordAt(sq) return L.recordAt(P.kind, sq) end

-- Number of modules of a board object, from its sprite.
function P.size(obj)
    local spr = obj and obj:getSprite()
    return spr and SIZE_OF[spr:getName()] or nil
end

function P.checkLink(character, obj, invObj)
    if not P.isPanel(obj) then return false, "Tooltip_LWX_NoInverter" end
    return L.check(character, obj, invObj)
end
