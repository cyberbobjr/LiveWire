-- LiveWire Extended: window of a breaker board (D-36, E19, redrawn E23). The board is drawn
-- as it stands on the wall: 8, 16 or 24 modules in rows of 8 on DIN rails, each module
-- either an empty cover or the breaker installed there (front art rendered from the tile
-- model, LWX_UI_module_*.png), with its lever, its rating plate (colour and amps) and a label strip. Click an
-- empty module to install a breaker you carry there; click a lever to switch it (or reset
-- it after a trip); click a breaker to see its circuit below: load in W and A against its
-- rating, energy, wired appliances, and buttons Label, Locate, twilight switch, Remove.
-- A breaker dragged from the inventory onto an empty module installs it there (the free
-- modules light up while dragging); the click menu stays for gamepad players.
-- Every size is in 1080p reference pixels times the window factor of LW_UIScale (4K
-- screens, large font option), set once when the window opens.
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

-- Layout in 1080p reference pixels (multiplied by lwK).
local MOD_W, MOD_H, GAP = 48, 112, 4
local LABEL_H, ROW_GAP, PAD, HEAD_H = 18, 12, 18, 34
local DETAIL_H, BTN_H = 156, 26
local ROW_W = 8 * MOD_W + 7 * GAP
local WIN_W = ROW_W + 2 * PAD + 2 * 22
local TEX = {}
for _, state in ipairs({ "on", "off", "tripped", "empty" }) do
    TEX[state] = getTexture("media/textures/LWX_UI_module_" .. state .. ".png")
end
-- Rating plate: colour of the rating, its amps printed on it (text colour readable on it).
local RATING = { [15] = { 0.20, 0.45, 0.95 }, [20] = { 0.95, 0.80, 0.15 }, [30] = { 0.25, 0.75, 0.35 } }
local RATING_TEXT = { [15] = { 1, 1, 1 } }
local C = { bg = { 0.10, 0.11, 0.12 }, box = { 0.78, 0.79, 0.77 }, boxEdge = { 0.42, 0.44, 0.46 },
    inner = { 0.62, 0.64, 0.63 }, rail = { 0.30, 0.31, 0.33 }, text = { 0.92, 0.92, 0.90 },
    dim = { 0.65, 0.67, 0.66 }, ok = { 0.45, 0.85, 0.50 }, warn = { 0.95, 0.70, 0.25 },
    bad = { 0.95, 0.35, 0.30 }, sel = { 1.0, 0.85, 0.25 }, hover = { 1, 1, 1 }, panel = { 0.16, 0.17, 0.18 },
    plate = { 0.95, 0.95, 0.92 } }

local function fontH() return getTextManager():getFontHeight(UIFont.Small) end

function Window:record()
    local sq = self.board and self.board:getSquare()
    return sq and X.Panel.recordAt(sq) or nil
end

local function queue(self, action)
    if luautils.walkAdj(self.player, self.board:getSquare()) then ISTimedActionQueue.add(action) end
end

local function slotState(slot)
    if slot.tripped then return "tripped" end
    if B.isOpen(slot) then return "off" end
    return "on"
end

-- ---------------------------------------------------------------- geometry (reference units)
function Window:rows() return math.max(1, math.floor((self.size or 8) / 8)) end

function Window:moduleRect(pos)
    local row, col = math.floor((pos - 1) / 8), (pos - 1) % 8
    return PAD + 22 + col * (MOD_W + GAP), HEAD_H + PAD + 14 + row * (MOD_H + LABEL_H + ROW_GAP)
end

function Window:detailTop() return HEAD_H + 2 * PAD + 14 + self:rows() * (MOD_H + LABEL_H + ROW_GAP) end

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

-- ---------------------------------------------------------------- drawing
function Window:rect(x, y, w, h, c, a)
    local k = self.lwK
    self:drawRect(x * k, y * k, w * k, h * k, a or 1, c[1], c[2], c[3])
end

function Window:border(x, y, w, h, c, a)
    local k = self.lwK
    self:drawRectBorder(x * k, y * k, w * k, h * k, a or 1, c[1], c[2], c[3])
end

