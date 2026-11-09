-- LiveWire Extended: breaker board rules shared by client tooltips and the authority
-- (D-35). A wall object of 8, 16 or 24 modules, linked to an inverter with electric
-- wire like the power terminal (LWX_Link). Its breakers fill its slots (E16).
require "LiveWireExtended/LWX_Link"
require "LiveWireExtended/LWX_Terminal"

local X = LiveWire.Extended
local L = X.Link
local P = {}
X.Panel = P

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
P.kind = L.register({ name = "panel", field = "panels", sprites = SPRITES, level = X.LEVEL,
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

-- ---------------------------------------------------------------- enlargement (D-55)
-- A board the player placed (batman_livewireext_01 tiles) grows in place: 8 -> 16 -> 24
-- modules. The next size is the tile two indices on (same face: even indices south, odd east).
-- The vanilla wall boxes (industry_02_212..215) are not placed by the player and never grow.
P.MAX_SIZE = 24
P.ENLARGE_COST = { items = { { "Base.SmallSheetMetal", 1 }, { "Base.Screws", 4 } } }

-- Tile index of a placed board (batman_livewireext_01_<n>), or nil for anything else.
function P.tileIndex(obj)
    local sprite = obj and obj.getSprite and obj:getSprite()
    local name = sprite and sprite:getName()
    if type(name) ~= "string" then return nil end
    local index = string.match(name, "^" .. X.Terminal.SHEET .. "_(%d+)$")
    return index and tonumber(index) or nil
end

-- Tile index of the next size of a board tile index, or nil when it cannot grow.
function P.enlargedIndex(index)
    if index == nil or P.SIZES[index] == nil then return nil end
    local nextIndex = index + 2
    local nextSize = P.SIZES[nextIndex]
    if nextSize == nil or nextSize <= P.SIZES[index] or nextSize > P.MAX_SIZE then return nil end
    return nextIndex
end

-- May `character` enlarge board `obj` now? true, or false and a refusal key (and its argument).
-- Shared by the menu and the authority, which checks it again.
function P.enlargeCheck(character, obj)
    if P.enlargedIndex(P.tileIndex(obj)) == nil then return false, "Tooltip_LWX_EnlargeNone" end
    if not LiveWire.API.screwdriver(character) then return false, "Tooltip_LW_NeedScrewdriver" end
    if not LiveWire.API.hasLevel(character, X.LEVEL) then
        return false, "Tooltip_LWX_NeedLevel", tostring(LiveWire.Config.requiredLevel(X.LEVEL))
    end
    for _, item in ipairs(P.ENLARGE_COST.items) do
        if LiveWire.API.countType(character, item[1]) < item[2] then return false, "Tooltip_LWX_EnlargeNeedMaterials" end
    end
    return true
end
