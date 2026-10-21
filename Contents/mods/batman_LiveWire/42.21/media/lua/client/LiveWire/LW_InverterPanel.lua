-- Live Wire: front panel of the inverter, drawn as a device: a backlit LCD screen
-- with pages (previous / next), an on/off button with its indicator light and a
-- reset button when the inverter has tripped. Same data as the management
-- software (snapshot of the inverter); the full view is the computer
-- (LW_SoftwareApp.lua). Commands are re-checked by the server.
if isServer() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"

LiveWire = LiveWire or {}

local Panel = ISPanel:derive("LiveWireInverterPanel")
LiveWire.InverterPanel = Panel
Panel.instance = nil

local W, H = 440, 262
local LCD_X, LCD_Y, LCD_W, LCD_H = 18, 40, 404, 138
local SCROLL_PX_PER_S = 40   -- lines wider than the screen scroll back and forth
local SCROLL_PAUSE_MS = 1200
local RESUBSCRIBE_MS = 60 * 1000
local CLOSE_RANGE = 30
local PAGES = 5

local function T(key, ...) return getText(key, ...) end

local function lcdFont()
    return LiveWire.Client.lcdFont()
end

function Panel.open(player, inverterId)
    if Panel.instance then Panel.instance:close() end
    local x = getPlayerScreenLeft(player:getPlayerNum()) + 120
    local y = getPlayerScreenTop(player:getPlayerNum()) + 100
    local p = Panel:new(x, y, player, inverterId)
    p:initialise()
    p:addToUIManager()
    p:setVisible(true)
    Panel.instance = p
end

function Panel:new(x, y, player, inverterId)
    local o = ISPanel:new(x, y, W, H)
    setmetatable(o, self)
    self.__index = self
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
    local by = LCD_Y + LCD_H + 16
    self.prevBtn = button(self, LCD_X, by, 40, 30, "<", "PREV")
    self.nextBtn = button(self, LCD_X + 46, by, 40, 30, ">", "NEXT")
    self.resetBtn = button(self, LCD_X + 100, by, 70, 30, "RESET", "RESET")
    self.powerBtn = button(self, W - 18 - 74, by, 74, 30, "I / O", "POWER")
    self.closeBtn = button(self, W - 26, 6, 18, 18, "x", "CLOSE")
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
        local on = not (snap and snap.inverter.state == "on")
        LiveWire.Client.send(P.C_SET_INVERTER, { inverter = self.inverterId, on = on })
        self.lastSubscribe = 0
    elseif b.internal == "RESET" then
        LiveWire.Client.send(P.C_RESET, { inverter = self.inverterId })
        self.lastSubscribe = 0
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
        L(T("IGUI_LW_LCD_Page_Balance"))
        local nominal = 0
        for i = 1, #snap.sources do nominal = nominal + (snap.sources[i].nominal or 0) end
        local scale = math.max(inv.maxW or 0, nominal, snap.production or 0, snap.demand or 0, 1)
        L(T("IGUI_LW_LCD_Prod", snap.production))
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
        L(T("IGUI_LW_LCD_Inverter", T("IGUI_LW_State_" .. tostring(inv.state)), inv.cond))
        if snap.coupled then L(T("IGUI_LW_LCD_Coupled", snap.coupled.n, snap.coupled.total)) end
        if inv.muffled then L(T("IGUI_LW_LCD_Muffled")) end
        if snap.breaker then
            L(T("IGUI_LW_LCD_Breaker", T("IGUI_LW_State_" .. tostring(snap.breaker.state))))
        end
        if snap.alarm then
            L(T(snap.alarm.on and "IGUI_LW_Alarm_On" or "IGUI_LW_Alarm_Armed"))
        end
        if snap.backup then
            L(T("IGUI_LW_Backup_Line", T("IGUI_LW_Backup_" .. tostring(snap.backup.state)), snap.backup.w))
        end
    end
    return lines, bars
end

