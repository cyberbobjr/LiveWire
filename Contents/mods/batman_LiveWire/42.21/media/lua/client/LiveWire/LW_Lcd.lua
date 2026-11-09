-- Live Wire: the LCD screens of the devices (D-56). Every backlit screen drawn by Live Wire and
-- LiveWire Extended (bank, device, pump, inverter, breaker and board windows) takes its palette,
-- its frame, its lines and its gauge from here.
-- Coordinates are in window units: multiplied by `ui.lwK` when the window carries a factor
-- (enclosure windows, reference units), used as given otherwise (windows laid out in pixels).
-- The pure functions (scroll offset, gauge fill) carry no drawing and are tested offline.
if isServer() then return end
require "LiveWire/LW_UIKit"

LiveWire = LiveWire or {}
local Lcd = {}
LiveWire.Lcd = Lcd

local Kit = LiveWire.UIKit

-- One frame colour and one glare for every screen; screen and ink per variant.
local BEZEL = { 0.06, 0.07, 0.06 }
local GLARE = { 0.96, 0.95, 0.90 }
Lcd.PALETTE = {
    green = { bezel = BEZEL, screen = { 0.62, 0.74, 0.40 }, ink = { 0.08, 0.13, 0.05 }, glare = GLARE },
    pump = { bezel = BEZEL, screen = { 0.38, 0.64, 0.82 }, ink = { 0.05, 0.11, 0.20 }, glare = GLARE },
    off = { bezel = BEZEL, screen = { 0.16, 0.19, 0.14 }, ink = { 0.6, 0.65, 0.55 }, glare = GLARE },
}
-- Fault text (inverter overload) on a lit screen.
Lcd.ALERT = { 0.55, 0.05, 0.02 }
Lcd.GLARE_ALPHA = 0.16
-- Lines wider than their screen scroll back and forth: speed in window units per second at
-- factor 1, pause at each end.
Lcd.SCROLL = 40
Lcd.SCROLL_PAUSE_MS = 1200
-- The LCD font (Code) has no ellipsis glyph: text abbreviated on a screen ends with three dots.
Lcd.ELLIPSIS = "..."

-- Screen of the bank and device windows, 1080p reference pixels (scaled with LW_UIScale.layout):
-- frame at lcdX, lcdY, `lcdInner` thick, lcdBottom above the window's bottom; lines from textX,
-- lineY, clipped to clipX, clipY .. width - clipRight, height - clipBottom.
Lcd.DEVICE_BASE = { lcdX = 14, lcdY = 42, lcdInner = 5, lcdBottom = 106,
    textX = 28, clipX = 27, clipY = 48, clipRight = 54, clipBottom = 118, lineY = 56, linePad = 4,
    scroll = Lcd.SCROLL }

-- Copy of `base` with the screen sizes of DEVICE_BASE added.
function Lcd.withDeviceScreen(base)
    local t = {}
    for name, v in pairs(Lcd.DEVICE_BASE) do t[name] = v end
    for name, v in pairs(base) do t[name] = v end
    return t
end

local function palette(variant)
    if type(variant) == "table" then return variant end
    return Lcd.PALETTE[variant or "green"] or Lcd.PALETTE.green
end

-------------------------------------------------------------------------------
-- Pure functions
-------------------------------------------------------------------------------

-- Horizontal shift of a line `width` wide in a box `avail` wide at time `now` (ms): still for
-- pauseMs, moves to its end at `speed` units per second, still again, then moves back.
function Lcd.scrollOffset(width, avail, speed, now, pauseMs)
    if width <= avail or not speed or speed <= 0 then return 0 end
    pauseMs = pauseMs or Lcd.SCROLL_PAUSE_MS
    local travel = width - avail
    local moveMs = travel / speed * 1000
    local t = now % (2 * (moveMs + pauseMs))
    if t < pauseMs then return 0 end
    t = t - pauseMs
    if t < moveMs then return t / moveMs * travel end
    t = t - moveMs
    if t < pauseMs then return travel end
    return travel - (t - pauseMs) / moveMs * travel
end

-- Width of a gauge's fill inside a border `w` wide with `gap` on each side.
function Lcd.fillWidth(fraction, w, gap)
    local f = math.max(0, math.min(1, fraction or 0))
    return (w - 2 * gap) * f
end

-------------------------------------------------------------------------------
-- Measures (engine text manager)
-------------------------------------------------------------------------------