function Window:text(s, x, y, c, w)
    local k = self.lwK
    if w then self:setStencilRect(x * k, y * k, w * k, fontH() + 4) end
    self:drawText(s, x * k, y * k, c[1], c[2], c[3], 1, UIFont.Small)
    if w then self:clearStencilRect() end
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
    local k = self.lwK
    self:text(getText("IGUI_LWX_BoardTitle", tostring(record.size), tostring(B.usedModules(record))), PAD, 10, C.text)
    local rows = self:rows()
    local bx, by = PAD, HEAD_H + PAD
    local bw, bh = ROW_W + 44, rows * (MOD_H + LABEL_H + ROW_GAP) + 14
    self:rect(bx, by, bw, bh, C.box)
    self:border(bx, by, bw, bh, C.boxEdge)
    self:rect(bx + 8, by + 6, bw - 16, bh - 12, C.inner)
    for r = 0, rows - 1 do
        local _, ry = self:moduleRect(r * 8 + 1)
        self:rect(bx + 14, ry + MOD_H / 2 - 9, bw - 28, 18, C.rail)
    end
    local hover = self:hit(self:getMouseX(), self:getMouseY())
    local dragged = self:draggedBreaker()
    local labelY = (LABEL_H - fontH() / k) / 2
    for pos = 1, record.size do
        local x, y = self:moduleRect(pos)
        local slot = B.slotAt(record, pos)
        local tex = TEX[slot and slotState(slot) or "empty"]
        if tex then self:drawTextureScaled(tex, x * k, y * k, MOD_W * k, MOD_H * k, 1, 1, 1, 1) end
        if slot then
            -- rating printed on the breaker, as on a real one
            local amps = slot.amps .. " A"
            local th = fontH() / k
            local tw = getTextManager():MeasureStringX(UIFont.Small, amps) / k
            self:rect(x + 4, y + MOD_H - th - 10, MOD_W - 8, th + 2, RATING[slot.amps] or C.plate)
            self:text(amps, x + (MOD_W - tw) / 2, y + MOD_H - th - 9, RATING_TEXT[slot.amps] or C.bg)
            if slot.twilight then self:rect(x + MOD_W - 12, y + 6, 7, 7, C.warn) end
            self:rect(x, y + MOD_H + 2, MOD_W, LABEL_H - 2, C.text)
            self:text(slot.label ~= "" and slot.label or tostring(pos), x + 2, y + MOD_H + 2 + labelY, C.bg, MOD_W - 4)
        else
            self:text(tostring(pos), x + MOD_W / 2 - 4, y + MOD_H + 2 + labelY, C.dim)
            if dragged then
                self:rect(x, y, MOD_W, MOD_H, C.ok, hover == pos and 0.45 or 0.15)
                self:border(x - 1, y - 1, MOD_W + 2, MOD_H + 2, C.ok, hover == pos and 1 or 0.6)
            end
        end
        if self.selected == pos then
            self:border(x - 2, y - 2, MOD_W + 4, MOD_H + 4, C.sel)
            self:border(x - 3, y - 3, MOD_W + 6, MOD_H + 6, C.sel)
        elseif hover == pos then
            self:border(x - 1, y - 1, MOD_W + 2, MOD_H + 2, C.hover, 0.7)
        end
    end
    self:renderDetails(record)
end

