-- Live Wire: inverter management interface (client). Shows production and
-- consumption, battery state, sources grouped by type (solar, wind, hydro), the
-- powered house (appliances by family, covered area) and alerts; buttons send
-- commands that the server re-validates. Data: snapshot of the inverter, read from
-- the authority in single player, received from the server in multiplayer.
if isServer() then return end

require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"

LiveWire = LiveWire or {}

local FONT = UIFont.Small
local FH = getTextManager():getFontHeight(FONT)
local PAD = 10
local WIDTH = 460
local BAR_H = 8
local GRAPH_H = 40
local RESUBSCRIBE_MS = 60 * 1000
local CLOSE_RANGE = 30

-- Source families, in display order. Hydro is planned for v0.2.
local FAMILIES = {
    { kind = "solar", key = "IGUI_LW_Family_Solar" },
    { kind = "wind", key = "IGUI_LW_Family_Wind" },
    { kind = "hydro", key = "IGUI_LW_Family_Hydro", planned = true },
}

local Dashboard = ISCollapsableWindow:derive("LiveWireDashboard")
LiveWire.Dashboard = Dashboard
Dashboard.instance = nil

local function T(key, ...) return getText(key, ...) end
local function kwh(v) return string.format("%.2f", v or 0) end

function Dashboard.open(player, inverterId)
    if Dashboard.instance then Dashboard.instance:close() end
    local x = getPlayerScreenLeft(player:getPlayerNum()) + 80
    local y = getPlayerScreenTop(player:getPlayerNum()) + 60
    local w = Dashboard:new(x, y, WIDTH, 420, player, inverterId)
    w:initialise()
    w:addToUIManager()
    w:setVisible(true)
    Dashboard.instance = w
end

function Dashboard:new(x, y, width, height, player, inverterId)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.inverterId = inverterId
    o.lastSubscribe = 0
    o:setResizable(false)
    o:setTitle(T("IGUI_LW_Dashboard_Title"))
    return o
end

-- Button height from the font, computed when the window is built (not at file load).
local function buttonHeight()
    return math.max(22, FH + 6)
end

local function addButton(self, x, label, internal)
    local w = getTextManager():MeasureStringX(FONT, label) + 20
    local b = ISButton:new(x, self:titleBarHeight() + PAD, w, buttonHeight(), label, self, Dashboard.onButton)
    b.internal = internal
    b:initialise()
    b:instantiate()
    b.borderColor = { r = 1, g = 1, b = 1, a = 0.2 }
    self:addChild(b)
    return x + w + 6
end

function Dashboard:createChildren()
    ISCollapsableWindow.createChildren(self)
    local x = PAD
    x = addButton(self, x, T("ContextMenu_LW_TurnOn"), "ON")
    x = addButton(self, x, T("ContextMenu_LW_TurnOff"), "OFF")
    addButton(self, x, T("ContextMenu_LW_Reset"), "RESET")
    self.contentTop = self:titleBarHeight() + PAD + buttonHeight() + PAD
end

function Dashboard:onButton(button)
    local P = LiveWire.Protocol
    if button.internal == "ON" then
        LiveWire.Client.send(P.C_SET_INVERTER, { inverter = self.inverterId, on = true })
    elseif button.internal == "OFF" then
        LiveWire.Client.send(P.C_SET_INVERTER, { inverter = self.inverterId, on = false })
    elseif button.internal == "RESET" then
        LiveWire.Client.send(P.C_RESET, { inverter = self.inverterId })
    end
    self.lastSubscribe = 0 -- ask for a fresh snapshot
end

function Dashboard:subscribe()
    if not isClient() then return end
    local now = getTimestampMs()
    if now - self.lastSubscribe < RESUBSCRIBE_MS then return end
    self.lastSubscribe = now
    LiveWire.Client.send(LiveWire.Protocol.C_SUBSCRIBE, { inverter = self.inverterId })
end

function Dashboard:update()
    ISCollapsableWindow.update(self)
    self:subscribe()
    local a = LiveWire.Anchor.table()[self.inverterId]
    if a then
        local dx, dy = self.player:getX() - a.x, self.player:getY() - a.y
        if dx * dx + dy * dy > CLOSE_RANGE * CLOSE_RANGE then self:close() end
    end
