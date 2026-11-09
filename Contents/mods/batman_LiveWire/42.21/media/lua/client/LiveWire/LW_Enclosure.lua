-- Live Wire: drawing kit of the enclosure windows (D-54). The breaker window of Live Wire and
-- the board window of LiveWire Extended both draw through it: cream enclosure with a smoked
-- lid and a manufacturer plate, the LCD block, drawn breakers with calibre plates, the button
-- grid. Sizes are in 1080p reference units; LW_UIKit draws them times the window factor `lwK`.
-- The pure functions (sizes, texts) carry no drawing and are tested offline.
-- Rules of the harmonisation plan: R1 heights from the real font, R2 two-pass size, R3 text
-- abbreviated with an ellipsis, R4 wrapped sentences, R5 equal button columns, R6 compact
-- window without lid, R7 calibre plate without its unit.
if isServer() then return end
require "LiveWire/LW_UIKit"

LiveWire = LiveWire or {}
local E = {}
LiveWire.Enclosure = E

local ELL = "\226\128\166"  -- the ellipsis, UTF-8

-- Palette of the enclosure (the same values as LW_BreakerPanel).
E.C = { white = { 0.87, 0.87, 0.82 }, light = { 0.96, 0.95, 0.90 }, edge = { 0.48, 0.51, 0.50 },
    shadow = { 0.26, 0.29, 0.29 }, ink = { 0.14, 0.19, 0.20 }, rail = { 0.49, 0.54, 0.54 },
    handle = { 0.25, 0.29, 0.31 }, orange = { 0.93, 0.51, 0.13 }, green = { 0.29, 0.59, 0.36 },
    red = { 0.74, 0.25, 0.20 }, glass = { 0.30, 0.43, 0.46 }, lcd = { 0.49, 0.61, 0.35 },
    brandRed = { 0.94, 0.20, 0.25 }, brandBlack = { 0.03, 0.03, 0.03 }, brandWhite = { 1, 1, 1 },
    bg = { 0.11, 0.15, 0.17 }, plateText = { 0.10, 0.11, 0.12 } }

-- Calibre bands and plates (15 A blue, 20 A yellow, 30 A green); the 15 A plate has white text.
E.RATING = { [15] = { 0.20, 0.45, 0.95 }, [20] = { 0.95, 0.80, 0.15 }, [30] = { 0.25, 0.75, 0.35 } }
E.RATING_TEXT = { [15] = { 1, 1, 1 } }

local MOD_W, MOD_H, MOD_GAP = 48, 112, 4
E.MODULE = { w = MOD_W, h = MOD_H, gap = MOD_GAP }

-------------------------------------------------------------------------------
-- Pure functions (reference units; `measure(s)` gives the width of s in reference units)
-------------------------------------------------------------------------------

-- R1: height of a row that carries text: the reference, or the real font height / k plus a margin.
function E.textHeight(ref, fontPx, k, margin)
    return math.max(ref, math.ceil(fontPx / k + margin))
end

-- R5: number of equal button columns, 5 then 3, 2, 1: the widest title must fit in a column.
function E.columns(avail, widest, gap)
    local choices = { 5, 3, 2 }
    for i = 1, #choices do
        local c = choices[i]
        if (avail - (c - 1) * gap) / c >= widest then return c end
    end
    return 1
end