-- Font of the text shown on a screen (Code, or Small in CN/JP/KO/TH: C10).
function Lcd.font()
    return LiveWire.Client.lcdFont()
end

function Lcd.measure(ui, font, s)
    return getTextManager():MeasureStringX(font, s) / (ui.lwK or 1)
end

function Lcd.fontHeight(ui, font)
    return getTextManager():getFontHeight(font or Lcd.font()) / (ui.lwK or 1)
end

-------------------------------------------------------------------------------
-- Drawing
-------------------------------------------------------------------------------

-- Frame `bezel` thick around a screen, with the glass glare on top. x, y, w, h: outer box.
-- Returns the screen box.
function Lcd.frame(ui, x, y, w, h, variant, bezel)
    local p = palette(variant)
    bezel = bezel or 4
    local ix, iy, iw, ih = x + bezel, y + bezel, w - 2 * bezel, h - 2 * bezel
    Kit.rect(ui, x, y, w, h, p.bezel)
    Kit.rect(ui, ix, iy, iw, ih, p.screen)
    Kit.rect(ui, ix + 2, iy + 2, iw - 4, 2, p.glare, Lcd.GLARE_ALPHA)
    return ix, iy, iw, ih
end

-- Plain text in the ink of the variant (or opts colour).
function Lcd.text(ui, s, x, y, variant, font, color)
    local k = ui.lwK or 1
    local c = color or palette(variant).ink
    ui:drawText(s, x * k, y * k, c[1], c[2], c[3], 1, font or Lcd.font())
end

-- One line shown in a box `avail` wide from x, clipped; a line too wide scrolls.
-- opts: font, now (ms), speed (units per second), pauseMs, color,
-- clip = { x, y, w, h } (default: the box avail wide, one font high).
function Lcd.line(ui, s, x, y, avail, variant, opts)
    opts = opts or {}
    local font = opts.font or Lcd.font()
    local k = ui.lwK or 1
    local speed = opts.speed or Lcd.SCROLL
    local offset = Lcd.scrollOffset(Lcd.measure(ui, font, s), avail, speed,
        opts.now or getTimestampMs(), opts.pauseMs)
    local c = opts.clip
    local cx, cy, cw, ch
    if c then cx, cy, cw, ch = c[1], c[2], c[3], c[4]
    else cx, cy, cw, ch = x, y, avail, Lcd.fontHeight(ui, font) end
    ui:setStencilRect(cx * k, cy * k, cw * k, ch * k)
    Lcd.text(ui, s, x - math.floor(offset), y, variant, font, opts.color)
    ui:clearStencilRect()
end

-- Gauge: a border and its fill at `fraction`, `gap` inside the border.
function Lcd.bar(ui, x, y, w, h, fraction, variant, gap)
    local ink = palette(variant).ink
    gap = gap or 2
    Kit.border(ui, x, y, w, h, ink)
    Kit.rect(ui, x + gap, y + gap, Lcd.fillWidth(fraction, w, gap), h - 2 * gap, ink)
end

-- One-unit rule across the screen (alpha a).
function Lcd.rule(ui, x, y, w, variant, a)
    Kit.rect(ui, x, y, w, 1, palette(variant).ink, a)
end

-- "Waiting for data" text.
function Lcd.waiting(ui, x, y, variant, font)
    Lcd.text(ui, getText("IGUI_LW_Waiting"), x, y, variant, font)
end

-- Screen of a bank or device window (layout L from DEVICE_BASE, window width W and height H).
-- Returns a function line(s, y) drawing one clipped, scrolling line.
function Lcd.deviceScreen(ui, L, W, H, variant, font, now)
    Lcd.frame(ui, L.lcdX, L.lcdY, W - 2 * L.lcdX, H - L.lcdBottom, variant, L.lcdInner)
    local clip = { L.clipX, L.clipY, W - L.clipRight, H - L.clipBottom }
    local avail = L.clipX + clip[3] - L.textX
    local opts = { font = font, now = now, speed = L.scroll, clip = clip }
    return function(s, y) Lcd.line(ui, s, L.textX, y, avail, variant, opts) end
end

-- Page indicator "page/count" at x.
function Lcd.page(ui, page, count, x, y, variant, font)
    Lcd.text(ui, tostring(page) .. "/" .. tostring(count), x, y, variant, font)
end
