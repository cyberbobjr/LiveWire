-- LiveWire Extended: window of a breaker board (D-36, E19, redrawn E23, D-54). The board is drawn
-- with the enclosure kit of Live Wire (LiveWire.Enclosure, obtained from LiveWire.API): the same
-- enclosure, lid and LCD block as the Live Wire breaker window, 8, 16 or 24 modules in rows of 8
-- on DIN rails, each module drawn with its lever, its calibre plate (15 A blue, 20 A yellow,
-- 30 A green) and a label strip. Click an empty module to install a breaker you carry there;
-- click a lever to switch it (or reset it after a trip); click a breaker to see its circuit on
-- the LCD: load in W and A against its rating, energy, and buttons Label, Locate, twilight
-- switch, Remove. A breaker dragged from the inventory onto an empty module installs it there
-- (the free modules light up while dragging); the click menu stays for gamepad players.
-- Every size is in 1080p reference pixels times the window factor of LW_UIScale, computed when the
-- window opens (two passes, R2); the window goes compact (no lid) when it does not fit the height.
-- Reads the public table only; every change is a timed action checked on the authority.
-- Locate lights the appliances once (persistent highlight), no per-frame hook.
if isServer() then return end
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextBox"
require "ISUI/ISContextMenu"
require "ISUI/ISInventoryPane"
require "LiveWire/LW_UIScale"
require "LiveWireExtended/LWX_Points"

local X = LiveWire.Extended
local B = X.Breakers
local Window = ISPanel:derive("LWXBoardWindow")
X.BoardWindow = Window

-- The drawing kit of Live Wire (D-54), read through the API when a window opens.
local function kit() return LiveWire.API.enclosure() end

-- Module and rail geometry in 1080p reference pixels (multiplied by lwK).
local MOD_W, MOD_H, GAP = 48, 112, 4
local LABEL_GAP, ROW_GAP = 4, 12
local DRAG_GREEN = { 0.45, 0.85, 0.50 }

local BUTTONS = { "lever", "label", "locate", "twilight", "remove" }
local TITLES = { lever = "IGUI_LWX_LeverSwitchOff", label = "IGUI_LWX_Rename", locate = "IGUI_LWX_Locate",
    twilight = "IGUI_LWX_TwilightFitBtn", remove = "IGUI_LWX_Remove" }
-- Every title a button can show: the grid's column width must hold the widest one (R5).
local ALL_TITLES = { "IGUI_LWX_LeverReset", "IGUI_LWX_LeverSwitchOn", "IGUI_LWX_LeverSwitchOff",
    "IGUI_LWX_Rename", "IGUI_LWX_Locate", "IGUI_LWX_LocateOff", "IGUI_LWX_TwilightRemoveBtn",
    "IGUI_LWX_TwilightFitBtn", "IGUI_LWX_Remove" }
-- Help text shown while no breaker is selected (both lines, the window size keeps them).
local HELP_KEYS = { "IGUI_LWX_SelectHint", "IGUI_LWX_EmptyHint" }
local LCD_KEYS = { "IGUI_LWX_LcdLoad", "IGUI_LWX_LcdCurrent", "IGUI_LWX_LcdToday" }
local LCD_MIN_W = 246

local function slotState(slot)
    if slot.tripped then return "tripped" end
    if B.isOpen(slot) then return "off" end
    return "on"
end

local function queue(self, action)
    if luautils.walkAdj(self.player, self.board:getSquare()) then ISTimedActionQueue.add(action) end
end

local function kwh(v) return string.format("%.1f kWh", v) end

