-- Live Wire: one scale factor for every window of the mod (C27).
-- The windows are designed in pixels for the 1080p reference font: UIFont.Small
-- 19 px high, the reference used by the vanilla build windows
-- (client/Entity/ISUI/BuildRecipe/ISWidgetBuildControl.lua:7). With a larger font
-- size option (4K screens), every size, margin and button grows by the same
-- factor, never under 1, and the window stays inside the screen.
-- Computed when a window is created, never per frame: the font size option only
-- applies after a restart, a window opened later picks it up.
if isServer() then return end

LiveWire = LiveWire or {}

local UI = {}
LiveWire.UIScale = UI

UI.REF_FONT_H = 19
UI.MARGIN = 16   -- free space kept around a window at the screen edges

local function screen()
    local core = getCore()
    return core:getScreenWidth(), core:getScreenHeight()
end

-- Height of the Small font relative to the reference, at least 1.
function UI.fontScale()
    local h = getTextManager():getFontHeight(UIFont.Small)
    local k = (tonumber(h) or UI.REF_FONT_H) / UI.REF_FONT_H
    if k < 1 then k = 1 end
    return k
end

-- Factor for a window designed at baseW x baseH: the font scale, lowered so that
-- the scaled window fits the screen, never under 1.
function UI.factor(baseW, baseH)
    local k = UI.fontScale()
    local sw, sh = screen()
    if baseW and baseW > 0 then k = math.min(k, (sw - 2 * UI.MARGIN) / baseW) end
    if baseH and baseH > 0 then k = math.min(k, (sh - 2 * UI.MARGIN) / baseH) end
    if k < 1 then k = 1 end
    return k
end

function UI.px(v, k)
    return math.floor(v * k + 0.5)
end

-- Scaled copy of a table of base pixel sizes; `k` is kept in the copy.
function UI.layout(k, base)
    local t = { k = k }
    for name, v in pairs(base) do t[name] = UI.px(v, k) end
    return t
end

-- Size limited to the screen, then position moved so that the whole window is
-- visible. Returns x, y, w, h.
function UI.fit(x, y, w, h)
    local sw, sh = screen()
    w = math.min(w, sw)
    h = math.min(h, sh)
    x = math.max(0, math.min(x, sw - w))
    y = math.max(0, math.min(y, sh - h))
    return math.floor(x), math.floor(y), math.floor(w), math.floor(h)
end