-- One LCD line, clipped to the screen; a line too wide for it scrolls back and
-- forth with a pause at each end. `reserve`: width kept free on the right.
function Panel:lcdLine(s, y, font, now, reserve)
    local avail = LCD_W - 16 - reserve
    local width = getTextManager():MeasureStringX(font, s)
    local offset = 0
    if width > avail then
        local travel = width - avail
        local moveMs = travel / SCROLL_PX_PER_S * 1000
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
    self:setStencilRect(LCD_X + 6, LCD_Y, avail + 4, LCD_H)
    self:drawText(s, LCD_X + 8 - math.floor(offset), y, 0.08, 0.13, 0.05, 1, font)
    self:clearStencilRect()
end

function Panel:render()
    ISPanel.render(self)
    local snap = self:snapshot()
    local now = getTimestampMs()
    local blink = math.floor(now / 500) % 2 == 0
    self:drawText(T("IGUI_LW_LCD_Brand"), 14, 10, 0.85, 0.87, 0.9, 1, UIFont.Small)

    -- LCD: backlit when the inverter is on, dark otherwise.
    local st = snap and snap.inverter.state
    local lit = st == "on" or st == "tripped"
    self:drawRect(LCD_X - 4, LCD_Y - 4, LCD_W + 8, LCD_H + 8, 1, 0.08, 0.08, 0.09)
    if lit then
        self:drawRect(LCD_X, LCD_Y, LCD_W, LCD_H, 1, 0.62, 0.74, 0.40)
    else
        self:drawRect(LCD_X, LCD_Y, LCD_W, LCD_H, 1, 0.16, 0.19, 0.14)
    end
    local font = lcdFont()
    local fh = getTextManager():getFontHeight(font)
    local tr, tg, tb = 0.08, 0.13, 0.05
    if not snap then
        self:drawText(T("IGUI_LW_Waiting"), LCD_X + 8, LCD_Y + 8, 0.6, 0.65, 0.55, 1, font)
    elseif lit then
        if st == "tripped" and blink then
            self:drawText(T("IGUI_LW_LCD_Overload"), LCD_X + 8, LCD_Y + LCD_H - fh - 6, 0.55, 0.05, 0.02, 1, font)
        end
        local lines, bars = self:pageContent(snap)
        local y = LCD_Y + 6
        for i = 1, #lines do
            self:lcdLine(lines[i], y, font, now, i == 1 and 44 or 0)
            if i == 1 then
                self:drawText(tostring(self.page) .. "/" .. tostring(PAGES), LCD_X + LCD_W - 34, y, tr, tg, tb, 1, font)
                self:drawRect(LCD_X + 6, y + fh + 1, LCD_W - 12, 1, 1, tr, tg, tb)
                y = y + 4
            end
            y = y + fh
        end
        for i = 1, #bars do
            local b = bars[i]
            local bx, bw = LCD_X + 60, LCD_W - 72
            if b.label ~= "" then self:drawText(b.label, LCD_X + 8, y + 1, tr, tg, tb, 1, font) else bx = LCD_X + 8; bw = LCD_W - 20 end
            self:drawRectBorder(bx, y + 3, bw, fh - 6, 1, tr, tg, tb)
            local f = LiveWire.clamp((b.value or 0) / math.max(1, b.max or 1), 0, 1)
            self:drawRect(bx + 2, y + 5, (bw - 4) * f, fh - 10, 1, tr, tg, tb)
            y = y + fh + 2
        end
    end

    -- Power indicator: green running, red off, blinking orange on a fault.
    local lx, ly = self.powerBtn:getX() - 18, self.powerBtn:getY() + 9
    local r, g, b = 0.75, 0.1, 0.08
    if st == "on" then
        r, g, b = 0.2, 0.95, 0.25
    elseif st == "tripped" or st == "broken" then
        if blink then r, g, b = 1.0, 0.6, 0.1 else r, g, b = 0.3, 0.2, 0.05 end
    end
    self:drawRect(lx, ly, 12, 12, 1, r, g, b)
    self:drawRectBorder(lx, ly, 12, 12, 1, 0.05, 0.05, 0.05)
end

function Panel:close()
    if isClient() then
        LiveWire.Client.send(LiveWire.Protocol.C_UNSUBSCRIBE, { inverter = self.inverterId })
    end
    self:setVisible(false)
    self:removeFromUIManager()
    if Panel.instance == self then Panel.instance = nil end
end
