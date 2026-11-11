-- LiveWire Extended: breaker board rules shared by client tooltips and the authority
-- (D-35). A wall object of 8, 16 or 24 modules, linked to an inverter with electric
-- wire like the power terminal (LWX_Link). Its breakers fill its slots (E16).
require "LiveWireExtended/LWX_Link"
require "LiveWireExtended/LWX_Terminal"
require "LiveWireExtended/LWX_Sites"

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

-- A vanilla wall box of the map is weatherproof: it may hang outside (D-62). Offset from its
-- square to the square on the other side of the wall it hangs on (industry_02_212 attachedN,
-- 213 attachedW, 214 attachedS, 215 attachedE). A crafted board is not weatherproof.
P.WEATHERPROOF = { industry_02_212 = { 0, -1 }, industry_02_213 = { -1, 0 },
                   industry_02_214 = { 0, 1 }, industry_02_215 = { 1, 0 } }

-- dx, dy to the square across the wall of a weatherproof box, or nil.
function P.acrossWall(spriteName)
    local d = P.WEATHERPROOF[spriteName or ""]
    if not d then return nil end
    return d[1], d[2]
end

-- Site a board serves (D-62): the site of its own square, the face of the wall it hangs on
-- (X.Sites); a weatherproof box hanging outside (record.wall, set when linked) serves the site
-- across its wall. The one rule of the placement, the power (LWX_Panels), the breakers
-- (LWX_Points), the tint and the wiring menu. nil when the board serves nothing.
function P.siteOf(record)
    local site = X.Sites.at(record.x, record.y, record.z)
    if site or not record.wall then return site end
    return X.Sites.at(record.x + record.wall[1], record.y + record.wall[2], record.z)
end

-- Tiles a player hangs (batman_livewireext_01_8..13), not weatherproof: only on the inside face
-- of a wall. The vanilla boxes (P.WEATHERPROOF) are not concerned: the furniture cursor never
-- places them (not moveable, industry_02_212 measured in game), only the map does.
P.REFUSED_OUTSIDE = "Tooltip_LWX_BoardNeedIndoor"
function P.placementRule(spriteName, sq)
    if not spriteName or P.SIZES[tonumber(string.match(spriteName, "^" .. X.Terminal.SHEET .. "_(%d+)$") or "")] == nil then
        return nil
    end
    if X.Sites.at(sq:getX(), sq:getY(), sq:getZ()) then return true end
    -- An MP client learns late that a fresh player house is closed and roofed (its world
    -- regions are only right after a reconnection, measured 2026-11-11): under a roof it lets
    -- the authority judge, which runs this rule again when the place action completes.
    if isClient() and sq:getZ() >= 0 and not sq:isOutside() then return true end
    return false, P.REFUSED_OUTSIDE
end
LiveWire.API.addPlacementRule(P.placementRule)

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
