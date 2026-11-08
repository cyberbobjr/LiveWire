-- Live Wire: front panel of the inverter, drawn as a device: a backlit LCD screen
-- with pages (previous / next), an on/off button with its indicator light and a
-- reset button when the inverter has tripped. Same data as the management
-- software (snapshot of the inverter); the full view is the computer
-- (LW_SoftwareApp.lua). Commands are re-checked by the server.
if isServer() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "LiveWire/LW_UIScale"

LiveWire = LiveWire or {}

local Panel = ISPanel:derive("LiveWireInverterPanel")
LiveWire.InverterPanel = Panel
Panel.instance = nil

-- Sizes at the 1080p reference font, scaled once per window (LW_UIScale.lua).
local BASE = {
    w = 440, h = 300, lcdX = 18, lcdY = 40, lcdW = 404, lcdH = 138,
    bezel = 4, pad = 8, top = 6, clip = 6, bottom = 6, sep = 4,
    btnY = 16, btnH = 30, arrowW = 40, nextX = 46, resetX = 100, resetW = 70, powerW = 74, side = 18,
    closeS = 18, closeX = 26, closeY = 6, linksY = 254, linksH = 28, brandX = 14, brandY = 10,
    reserve = 44, pageX = 34, barX = 60, barRight = 72, barPad = 20, barInset = 3, barGap = 2,
    led = 12, ledX = 18, ledY = 9,
    scroll = 40,   -- px/s: lines wider than the screen scroll back and forth
}
Panel.BASE = BASE
-- Unscaled layout until a window is opened (instances made without open()).
Panel.L = LiveWire.UIScale.layout(1, BASE)
local SCROLL_PAUSE_MS = 1200
local RESUBSCRIBE_MS = 60 * 1000
local CLOSE_RANGE = 30
local PAGES = 5

local function T(key, ...) return getText(key, ...) end

local function lcdFont()
    return LiveWire.Client.lcdFont()
end

function Panel.open(player, inverterId, obj)
    if Panel.instance then Panel.instance:close() end
    local L = LiveWire.UIScale.layout(LiveWire.UIScale.factor(BASE.w, BASE.h), BASE)
    local x, y = LiveWire.UIScale.fit(getPlayerScreenLeft(player:getPlayerNum()) + 120,
        getPlayerScreenTop(player:getPlayerNum()) + 100, L.w, L.h)
    local p = Panel:new(x, y, player, inverterId, L)
    p.obj = obj
    p:initialise()
    p:addToUIManager()
    p:setVisible(true)
    Panel.instance = p
end

function Panel:new(x, y, player, inverterId, L)
    L = L or Panel.L
    local o = ISPanel:new(x, y, L.w, L.h)
    setmetatable(o, self)
    self.__index = self
    o.L = L
    o.player = player
    o.inverterId = inverterId
    o.page = 1
    o.lastSubscribe = 0
    o.moveWithMouse = true
    o.backgroundColor = { r = 0.20, g = 0.21, b = 0.22, a = 0.97 }
    o.borderColor = { r = 0.45, g = 0.47, b = 0.50, a = 1 }
    return o
end

local function button(self, x, y, w, h, label, internal)
    local b = ISButton:new(x, y, w, h, label, self, Panel.onButton)
    b.internal = internal
    b:initialise()
    b:instantiate()
    b.backgroundColor = { r = 0.12, g = 0.12, b = 0.13, a = 1 }
    b.backgroundColorMouseOver = { r = 0.25, g = 0.25, b = 0.27, a = 1 }
    b.borderColor = { r = 0.55, g = 0.57, b = 0.6, a = 1 }
    self:addChild(b)
    return b
end

function Panel:createChildren()
    ISPanel.createChildren(self)
    local L = self.L
    local by = L.lcdY + L.lcdH + L.btnY
    self.prevBtn = button(self, L.lcdX, by, L.arrowW, L.btnH, "<", "PREV")
    self.nextBtn = button(self, L.lcdX + L.nextX, by, L.arrowW, L.btnH, ">", "NEXT")
    self.resetBtn = button(self, L.lcdX + L.resetX, by, L.resetW, L.btnH, "RESET", "RESET")
    self.powerBtn = button(self, L.w - L.side - L.powerW, by, L.powerW, L.btnH, "I / O", "POWER")
    self.closeBtn = button(self, L.w - L.closeX, L.closeY, L.closeS, L.closeS, "x", "CLOSE")
    button(self, L.lcdX, L.linksY, L.lcdW, L.linksH, T("IGUI_LW_Connections"), "LINKS")