-- Byte positions where a UTF-8 character ends.
local function charEnds(s)
    local ends = {}
    for i = 1, #s do
        local nxt = string.byte(s, i + 1)
        if nxt == nil or nxt < 128 or nxt >= 192 then ends[#ends + 1] = i end
    end
    return ends
end

-- R3: `s` unchanged when it fits in maxW, else its longest whole-character prefix (trailing
-- spaces removed) followed by an ellipsis.
function E.abbreviate(s, maxW, measure)
    if measure(s) <= maxW then return s end
    local ends = charEnds(s)
    for i = #ends, 1, -1 do
        local head = (string.gsub(string.sub(s, 1, ends[i]), "%s+$", ""))
        local candidate = head .. ELL
        if measure(candidate) <= maxW then return candidate end
    end
    return ELL
end

-- R4: words wrapped into lines of at most maxW; a line too long for one word is abbreviated (R3).
function E.wrap(s, maxW, measure)
    local lines, cur = {}, nil
    for word in string.gmatch(s, "%S+") do
        local try = cur and (cur .. " " .. word) or word
        if cur == nil or measure(try) <= maxW then
            cur = try
        else
            lines[#lines + 1] = cur
            cur = word
        end
    end
    if cur then lines[#lines + 1] = cur end
    for i = 1, #lines do lines[i] = E.abbreviate(lines[i], maxW, measure) end
    return lines
end

-- R7: "30 A" on the plate, then "30" when the plate is too narrow.
function E.plateText(amps, maxW, measure)
    local full = tostring(amps) .. " A"
    if measure(full) <= maxW then return full end
    return E.abbreviate(tostring(amps), maxW, measure)
end

-- R2: sizeAt(k) gives w, h of the content drawn at scale k; factorFor(w, h) gives the window
-- factor (LW_UIScale.factor). Content at scale 1, then its factor, then the content at that
-- factor; if the window no longer fits at that factor, the factor is lowered once more.
-- k0 (optional, 1 by default): the scale the content is first measured at, the font scale
-- for a window whose text is drawn at the real font height; the text then keeps its
-- reference height (font / k0) in the first pass.
function E.twoPass(sizeAt, factorFor, k0)
    local k = factorFor(sizeAt(k0 or 1))
    local w, h = sizeAt(k)
    local k2 = factorFor(w, h)
    if k2 < k then
        k = k2
        w, h = sizeAt(k)
    end
    return k, w, h
end

-- R6: the full window (lid included) does not fit the screen height at scale k.
function E.needsCompact(fullH, k, screenH, margin)
    return fullH * k > screenH - 2 * margin
end

-- R5: `count` buttons of height h in `cols` equal columns between x = left and x = right.
-- Returns the cells { x, y, w, h } (y from the top of the grid) and the grid height.
function E.grid(left, right, cols, gap, count, h, rowGap)
    local bw = (right - left - (cols - 1) * gap) / cols
    local cells = {}
    for i = 1, count do
        local c = (i - 1) % cols
        local r = math.floor((i - 1) / cols)
        cells[i] = { x = left + c * (bw + gap), y = r * (h + rowGap), w = bw, h = h }
    end
    local rows = math.ceil(count / cols)
    return cells, rows * h + (rows - 1) * rowGap
end

-- Height of the LCD block of Live Wire (the mockup's lcdBlock), its condition strip included.
-- fr: real font height / k.
function E.lcdHeight(fr)
    local lineH = math.max(25, math.ceil(fr + 6))
    local lcdTop = math.max(38, math.ceil(16 + fr + 3))
    local frameH = 3 * lineH + 11
    local ledY = lcdTop + frameH + 5
    local stY = ledY + math.max(21, math.ceil(fr + 2))
    local blockH = math.max(176, math.ceil(stY + fr + 7))
    local stripY = blockH + 11
    return stripY + math.max(29, math.ceil(fr + 10))
end

-- Geometry of the enclosure (mockup propA), reference units. p = {
--   fr, fmr        real font heights (regular, medium) / k,
--   compact        no lid,
--   lcdW, gridW, gridH   LCD width, breaker grid size,
--   hintLines      lines of the help text (already wrapped),
--   buttons        { count, widest } (widest: widest title + padding; count 1 = full width) }.
-- Returns W, H and the positions used by the drawing: encX, encY, encW, encH, lid, recessX,
-- recessY, recessW, recessH, innerH, lcdH, inX, inW, hintY, btnY, btnCols, btnRows, cells.
function E.layout(p)
    local fr, fmr = p.fr, p.fmr
    local headH = math.max(36, math.ceil(fmr + 14))
    local btnH = math.max(28, math.ceil(fr + 9))
    local lineH = math.ceil(fr + 4)
    local lid = p.compact and 0 or math.max(65, math.ceil(fmr + 42))
    local encX, encY = 14, headH + 6
    local recessY = encY + (lid > 0 and (11 + lid + 17) or 12)
    local lcdH = E.lcdHeight(fr)
    local innerH = math.max(p.gridH, lcdH)
    local recessX = encX + 23
    local recessW = 14 + p.lcdW + 20 + p.gridW + 14
    local recessH = innerH + 28
    local encW = recessW + 46
    local W = encW + 28
    local inX, inW = encX + 35, encW - 70
    local hintY = recessY + recessH + 10
    local count = p.buttons.count
    local cols = 1
    if count > 1 then cols = E.columns(inW, p.buttons.widest, 8) end
    local btnY = hintY + p.hintLines * lineH + 10
    local cells, gridH = E.grid(inX, inX + inW, cols, 8, count, btnH, 6)
    local encH = btnY + gridH + 14 - encY
    local H = encY + encH + 12
    return {
        W = W, H = H, headH = headH, encX = encX, encY = encY, encW = encW, encH = encH, lid = lid,
        recessX = recessX, recessY = recessY, recessW = recessW, recessH = recessH, innerH = innerH,
        lcdH = lcdH, inX = inX, inW = inW, hintY = hintY, btnY = btnY, btnCols = cols,
        btnRows = math.ceil(count / cols), cells = cells, lineH = lineH, btnH = btnH,
        closeS = math.max(22, math.ceil(fr + 5)), fr = fr, fmr = fmr,
    }
end

-------------------------------------------------------------------------------
-- Drawing (ui is an ISPanel; reference units, scaled by ui.lwK)
-------------------------------------------------------------------------------

local rect, border = LiveWire.UIKit.rect, LiveWire.UIKit.border
E.rect, E.border = rect, border

local function factorOf(ui) return ui.lwK or 1 end

-- Measure of a text in reference units for a font.
function E.measurer(ui, font)
    return E.measureAt(factorOf(ui), font)
end

-- The same measure for a window factor k, without a window (sizes are computed at opening).
function E.measureAt(k, font)
    local tm = getTextManager()
    return function(s) return tm:MeasureStringX(font, s) / k end
end

-- Reference height of a font.
function E.fontHeight(ui, font)
    return getTextManager():getFontHeight(font) / factorOf(ui)
end

-- Text drawn in the box x..x+w (w nil: no box). R3: abbreviated with an ellipsis when too long.
-- align: "left" (default), "center", "right". Returns the text drawn.
function E.text(ui, s, x, y, w, c, font, align)
    font = font or UIFont.Small
    local k = factorOf(ui)
    local shown = s
    if w then shown = E.abbreviate(s, w, E.measurer(ui, font)) end
    local xx = x
    if w and align and align ~= "left" then
        local tw = E.measurer(ui, font)(shown)
        xx = align == "right" and (x + w - tw) or (x + (w - tw) / 2)
    end
    ui:drawText(shown, xx * k, y * k, c[1], c[2], c[3], 1, font)
    return shown
end

-- Right-aligned text ending at x (no abbreviation: values are short).
function E.textRight(ui, s, x, y, c, font)
    local k = factorOf(ui)
    ui:drawTextRight(s, x * k, y * k, c[1], c[2], c[3], 1, font or UIFont.Small)
end

local function screw(ui, x, y)
    rect(ui, x + 2, y, 8, 12, E.C.edge)
    rect(ui, x, y + 2, 12, 8, E.C.edge)
    rect(ui, x + 2, y + 5, 8, 2, E.C.ink)
end
E.screw = screw

-- Colour plate with a text centred on a breaker's bottom (R7 text).
function E.plate(ui, x, y, text, col, tcol)
    local fh = E.fontHeight(ui, UIFont.Small)
    local s = E.plateText(text, MOD_W - 10, E.measurer(ui, UIFont.Small))
    rect(ui, x + 4, y + MOD_H - fh - 10, MOD_W - 8, fh + 2, col)
    E.text(ui, s, x + 5, y + MOD_H - fh - 9, MOD_W - 10, tcol, UIFont.Small, "center")
end

-- A drawn breaker of the 48 x 112 module: state "on", "off", "tripped" or "empty".
-- band: colour strip on top (calibre); main: the orange main lever.
function E.module(ui, x, y, state, band, main)
    local C = E.C
    rect(ui, x + 2, y + 3, MOD_W, MOD_H, C.shadow)
    rect(ui, x, y, MOD_W, MOD_H, state == "empty" and { 0.80, 0.81, 0.78 } or C.light)
    border(ui, x, y, MOD_W, MOD_H, C.edge)
    if state == "empty" then
        rect(ui, x + 12, y + 50, MOD_W - 24, 12, C.edge)
        return
    end
    rect(ui, x + 7, y + 6, MOD_W - 14, 4, band or C.edge)
    rect(ui, x + 19, y + 14, 10, 10, C.edge)
    rect(ui, x + 20, y + 18, 8, 2, C.ink)
    rect(ui, x + 14, y + 28, MOD_W - 28, 52, C.ink)
    local ty = state == "on" and y + 28 or state == "off" and y + 58 or y + 43
    rect(ui, x + 8, ty + 3, MOD_W - 16, 22, C.shadow)
    local lever = state == "tripped" and C.red or main and C.orange or C.handle
    rect(ui, x + 7, ty, MOD_W - 14, 21, lever)
    rect(ui, x + 7, ty, MOD_W - 14, 3, main and C.orange or C.edge)
    for i = 1, 3 do rect(ui, x + 11, ty + 9 + i * 3, MOD_W - 22, 1, C.ink, 0.5) end
end

-- Bar joining the levers of the poles of one circuit (n modules wide), at the lever state.
function E.tieBar(ui, x, y, n, state)
    local fy = state == "on" and 38 or state == "off" and 68 or 53
    rect(ui, x + 12, y + fy, n * MOD_W - 24, 4, E.C.ink)
end

-- LCD block at x, y, width w. d = { title, rows = { {label, value}, ... } (3 rows), led (colour),
-- line, status, statusC, strip }. Returns its height (E.lcdHeight of the font).
function E.lcd(ui, x, y, w, d, fr)
    local C = E.C
    local lineH = math.max(25, math.ceil(fr + 6))
    local titleY = 16
    local lcdTop = math.max(38, math.ceil(titleY + fr + 3))
    local frameH = 3 * lineH + 11
    local ledY = lcdTop + frameH + 5
    local stY = ledY + math.max(21, math.ceil(fr + 2))
    local blockH = math.max(176, math.ceil(stY + fr + 7))
    local stripY = blockH + 11
    local stripH = math.max(29, math.ceil(fr + 10))
    rect(ui, x, y, w, blockH, C.ink)
    rect(ui, x + 4, y + 4, w - 8, blockH - 8, C.white)
    border(ui, x + 7, y + 7, w - 14, blockH - 14, C.edge)
    E.text(ui, d.title, x + 17, y + titleY, w - 34, C.ink)
    rect(ui, x + 13, y + lcdTop, w - 24, frameH, C.ink)
    rect(ui, x + 16, y + lcdTop + 3, w - 30, frameH - 6, C.lcd)
    rect(ui, x + 18, y + lcdTop + 5, w - 34, 2, C.light, 0.16)
    for i, row in ipairs(d.rows) do
        local ry = y + lcdTop + 5 + (i - 1) * lineH + math.max(0, math.floor((lineH - fr) / 2))
        local measure = E.measurer(ui, UIFont.Small)
        local vw = measure(row[2])
        E.text(ui, row[1], x + 22, ry, w - 44 - vw - 8, C.ink)
        E.textRight(ui, row[2], x + w - 19, ry, C.ink)
        if i == 2 then rect(ui, x + 22, y + lcdTop + 5 + 2 * lineH - 1, w - 44, 1, C.ink, 0.25) end
    end
    rect(ui, x + 21, y + ledY + 6, 9, 5, d.led)
    E.text(ui, d.line, x + 38, y + ledY, w - 55, C.ink)
    E.text(ui, d.status, x + 21, y + stY, w - 40, d.statusC or C.ink)
    rect(ui, x + 4, y + stripY, w - 8, stripH, C.ink)
    rect(ui, x + 7, y + stripY + 3, w - 14, stripH - 6, C.lcd)
    E.text(ui, d.strip, x + 13, y + stripY + (stripH - fr) / 2, w - 26, C.ink)
    return blockH + 11 + stripH
end

-- Frame of the enclosure from layout L: background, header title (E.text, R3), lid with its
-- hinges and plate, recess. The caller draws the close button, the LCD, the modules and the
-- buttons. title: header text; brand: text of the manufacturer plate.
function E.frame(ui, L, title, brand)
    local C = E.C
    local fr = E.fontHeight(ui, UIFont.Small)
    local fmr = E.fontHeight(ui, UIFont.Medium)
    rect(ui, 0, 0, L.W, L.H, C.bg, 0.99)
    border(ui, 1, 1, L.W - 2, L.H - 2, C.edge)
    ui:drawText("LIVE WIRE", 19 * factorOf(ui), (L.headH - fmr) / 2 * factorOf(ui), C.white[1], C.white[2], C.white[3], 1, UIFont.Medium)
    local tx = math.max(181, 19 + E.measurer(ui, UIFont.Medium)("LIVE WIRE") + 16)
    E.text(ui, title, tx, (L.headH - fr) / 2 + 1, L.W - tx - 60, C.white)
    local encX, encY, encW, encH = L.encX, L.encY, L.encW, L.encH
    rect(ui, encX - 4, encY + 4, encW + 8, encH, C.shadow)
    rect(ui, encX, encY, encW, encH, C.white)
    border(ui, encX, encY, encW, encH, C.edge)
    if L.lid > 0 then
        local lx, ly, lw = encX + 11, encY + 11, encW - 22
        rect(ui, lx, ly, lw, L.lid, C.glass, 0.82)
        border(ui, lx, ly, lw, L.lid, C.ink)
        rect(ui, lx + 6, ly + 4, lw - 12, 7, C.light, 0.25)
        rect(ui, lx + 11, ly + 13, lw - 22, 2, C.light, 0.15)
        rect(ui, encX + encW / 2 - 34, encY + 6, 68, 13, C.edge)
        rect(ui, encX + encW / 2 - 29, encY + 7, 58, 6, C.white)
        for _, x in ipairs({ encX + 17, encX + encW - 29 }) do
            rect(ui, x, encY + 52, 12, 36, C.ink)
            rect(ui, x + 3, encY + 54, 6, 29, C.edge)
        end
        local ph = math.max(30, math.ceil(fmr + 7))
        local pw = math.max(166, math.ceil(E.measurer(ui, UIFont.Medium)(brand) + 44))
        local px = encX + encW - pw - 24
        local py = ly + math.max(23, math.floor((L.lid - ph) / 2))
        rect(ui, px, py, pw, ph, C.brandWhite)
        border(ui, px, py, pw, ph, C.brandBlack)
        rect(ui, px + 8, py + 7, 4, ph - 14, C.brandBlack)
        ui:drawText(brand, (px + 22) * factorOf(ui), (py + (ph - fmr) / 2) * factorOf(ui),
            C.brandRed[1], C.brandRed[2], C.brandRed[3], 1, UIFont.Medium)
    end
    rect(ui, L.recessX, L.recessY, L.recessW, L.recessH, C.shadow)
    rect(ui, L.recessX + 5, L.recessY + 5, L.recessW - 10, L.recessH - 11, C.edge)
end

-- Screws of the hint line, as in Live Wire's enclosure.
function E.hintScrews(ui, L)
    screw(ui, L.encX + 10, L.hintY)
    screw(ui, L.encX + L.encW - 22, L.hintY)
end

-- Button of cell `index` of the layout's grid (L.cells: x absolute, y from L.btnY), styled as the
-- mockup's buttons (black fill, light border, white title). Scaled through LW_UIKit.button.
function E.cellButton(ui, L, index, title, onclick, internal)
    local cell = L.cells[index]
    local b = LiveWire.UIKit.button(ui, cell.x, L.btnY + cell.y, cell.w, cell.h, title, onclick, internal, ui.lwK)
    b.displayBackground = true
    b.backgroundColor = { r = 0, g = 0, b = 0, a = 0.85 }
    b.borderColor = { r = 0.7, g = 0.7, b = 0.7, a = 1 }
    b.textColor = { r = 1, g = 1, b = 1, a = 1 }
    return b
end

-- Enabled or greyed button (the mockup's dim state: a fainter border, the title greyed).
function E.setLook(b, enabled)
    b:setEnable(enabled)
    b.borderColor.a = enabled and 1 or 0.4
end