-- Layout of the window for a board of `size` modules at factor k, reference units. Returns the
-- kit's layout (L) and the grid origin, its height and the LCD width.
local function layoutAt(k, size, compact)
    local K = kit()
    local tm = getTextManager()
    local fr = tm:getFontHeight(UIFont.Small) / k
    local fmr = tm:getFontHeight(UIFont.Medium) / k
    local measure = K.measureAt(k, UIFont.Small)
    -- The LCD rows are drawn in the screen font of the kit (D-56).
    local fl = tm:getFontHeight(K.lcdFont()) / k
    local screen = K.measureAt(k, K.lcdFont())
    local lsH = math.max(23, math.ceil(fr + 4))
    local rows = math.max(1, math.floor(size / 8))
    local gridW = 8 * MOD_W + 7 * GAP
    local gridH = rows * (MOD_H + LABEL_GAP + lsH) + (rows - 1) * ROW_GAP
    local lcdW = LCD_MIN_W
    for i = 1, #LCD_KEYS do
        local second = i == 1 and getText("IGUI_LW_BoardCutWatts") or i == 2 and "99.9 / 30 A" or "99.9 kWh"
        lcdW = math.max(lcdW, math.ceil(screen(getText(LCD_KEYS[i])) + screen(second) + 52))
    end
    lcdW = math.max(lcdW, math.ceil(measure(getText("IGUI_LWX_Rating", "30", "3600")) + 44))
    local widest = 0
    for _, key in ipairs(ALL_TITLES) do widest = math.max(widest, measure(getText(key))) end
    local spec = { fr = fr, fmr = fmr, fl = fl, compact = compact, lcdW = lcdW, gridW = gridW, gridH = gridH,
        buttons = { count = #BUTTONS, widest = widest + 24 } }
    spec.hintLines = 0
    local base = K.layout(spec)
    local lines = 0
    for _, key in ipairs(HELP_KEYS) do lines = lines + #K.wrap(getText(key), base.inW, measure) end
    spec.hintLines = lines
    local L = K.layout(spec)
    L.lsH, L.rows, L.gridW, L.gridH, L.lcdW = lsH, rows, gridW, gridH, lcdW
    L.gx = L.recessX + 14 + lcdW + 20
    L.gy = L.recessY + 14 + math.floor((L.innerH - gridH) / 2)
    L.helpKeys = HELP_KEYS
    return L
end

function Window:record()
    local sq = self.board and self.board:getSquare()
    return sq and X.Panel.recordAt(sq) or nil
end

-- Module at position `pos` (top-left of its breaker body, reference units).
function Window:moduleRect(pos)
    local L = self.L
    local row, col = math.floor((pos - 1) / 8), (pos - 1) % 8
    return L.gx + col * (MOD_W + GAP), L.gy + row * (MOD_H + LABEL_GAP + L.lsH + ROW_GAP)
end

-- Module under the local point (mx, my) in pixels, and whether it is on its lever half.
function Window:hit(mx, my)
    local k = self.lwK
    for pos = 1, self.size or 8 do
        local x, y = self:moduleRect(pos)
        if mx >= x * k and mx < (x + MOD_W) * k and my >= y * k and my < (y + MOD_H) * k then
            return pos, (my - y * k) < MOD_H * k * 0.5
        end
    end
end

function Window:prerender()
    ISPanel.prerender(self)
    local record = self:record()
    if not record then self:close(); return end
    self.size = record.size or 8
    if self.selected and not B.slotAt(record, self.selected) then self.selected = nil end
    self:refreshButtons(record)
    self:drawBoard(record)
end

-- Drawn in prerender: the game renders the children (buttons) between prerender and
-- render, so anything drawn in render would cover them.
function Window:drawBoard(record)
    local K, L = kit(), self.L
    local C = K.C
    K.frame(self, L, getText("IGUI_LWX_BoardTitle", tostring(record.size), tostring(B.usedModules(record))),
        getText("IGUI_LW_BoardBrand"))
    for r = 0, L.rows - 1 do
        local _, ry = self:moduleRect(r * 8 + 1)
        K.rect(self, L.gx - 6, ry + MOD_H / 2 - 13, L.gridW + 12, 26, C.rail)
        K.border(self, L.gx - 6, ry + MOD_H / 2 - 13, L.gridW + 12, 26, C.light)
    end
    local hover = self:hit(self:getMouseX(), self:getMouseY())
    local dragged = self:draggedBreaker()
    local fr = K.fontHeight(self, UIFont.Small)
    for pos = 1, record.size do
        local x, y = self:moduleRect(pos)
        local slot = B.slotAt(record, pos)
        if slot then
            K.module(self, x, y, slotState(slot), K.RATING[slot.amps], false)
            K.plate(self, x, y, slot.amps, K.RATING[slot.amps], K.RATING_TEXT[slot.amps] or C.plateText)
            if slot.twilight then K.rect(self, x + MOD_W - 12, y + 13, 7, 7, C.orange) end
            K.rect(self, x, y + MOD_H + LABEL_GAP, MOD_W, L.lsH, C.light)
            K.border(self, x, y + MOD_H + LABEL_GAP, MOD_W, L.lsH, C.edge)
            K.text(self, slot.label ~= "" and slot.label or tostring(pos), x + 3,
                y + MOD_H + LABEL_GAP + (L.lsH - fr) / 2, MOD_W - 6, C.ink, UIFont.Small, "center")
        else
            K.module(self, x, y, "empty")
            K.rect(self, x, y + MOD_H + LABEL_GAP, MOD_W, L.lsH, C.light, 0.6)
            K.border(self, x, y + MOD_H + LABEL_GAP, MOD_W, L.lsH, C.edge, 0.6)
            K.text(self, tostring(pos), x + 3, y + MOD_H + LABEL_GAP + (L.lsH - fr) / 2, MOD_W - 6, C.edge,
                UIFont.Small, "center")
            if dragged then
                K.rect(self, x, y, MOD_W, MOD_H, DRAG_GREEN, hover == pos and 0.45 or 0.15)
                K.border(self, x - 1, y - 1, MOD_W + 2, MOD_H + 2, DRAG_GREEN, hover == pos and 1 or 0.6)
            end
        end
        if self.selected == pos then
            K.border(self, x - 2, y - 2, MOD_W + 4, MOD_H + 4, C.orange)
            K.border(self, x - 3, y - 3, MOD_W + 6, MOD_H + 6, C.orange)
        elseif hover == pos then
            K.border(self, x - 1, y - 1, MOD_W + 2, MOD_H + 2, C.white, 0.7)
        end
    end
    K.lcd(self, L.recessX + 14, L.recessY + 14 + math.floor((L.innerH - L.lcdH) / 2), L.lcdW,
        self:lcdContent(record), L.fr)
    if not self.selected then
        local y = L.hintY
        for _, key in ipairs(L.helpKeys) do
            for _, line in ipairs(K.wrap(getText(key), L.inW, K.measureAt(self.lwK, UIFont.Small))) do
                K.text(self, line, L.inX, y, L.inW, C.ink)
                y = y + L.lineH
            end
        end
    end
    K.hintScrews(self, L)
end

-- Name of the network the board feeds (the grid name, as on Live Wire's breaker LCD), else the
-- generic network label. The name needs the inverter's snapshot: the window subscribes to it.
function Window:networkName(record)
    local name = record.inv and LiveWire.API.gridName(record.inv)
    if name == nil or name == "" then return getText("IGUI_LW_Network") end
    return name
end

-- Text and values of the LCD: the selected breaker, else the whole board.
function Window:lcdContent(record)
    local K = kit()
    local slot = self.selected and B.slotAt(record, self.selected)
    if not slot then
        local load, amps, today, yesterday, week = 0, 0, 0, 0, 0
        for pos = 1, record.size do
            local s = B.slotAt(record, pos)
            if s then
                local m = B.meterSummary(s)
                if slotState(s) == "on" then
                    load = load + (s.load or 0)
                    amps = amps + B.amps(s)
                end
                today, yesterday, week = today + m.today, yesterday + m.yesterday, week + m.week
            end
        end
        return { title = getText("IGUI_LW_BoardPowerTitle"),
            rows = { { getText(LCD_KEYS[1]), tostring(load) .. " W" },
                { getText(LCD_KEYS[2]), string.format("%.1f A", amps) },
                { getText(LCD_KEYS[3]), kwh(today) } },
            led = K.C.green, line = self:networkName(record),
            status = getText("IGUI_LWX_LcdCount", tostring(record.size), tostring(#(record.slots or {}))),
            strip = getText("IGUI_LWX_LcdHistory", string.format("%.1f", yesterday), string.format("%.1f", week)) }
    end
    local state = slotState(slot)
    local load = (slot.off or slot.tripped) and 0 or (slot.load or 0)
    local m = B.meterSummary(slot)
    local name = slot.label ~= "" and slot.label or getText("IGUI_LWX_ModuleName", tostring(slot.pos))
    if slot.twilight then name = getText("IGUI_LWX_TwilightTag", name) end
    local shownLoad = (load == 0 and state ~= "on") and getText("IGUI_LW_BoardCutWatts") or tostring(load) .. " W"
    return { title = string.upper(name),
        rows = { { getText(LCD_KEYS[1]), shownLoad },
            { getText(LCD_KEYS[2]), string.format("%.1f / %d A", load / slot.volts, slot.amps) },
            { getText(LCD_KEYS[3]), kwh(m.today) } },
        led = state == "on" and K.C.green or state == "tripped" and K.C.red or K.C.edge,
        line = getText("IGUI_LWX_State_" .. state),
        status = getText("IGUI_LWX_Rating", tostring(slot.amps), tostring(B.capacityW(slot))),
        strip = getText("IGUI_LWX_LcdHistory", string.format("%.1f", m.yesterday), string.format("%.1f", m.week)) }
end

-- ---------------------------------------------------------------- actions
function Window:titleOf(key, slot)
    if not slot then return getText(TITLES[key]) end
    if key == "lever" then
        local state = slotState(slot)
        return getText(state == "tripped" and "IGUI_LWX_LeverReset" or slot.off and "IGUI_LWX_LeverSwitchOn"
            or "IGUI_LWX_LeverSwitchOff")
    elseif key == "locate" then
        return getText(self.locating == slot.pos and "IGUI_LWX_LocateOff" or "IGUI_LWX_Locate")
    elseif key == "twilight" then
        return getText(slot.twilight and "IGUI_LWX_TwilightRemoveBtn" or "IGUI_LWX_TwilightFitBtn")
    end
    return getText(TITLES[key])
end

-- Buttons stay visible; without a selection they are greyed (the window keeps its size).
-- A title too long for its column is abbreviated, the full text in its tooltip (R3).
function Window:refreshButtons(record)
    local K, L = kit(), self.L
    local slot = self.selected and B.slotAt(record, self.selected)
    local measure = K.measureAt(self.lwK, UIFont.Small)
    for i, key in ipairs(BUTTONS) do
        local b = self.btn[key]
        local full = self:titleOf(key, slot)
        local shown = K.abbreviate(full, L.cells[i].w - 14, measure)
        b:setTitle(shown)
        b.tooltip = shown ~= full and full or nil
        K.setLook(b, slot ~= nil)
    end
    if slot then
        K.setLook(self.btn.twilight, slot.twilight == true or LiveWire.API.countType(self.player, B.TWILIGHT_ITEM) > 0)
    end
end

function Window:selectedSlot()
    local record = self:record()
    return record and self.selected and B.slotAt(record, self.selected) or nil
end

function Window:onLever()
    local slot = self:selectedSlot()
    if not slot then return end
    queue(self, LWXBreakerAction:new(self.player, self.board, nil, slot.pos, (slot.off or slot.tripped) and "on" or "off"))
end

function Window:onLabel()
    local slot, me = self:selectedSlot(), self
    if not slot then return end
    local box = ISTextBox:new(0, 0, 320, 140, getText("IGUI_LWX_LabelPrompt", tostring(slot.pos)), slot.label or "",
        nil, function(_, b)
            if b.internal == "OK" then
                queue(me, LWXBreakerAction:new(me.player, me.board, nil, slot.pos, "label", b.parent.entry:getText()))
            end
        end)
    box:initialise()
    box:addToUIManager()
    box.entry:setMaxTextLength(B.LABEL_MAX)
end

function Window:clearLocate()
    for _, o in ipairs(self.lit or {}) do
        if o:getObjectIndex() ~= -1 then o:setHighlighted(false) end
    end
    self.lit, self.locating = {}, nil
end

-- Light every appliance of breaker `pos` (all pieces of a multi-tile one, a room's switches).
function Window:locate(pos)
    local again = self.locating == pos
    self:clearLocate()
    if again then return end
    local record = self:record()
    local slot = record and B.slotAt(record, pos)
    if not slot then return end
    self.locating = pos
    for _, key in ipairs(B.pointList(slot)) do
        for _, found in ipairs(X.Points.objectsOf(key, X.Points.point(key))) do
            for _, o in ipairs(X.Adapters.find(found).pieces(found)) do
                if not o:isHighlighted() then
                    o:setHighlightColor(0.95, 0.75, 0.2, 1)
                    o:setHighlighted(true, false)
                    self.lit[#self.lit + 1] = o
                end
            end
        end
    end
end

function Window:onLocate()
    if self.selected then self:locate(self.selected) end
end

function Window:onTwilight()
    local slot = self:selectedSlot()
    if not slot then return end
    queue(self, LWXBreakerAction:new(self.player, self.board, nil, slot.pos, slot.twilight and "twilightOff" or "twilightOn"))
end

function Window:onRemove()
    local slot = self:selectedSlot()
    if not slot then return end
    queue(self, LWXBreakerAction:new(self.player, self.board, nil, slot.pos, "remove"))
    self.selected = nil
end

-- Empty module: the breakers the player carries, installed in that very module.
function Window:installMenu(pos)
    local menu = ISContextMenu.get(self.player:getPlayerNum(), getMouseX(), getMouseY())
    menu:addOption(getText("IGUI_LWX_InstallHere", tostring(pos)), nil, nil).notAvailable = true
    for _, fullType in ipairs(B.ORDER) do
        local t = B.TYPES[fullType]
        local it = getScriptManager():FindItem(fullType)
        local count = LiveWire.API.countType(self.player, fullType)
        local o = menu:addOption(string.format("%s (%d)", it and it:getDisplayName() or fullType, count), self,
            function(win) queue(win, LWXBreakerAction:new(win.player, win.board, fullType, pos, nil)) end)
        local ok, why, arg = B.checkInstall(self.player, self.board, fullType, pos)
        local tip = ISWorldObjectContextMenu.addToolTip()
        if ok then
            tip.description = getText("Tooltip_LWX_BreakerRating", tostring(t.amps), tostring(t.volts), tostring(B.capacityW(t)))
        else
            tip.description = getText(why, arg)
            o.notAvailable = true
        end
        o.toolTip = tip
    end
    return menu
end

-- The breaker item being dragged from an inventory window, or nil.
function Window:draggedBreaker()
    local dragging = ISMouseDrag and ISMouseDrag.dragging
    if not dragging then return nil end
    for _, it in ipairs(ISInventoryPane.getActualItems(dragging)) do
        if B.TYPES[it:getFullType()] then return it end
    end
    return nil
end

-- Drop a dragged breaker on an empty module: install it there.
function Window:onMouseUp(x, y)
    local item = self:draggedBreaker()
    if not item then return ISPanel.onMouseUp(self, x, y) end
    local num = self.player:getPlayerNum()
    getPlayerInventory(num).render3DItems = {}
    getPlayerLoot(num).render3DItems = {}
    local pos = self:hit(x, y)
    local record = self:record()
    if pos and record and B.moduleFree(record, pos) then
        local ok, why, arg = B.checkInstall(self.player, self.board, item:getFullType(), pos)
        if ok then
            queue(self, LWXBreakerAction:new(self.player, self.board, item:getFullType(), pos, nil))
        else
            self.player:Say(getText(why, arg))
        end
    end
    return true
end

function Window:onMouseDown(x, y)
    local pos, onLever = self:hit(x, y)
    if not pos then return ISPanel.onMouseDown(self, x, y) end
    local record = self:record()
    local slot = record and B.slotAt(record, pos)
    if not slot then
        self.selected = nil
        self:installMenu(pos)
        return true
    end
    self.selected = slot.pos
    if onLever then self:onLever() end
    return true
end

function Window:close()
    self:clearLocate()
    self:setVisible(false)
    self:removeFromUIManager()
    if Window.instance == self then Window.instance = nil end
end

function Window:createChildren()
    ISPanel.createChildren(self)
    local K, L = kit(), self.L
    LiveWire.UIKit.button(self, L.W - 14 - L.closeS, (L.headH - L.closeS) / 2, L.closeS, L.closeS, "x",
        Window.close, "close", self.lwK)
    self.btn = {}
    local fns = { lever = Window.onLever, label = Window.onLabel, locate = Window.onLocate,
        twilight = Window.onTwilight, remove = Window.onRemove }
    for i, key in ipairs(BUTTONS) do
        self.btn[key] = K.cellButton(self, L, i, getText(TITLES[key]), fns[key], key)
    end
end

function Window:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.backgroundColor = { r = 0.10, g = 0.11, b = 0.12, a = 0.96 }
    o.borderColor = { r = 0.45, g = 0.47, b = 0.50, a = 1 }
    o.moveWithMouse = true
    o.lit = {}
    return o
end

function Window.open(player, board)
    if Window.instance then Window.instance:close() end
    local sq = board:getSquare()
    local record = sq and X.Panel.recordAt(sq)
    local size = record and record.size or X.Panel.size(board) or 8
    local UI = LiveWire.UIScale
    local K = kit()
    local k = K.twoPass(function(kk)
        local L = layoutAt(kk, size, false)
        return L.W, L.H
    end, UI.factor, UI.fontScale())
    local core = getCore()
    local compact = K.needsCompact(layoutAt(k, size, false).H, k, core:getScreenHeight(), UI.MARGIN)
    local L = layoutAt(k, size, compact)
    local x, y, w, h = UI.fit(getPlayerScreenLeft(player:getPlayerNum()) + 120,
        getPlayerScreenTop(player:getPlayerNum()) + 60, UI.px(L.W, k), UI.px(L.H, k))
    local win = Window:new(x, y, w, h)
    win.lwK, win.player, win.board, win.size, win.L = k, player, board, size, L
    if record and record.inv then LiveWire.API.subscribeInverter(record.inv) end
    win:initialise()
    win:addToUIManager()
    Window.instance = win
    return win
end

-- Inverter software, House tab (Live Wire hook): energy of each breaker of the boards
-- linked to this inverter.
local function softwareLines(inverterId)
    local out = {}
    for _, r in pairs(X.Data.table().panels or {}) do
        if tostring(r.inv) == tostring(inverterId) then
            for _, slot in ipairs(r.slots or {}) do
                local m = B.meterSummary(slot)
                local name = slot.label ~= "" and slot.label or getText("IGUI_LWX_ModuleName", tostring(slot.pos))
                out[#out + 1] = getText("IGUI_LWX_SoftwareMeter", name, string.format("%.1f", m.today),
                    string.format("%.1f", m.yesterday))
            end
        end
    end
    return out
end

LiveWire.API.registerSoftwareLines(softwareLines)