end

function Panel:snapshot()
    return LiveWire.Client.snapshot(self.inverterId)
end

function Panel:onButton(b)
    local P = LiveWire.Protocol
    if b.internal == "PREV" then
        self.page = (self.page - 2) % PAGES + 1
    elseif b.internal == "NEXT" then
        self.page = self.page % PAGES + 1
    elseif b.internal == "POWER" then
        local snap = self:snapshot()
        local on = snap and snap.inverter.state == "off" or false
        LiveWire.Client.send(P.C_SET_INVERTER, { inverter = self.inverterId, on = on })
        self.lastSubscribe = 0
    elseif b.internal == "RESET" then
        LiveWire.Client.send(P.C_RESET, { inverter = self.inverterId })
        self.lastSubscribe = 0
    elseif b.internal == "LINKS" then
        local obj = self.obj or LiveWire.Install.inverterById(self.player:getCurrentSquare(), self.inverterId)
        if obj then LiveWire.ConnectionPanel.open(self.player, obj) end
    elseif b.internal == "CLOSE" then
        self:close()
    end
end

function Panel:update()
    ISPanel.update(self)
    if isClient() then
        local now = getTimestampMs()
        if now - self.lastSubscribe >= RESUBSCRIBE_MS then
            self.lastSubscribe = now
            LiveWire.Client.send(LiveWire.Protocol.C_SUBSCRIBE, { inverter = self.inverterId })
        end
    end
    local a = LiveWire.Anchor.table()[self.inverterId]
    if a then
        local dx, dy = self.player:getX() - a.x, self.player:getY() - a.y
        if dx * dx + dy * dy > CLOSE_RANGE * CLOSE_RANGE then self:close() end
    end
    local snap = self:snapshot()
    local st = snap and snap.inverter.state
    self.resetBtn:setVisible(st == "tripped")
end