end

-- Rows: { text = s, r, g, b } | { bar = fraction, r, g, b } | { header = s }
--     | { graph = { values... }, max = m, r, g, b } (one bar per hour, oldest first).
function Dashboard:buildRows(snap)
    local rows = {}
    local function text(s, r, g, b) rows[#rows + 1] = { text = s, r = r or 1, g = g or 1, b = b or 1 } end
    local function header(s) rows[#rows + 1] = { header = s } end
    local function bar(f, r, g, b) rows[#rows + 1] = { bar = LiveWire.clamp(f or 0, 0, 1), r = r, g = g, b = b } end
    local function graph(values, max, r, g, b)
        rows[#rows + 1] = { graph = values, max = max, r = r, g = g, b = b }
    end
    if not snap then
        text(T("IGUI_LW_Waiting"), 0.8, 0.8, 0.8)
        return rows
    end
    local inv = snap.inverter
    local level = self.player:getPerkLevel(Perks.Electricity)

    -- Inverter and balance.
    if snap.name and snap.name ~= "" then text(snap.name, 1, 0.9, 0.6) end
    local stateKey = "IGUI_LW_State_" .. tostring(inv.state)
    if inv.state == "on" and not inv.powered then stateKey = "IGUI_LW_State_idle" end
    text(T("IGUI_LW_Inverter_Line", T("IGUI_LW_Model_" .. inv.model), T(stateKey), inv.cond))
    header(T("IGUI_LW_Section_Balance"))
    local nominal = 0
    for i = 1, #snap.sources do nominal = nominal + (snap.sources[i].nominal or 0) end
    if snap.backup and snap.backup.state == "running" then nominal = nominal + snap.backup.w end
    text(T("IGUI_LW_Production_Line", snap.production))
    if nominal > 0 then bar(snap.production / nominal, 0.3, 0.8, 0.3) end
    text(T("IGUI_LW_Demand_Line", snap.demand, inv.maxW))
    if inv.maxW > 0 then
        local f = snap.demand / inv.maxW
        if f > 0.9 then bar(f, 0.9, 0.3, 0.2) elseif f > 0.7 then bar(f, 0.9, 0.7, 0.2) else bar(f, 0.3, 0.6, 0.9) end
        if f > 0.9 then text(T("IGUI_LW_Alert_Overload"), 1, 0.5, 0.3) end
    end

    -- Batteries.
    header(T("IGUI_LW_Section_Batteries", snap.banks or 0))
    if snap.capacity and snap.capacity > 0 then
        local pct = math.floor(snap.stock / snap.capacity * 100 + 0.5)
        text(T("IGUI_LW_Stock_Line", kwh(snap.stock), kwh(snap.capacity), pct))
        bar(snap.stock / snap.capacity, 0.9, 0.8, 0.2)
        if level >= 4 and snap.autonomyH then
            text(T("IGUI_LW_Autonomy", math.floor(snap.autonomyH + 0.5)))
        end
        for i = 1, #snap.batteries do
            local bt = snap.batteries[i]
            local item = getScriptManager():FindItem(bt.model)
            local name = item and item:getDisplayName() or bt.model
            local r, g, b = 1, 1, 1
            if bt.cond < 30 then r, g, b = 1, 0.6, 0.3 end
            text("  " .. T("IGUI_LW_Battery_Line", name, math.floor(bt.charge * 100 + 0.5), bt.cond), r, g, b)
        end
    else
        text(T("IGUI_LW_NoBattery"), 0.8, 0.8, 0.8)
    end
    if (snap.extra or 0) > 0 then text(T("IGUI_LW_TooManyBatteries", snap.extra), 1, 0.6, 0.3) end
    if snap.lost and snap.lost > 0.0005 then text(T("IGUI_LW_Lost", kwh(snap.lost)), 1, 0.8, 0.4) end

    -- Sources by family.
    header(T("IGUI_LW_Sources"))
    for f = 1, #FAMILIES do
        local fam = FAMILIES[f]
        local n, w = 0, 0
        for i = 1, #snap.sources do
            if snap.sources[i].kind == fam.kind then n = n + 1; w = w + snap.sources[i].w end
        end
        if fam.planned and n == 0 then
            text(T("IGUI_LW_Family_Line_Planned", T(fam.key)), 0.6, 0.6, 0.6)
        else
            text(T("IGUI_LW_Family_Line", T(fam.key), n, w), 0.8, 0.95, 1)
            for i = 1, #snap.sources do
                local s = snap.sources[i]
                if s.kind == fam.kind then
                    local r, g, b = 1, 1, 1
                    if s.cond <= 0 then r, g, b = 1, 0.4, 0.4 end
                    local line = T("IGUI_LW_Source_Line", T("IGUI_LW_Model_" .. s.model), s.w, s.cond)
                    if s.kind == "solar" and (s.snow or 0) > 0.05 then
                        line = line .. " " .. T("IGUI_LW_Snow", math.floor(s.snow * 100 + 0.5))
                    end
                    text("  " .. line, r, g, b)
                end
            end
        end
    end

    -- Backup generator.
    local bk = snap.backup
    if bk then
        header(T("IGUI_LW_Section_Backup"))
        local r, g, b = 0.8, 0.95, 1
        if bk.state == "nofuel" or bk.state == "unplugged" or bk.state == "broken" then r, g, b = 1, 0.5, 0.3 end
        text(T("IGUI_LW_Backup_Line", T("IGUI_LW_Backup_" .. tostring(bk.state)), bk.w), r, g, b)
        local fuelPct = 0
        if (bk.maxFuel or 0) > 0 then fuelPct = bk.fuel / bk.maxFuel end
        text(T("IGUI_LW_Backup_Fuel", math.floor(fuelPct * 100 + 0.5)))
        bar(fuelPct, 0.8, 0.5, 0.2)
        text(T("IGUI_LW_Backup_Thresholds", bk.start, bk.stop), 0.8, 0.8, 0.8)
    end

    -- Management computer: 48-hour history and forecast until sunrise.
    local pc = snap.computer
    header(T("IGUI_LW_Section_Computer"))
    if not pc then
        text(T("IGUI_LW_Computer_None"), 0.7, 0.7, 0.7)
    elseif not pc.powered then
        text(T("IGUI_LW_Computer_Off"), 1, 0.6, 0.3)
    else
        local hist = snap.history or {}
        if #hist == 0 then
            text(T("IGUI_LW_Computer_NoHistory"), 0.7, 0.7, 0.7)
        else
            local prod, dem, stock = {}, {}, {}
            local peak = 1
            for i = 1, #hist do
                prod[i], dem[i] = hist[i].p or 0, hist[i].d or 0
                stock[i] = math.max(0, hist[i].s or 0)
                peak = math.max(peak, prod[i], dem[i])
            end
            text(T("IGUI_LW_History_Production", #hist, peak), 0.3, 0.8, 0.3)
            graph(prod, peak, 0.3, 0.8, 0.3)
            text(T("IGUI_LW_History_Demand"), 0.3, 0.6, 0.9)
            graph(dem, peak, 0.3, 0.6, 0.9)
            if snap.capacity and snap.capacity > 0 then
                text(T("IGUI_LW_History_Stock"), 0.9, 0.8, 0.2)
                graph(stock, 1, 0.9, 0.8, 0.2)
            end
        end
        if snap.dawnH then
            local dawn = math.floor(snap.dawnH + 0.5)
            if not snap.capacity or snap.capacity <= 0 then
                -- No battery: nothing to forecast.
            elseif not snap.autonomyH then
                text(T("IGUI_LW_Forecast_Surplus"), 0.3, 0.9, 0.3)
            elseif snap.autonomyH >= snap.dawnH then
                text(T("IGUI_LW_Forecast_Holds", dawn), 0.3, 0.9, 0.3)
            else
                text(T("IGUI_LW_Forecast_Short", math.floor(snap.autonomyH + 0.5), dawn), 1, 0.5, 0.3)
            end
        end
        if pc.shed then text(T("IGUI_LW_Computer_Shed"), 0.8, 0.8, 0.8) end
    end
    if snap.alarm then
        if snap.alarm.on then
            text(T("IGUI_LW_Alarm_On"), 1, 0.4, 0.3)
        else
            text(T("IGUI_LW_Alarm_Armed"), 0.8, 0.8, 0.8)
        end
    end

    -- The powered house: every appliance in the covered area, no individual wiring.
    header(T("IGUI_LW_Section_House"))
    text(T("IGUI_LW_Coverage", snap.coverage and snap.coverage.radius or 20,
        snap.coverage and snap.coverage.floors or 3), 0.8, 0.8, 0.8)
    if #(snap.appliances or {}) == 0 then
        text("  " .. T("IGUI_LW_NoAppliance"), 0.7, 0.7, 0.7)
    end
    for i = 1, #(snap.appliances or {}) do
        local ap = snap.appliances[i]
        text("  " .. T("IGUI_LW_Appliance_Line", T("IGUI_LW_Appliance_" .. ap.cat), ap.n, ap.w))
    end

    -- Equipment.
    if #snap.options > 0 then
        header(T("IGUI_LW_Options"))
        for i = 1, #snap.options do
            local o = snap.options[i]
            text("  " .. T("IGUI_LW_Option_Line", T("IGUI_LW_Model_" .. o.model), o.cond))
        end
    end
    return rows
end

function Dashboard:render()
    ISCollapsableWindow.render(self)
    if self.isCollapsed then return end
    local rows = self:buildRows(LiveWire.Client.snapshot(self.inverterId))
    local y = self.contentTop or (self:titleBarHeight() + PAD)
    local inner = self:getWidth() - 2 * PAD
    local widest = WIDTH - 2 * PAD
    for i = 1, #rows do
        local row = rows[i]
        if row.header then
            y = y + 4
            self:drawText(row.header, PAD, y, 0.7, 0.9, 1, 1, FONT)
            y = y + FH
            self:drawRect(PAD, y, inner, 1, 0.4, 0.7, 0.9, 1)
            y = y + 3
        elseif row.graph then
            local n = #row.graph
            local slot = inner / math.max(n, 24)
            self:drawRect(PAD, y + 1, inner, GRAPH_H, 0.6, 0.1, 0.1, 0.1)
            for k = 1, n do
                local f = LiveWire.clamp((row.graph[k] or 0) / (row.max or 1), 0, 1)
                local hgt = math.floor(f * (GRAPH_H - 2) + 0.5)
                if hgt > 0 then
                    self:drawRect(PAD + (k - 1) * slot + 1, y + GRAPH_H - hgt, math.max(1, slot - 1), hgt,
                        0.9, row.r, row.g, row.b)
                end
            end
            self:drawRectBorder(PAD, y + 1, inner, GRAPH_H, 0.5, 1, 1, 1)
            y = y + GRAPH_H + 4
        elseif row.bar then
            self:drawRect(PAD, y + 1, inner, BAR_H, 0.6, 0.1, 0.1, 0.1)
            self:drawRect(PAD, y + 1, inner * row.bar, BAR_H, 0.9, row.r, row.g, row.b)
            self:drawRectBorder(PAD, y + 1, inner, BAR_H, 0.5, 1, 1, 1)
            y = y + BAR_H + 4
        else
            self:drawText(row.text, PAD, y, row.r, row.g, row.b, 1, FONT)
            local w = getTextManager():MeasureStringX(FONT, row.text)
            if w > widest then widest = w end
            y = y + FH
        end
    end
    local wantH = y + PAD + 8
    local wantW = widest + 2 * PAD
    if math.abs(self:getHeight() - wantH) > 1 then self:setHeight(wantH) end
    if wantW > self:getWidth() + 1 then self:setWidth(wantW) end
end

function Dashboard:close()
    if isClient() then
        LiveWire.Client.send(LiveWire.Protocol.C_UNSUBSCRIBE, { inverter = self.inverterId })
    end
    self:setVisible(false)
    self:removeFromUIManager()
    if Dashboard.instance == self then Dashboard.instance = nil end
end