function Window:renderDetails(record)
    local top = self:detailTop()
    local x, w = PAD, WIN_W - 2 * PAD
    self:rect(x, top, w, DETAIL_H - 10, C.panel)
    local slot = self.selected and B.slotAt(record, self.selected)
    local line = fontH() / self.lwK + 4
    local y = top + 8
    if not slot then
        self:text(getText("IGUI_LWX_SelectHint"), x + 10, y, C.dim, w - 20)
        self:text(getText("IGUI_LWX_EmptyHint"), x + 10, y + line, C.dim, w - 20)
        return
    end
    local name = slot.label ~= "" and slot.label or getText("IGUI_LWX_ModuleName", tostring(slot.pos))
    if slot.twilight then name = getText("IGUI_LWX_TwilightTag", name) end
    self:text(name, x + 10, y, C.text, w / 2 - 10)
    local state = slotState(slot)
    local sc = state == "tripped" and C.bad or state == "off" and C.dim or C.ok
    self:text(getText("IGUI_LWX_State_" .. state), x + w / 2, y, sc, w / 2 - 10)
    y = y + line
    local cap = B.capacityW(slot)
    self:text(getText("IGUI_LWX_Rating", tostring(slot.amps), tostring(cap)), x + 10, y, C.dim, w - 20)
    y = y + line
    local load = slot.load or 0
    local frac = math.min(1, load / cap)
    self:rect(x + 10, y + 2, w - 20, 10, C.rail)
    self:rect(x + 10, y + 2, (w - 20) * frac, 10, frac > 0.9 and C.bad or frac > 0.7 and C.warn or C.ok)
    y = y + 16
    self:text(getText("IGUI_LWX_LoadLine", tostring(load), string.format("%.1f", B.amps(slot)),
        tostring(#B.pointList(slot))), x + 10, y, C.text, w - 20)
    y = y + line
    local m = B.meterSummary(slot)
    self:text(getText("IGUI_LWX_Meter", string.format("%.1f", m.today), string.format("%.1f", m.yesterday),
        string.format("%.1f", m.week)), x + 10, y, C.dim, w - 20)
end

-- ---------------------------------------------------------------- actions
local BUTTONS = { "lever", "label", "locate", "twilight", "remove" }

function Window:refreshButtons(record)
    local slot = self.selected and B.slotAt(record, self.selected)
    for _, key in ipairs(BUTTONS) do self.btn[key]:setVisible(slot ~= nil) end
    if not slot then return end
    local state = slotState(slot)
    self.btn.lever:setTitle(getText(state == "tripped" and "IGUI_LWX_LeverReset" or slot.off and "IGUI_LWX_LeverSwitchOn"
        or "IGUI_LWX_LeverSwitchOff"))
    self.btn.locate:setTitle(getText(self.locating == slot.pos and "IGUI_LWX_LocateOff" or "IGUI_LWX_Locate"))
    self.btn.twilight:setTitle(getText(slot.twilight and "IGUI_LWX_TwilightRemoveBtn" or "IGUI_LWX_TwilightFitBtn"))
    self.btn.twilight.enable = slot.twilight == true or LiveWire.API.countType(self.player, B.TWILIGHT_ITEM) > 0
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
    local k = self.lwK
    local c = ISButton:new((WIN_W - PAD - 26) * k, 8 * k, 26 * k, 22 * k, "X", self, Window.close)
    c:initialise()
    self:addChild(c)
    self.btn = {}
    local top = self:detailTop() + DETAIL_H - 10 - BTN_H - 8
    local fns = { lever = Window.onLever, label = Window.onLabel, locate = Window.onLocate,
        twilight = Window.onTwilight, remove = Window.onRemove }
    local titles = { lever = "IGUI_LWX_LeverSwitchOff", label = "IGUI_LWX_Rename", locate = "IGUI_LWX_Locate",
        twilight = "IGUI_LWX_TwilightFitBtn", remove = "IGUI_LWX_Remove" }
    local bw = (WIN_W - 2 * PAD - 20 - 4 * 6) / 5
    for i, key in ipairs(BUTTONS) do
        local b = ISButton:new((PAD + 10 + (i - 1) * (bw + 6)) * k, top * k, bw * k, BTN_H * k, getText(titles[key]),
            self, fns[key])
        b:initialise()
        b:setVisible(false)
        self:addChild(b)
        self.btn[key] = b
    end
end

function Window:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.backgroundColor = { r = C.bg[1], g = C.bg[2], b = C.bg[3], a = 0.96 }
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
    local rows = math.max(1, math.floor(size / 8))
    local h = HEAD_H + 2 * PAD + 14 + rows * (MOD_H + LABEL_H + ROW_GAP) + DETAIL_H
    local UI = LiveWire.UIScale
    local k = UI.factor(WIN_W, h)
    local x, y, w, hh = UI.fit(getPlayerScreenLeft(player:getPlayerNum()) + 120,
        getPlayerScreenTop(player:getPlayerNum()) + 60, UI.px(WIN_W, k), UI.px(h, k))
    local win = Window:new(x, y, w, hh)
    win.lwK, win.player, win.board, win.size = k, player, board, size
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