-- Lines of one page: list of strings, plus optional bars { label, value, max }.
function Panel:pageContent(snap)
    local lines, bars = {}, {}
    local inv = snap.inverter
    local function L(s) lines[#lines + 1] = s end
    if self.page == 1 then
        L(snap.name ~= "" and snap.name or T("IGUI_LW_LCD_Page_Balance"))
        local nominal = 0
        for i = 1, #snap.sources do nominal = nominal + (snap.sources[i].nominal or 0) end
        local scale = math.max(inv.maxW or 0, nominal, snap.production or 0, snap.demand or 0, 1)
        L(T("IGUI_LW_LCD_Prod", snap.production))
        -- Public grid draw, only while the inverter takes some (option GridCharging).
        if (snap.gridW or 0) > 0 then L(T("IGUI_LW_LCD_Mains", snap.gridW)) end
        L(T("IGUI_LW_LCD_Load", snap.demand, inv.maxW))
        bars[1] = { label = T("IGUI_LW_LCD_BarProd"), value = snap.production, max = scale }
        bars[2] = { label = T("IGUI_LW_LCD_BarLoad"), value = snap.demand, max = scale }
    elseif self.page == 2 then
        L(T("IGUI_LW_LCD_Page_Batteries"))
        if snap.capacity and snap.capacity > 0 then
            L(T("IGUI_LW_LCD_Stock", math.floor(snap.stock / snap.capacity * 100 + 0.5)))
            L(T("IGUI_LW_LCD_Kwh", string.format("%.2f", snap.stock), string.format("%.2f", snap.capacity)))
            if snap.autonomyH then L(T("IGUI_LW_LCD_Autonomy", math.floor(snap.autonomyH + 0.5))) end
            L(T("IGUI_LW_LCD_Banks", #snap.batteries, snap.banks or 0))
            bars[1] = { label = "", value = snap.stock, max = snap.capacity }
        else
            L(T("IGUI_LW_LCD_NoBattery"))
        end
    elseif self.page == 3 then
        L(T("IGUI_LW_LCD_Page_Sources"))
        for _, fam in ipairs({ { "solar", "IGUI_LW_Family_Solar" }, { "wind", "IGUI_LW_Family_Wind" },
                               { "hydro", "IGUI_LW_Family_Hydro" } }) do
            local n, w = 0, 0
            for i = 1, #snap.sources do
                if snap.sources[i].kind == fam[1] then n = n + 1; w = w + snap.sources[i].w end
            end
            L(T("IGUI_LW_LCD_Family", T(fam[2]), n, w))
        end
        -- nil when the inverter cannot use the public grid (option off, outside).
        if snap.gridW then L(T("IGUI_LW_LCD_Grid", snap.gridW)) end
    elseif self.page == 4 then
        L(T("IGUI_LW_LCD_Page_House"))
        local ap = snap.appliances or {}
        if #ap == 0 then L(T("IGUI_LW_NoAppliance")) end
        for i = 1, math.min(3, #ap) do
            L(T("IGUI_LW_Appliance_Line", T("IGUI_LW_Appliance_" .. ap[i].cat), ap[i].n, ap[i].w))
        end
        L(T("IGUI_LW_LCD_Range", snap.coverage and snap.coverage.radius or 20,
            snap.coverage and snap.coverage.floors or 3))
    else
        L(T("IGUI_LW_LCD_Page_Status"))
        local event = snap.events and snap.events[#snap.events]
        if event then L(LiveWire.Client.text(event.key, event.args)) end
        L(T("IGUI_LW_LCD_Inverter", T("IGUI_LW_State_" .. tostring(inv.state)), inv.cond))
        if snap.coupled then L(T("IGUI_LW_LCD_Coupled", snap.coupled.n, snap.coupled.total)) end
        if inv.muffled then L(T("IGUI_LW_LCD_Muffled")) end
        if snap.breaker then
            L(T("IGUI_LW_LCD_Breaker", T("IGUI_LW_State_" .. tostring(snap.breaker.state))))
        end
        if snap.alarm then
            L(T(snap.alarm.on and "IGUI_LW_Alarm_On" or "IGUI_LW_Alarm_Armed"))
        end
        if snap.backup and snap.backup.state == "manual" then
            -- Manual control (C09): say how to give control back to the mod.
            L(T("IGUI_LW_LCD_BackupManual", snap.backup.w, T("ContextMenu_LW_ResumeBackup")))
        elseif snap.backup then
            L(T("IGUI_LW_Backup_Line", T("IGUI_LW_Backup_" .. tostring(snap.backup.state)), snap.backup.w))
        end
    end
    return lines, bars
end

-- One LCD line, clipped to the screen; a line too wide for it scrolls back and
-- forth with a pause at each end. `reserve`: width kept free on the right.
function Panel:lcdLine(s, y, font, now, reserve)
    local L = self.L
    local avail = L.lcdW - 2 * L.pad - reserve
    local width = getTextManager():MeasureStringX(font, s)
    local offset = 0
    if width > avail then
        local travel = width - avail
        local moveMs = travel / L.scroll * 1000
        local cycle = 2 * (moveMs + SCROLL_PAUSE_MS)
        local t = now % cycle
        if t < SCROLL_PAUSE_MS then
            offset = 0
        elseif t < SCROLL_PAUSE_MS + moveMs then
            offset = (t - SCROLL_PAUSE_MS) / moveMs * travel
        elseif t < 2 * SCROLL_PAUSE_MS + moveMs then
            offset = travel
        else
            offset = travel - (t - 2 * SCROLL_PAUSE_MS - moveMs) / moveMs * travel
        end
    end
    self:setStencilRect(L.lcdX + L.clip, L.lcdY, avail + L.sep, L.lcdH)
    self:drawText(s, L.lcdX + L.pad - math.floor(offset), y, 0.08, 0.13, 0.05, 1, font)
    self:clearStencilRect()
end

-- Brand line of the model (inverter cabinet: its own rating), looked up once.
function Panel:brandKey()
    if not self.brandChecked then
        self.brandChecked = true
        local obj = self.obj or LiveWire.Install.inverterById(self.player:getCurrentSquare(), self.inverterId)
        local model = obj and LiveWire.Defs.modelOfObject(obj)
        local def = model and LiveWire.Defs.devices[model]
        self.brand = def and def.lcdBrand
    end
    return self.brand or "IGUI_LW_LCD_Brand"
end

function Panel:render()
    ISPanel.render(self)
    local snap = self:snapshot()
    local now = getTimestampMs()
    local blink = math.floor(now / 500) % 2 == 0
    local L = self.L
    local LCD_X, LCD_Y, LCD_W, LCD_H = L.lcdX, L.lcdY, L.lcdW, L.lcdH
    self:drawText(T(self:brandKey()), L.brandX, L.brandY, 0.85, 0.87, 0.9, 1, UIFont.Small)

    -- LCD: backlit when the inverter is on, dark otherwise.
    local st = snap and snap.inverter.state
    local lit = st == "on" or st == "tripped"
    self:drawRect(LCD_X - L.bezel, LCD_Y - L.bezel, LCD_W + 2 * L.bezel, LCD_H + 2 * L.bezel, 1, 0.08, 0.08, 0.09)
    if lit then
        self:drawRect(LCD_X, LCD_Y, LCD_W, LCD_H, 1, 0.62, 0.74, 0.40)
    else
        self:drawRect(LCD_X, LCD_Y, LCD_W, LCD_H, 1, 0.16, 0.19, 0.14)
    end
    local font = lcdFont()
    -- Line height of the font really drawn (Code, or Small in CN/JP/KO/TH: C10),
    -- measured once per window.
    local fh = self.fontH
    if not fh then
        fh = getTextManager():getFontHeight(font)
        self.fontH = fh
    end
    local tr, tg, tb = 0.08, 0.13, 0.05
    if not snap then
        self:drawText(T("IGUI_LW_Waiting"), LCD_X + L.pad, LCD_Y + L.pad, 0.6, 0.65, 0.55, 1, font)
    elseif lit then
        if st == "tripped" and blink then
            self:drawText(T("IGUI_LW_LCD_Overload"), LCD_X + L.pad, LCD_Y + LCD_H - fh - L.bottom, 0.55, 0.05, 0.02, 1, font)
        end
        local lines, bars = self:pageContent(snap)
        local y = LCD_Y + L.top
        for i = 1, #lines do
            self:lcdLine(lines[i], y, font, now, i == 1 and L.reserve or 0)
            if i == 1 then
                self:drawText(tostring(self.page) .. "/" .. tostring(PAGES), LCD_X + LCD_W - L.pageX, y, tr, tg, tb, 1, font)
                self:drawRect(LCD_X + L.clip, y + fh + 1, LCD_W - 2 * L.clip, 1, 1, tr, tg, tb)
                y = y + L.sep
            end
            y = y + fh
        end
        for i = 1, #bars do
            local b = bars[i]
            local bx, bw = LCD_X + L.barX, LCD_W - L.barRight
            if b.label ~= "" then self:drawText(b.label, LCD_X + L.pad, y + 1, tr, tg, tb, 1, font) else bx = LCD_X + L.pad; bw = LCD_W - L.barPad end
            local inset, gap = L.barInset, L.barGap
            self:drawRectBorder(bx, y + inset, bw, fh - 2 * inset, 1, tr, tg, tb)
            local f = LiveWire.clamp((b.value or 0) / math.max(1, b.max or 1), 0, 1)
            self:drawRect(bx + gap, y + inset + gap, (bw - 2 * gap) * f, fh - 2 * (inset + gap), 1, tr, tg, tb)
            y = y + fh + gap
        end
    end

    -- Power indicator: green running, red off, blinking orange on a fault.
    local lx, ly = self.powerBtn:getX() - L.ledX, self.powerBtn:getY() + L.ledY
    local r, g, b = 0.75, 0.1, 0.08
    if st == "on" then
        r, g, b = 0.2, 0.95, 0.25
    elseif st == "tripped" or st == "broken" then
        if blink then r, g, b = 1.0, 0.6, 0.1 else r, g, b = 0.3, 0.2, 0.05 end
    end
    self:drawRect(lx, ly, L.led, L.led, 1, r, g, b)
    self:drawRectBorder(lx, ly, L.led, L.led, 1, 0.05, 0.05, 0.05)
end

function Panel:close(sessionEnded)
    if isClient() and not sessionEnded then
        LiveWire.Client.send(LiveWire.Protocol.C_UNSUBSCRIBE, { inverter = self.inverterId })
    end
    self:setVisible(false)
    self:removeFromUIManager()
    if Panel.instance == self then Panel.instance = nil end
end
