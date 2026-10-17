-- Live Wire: network dashboard window (client). Reads the snapshot of the inverter:
-- directly from the authority in single player, from the server in multiplayer.
if isServer() then return end

require "ISUI/ISCollapsableWindow"

LiveWire = LiveWire or {}

local FONT = UIFont.Small
local FH = getTextManager():getFontHeight(FONT)
local PAD = 10
local WIDTH = 380
local RESUBSCRIBE_MS = 60 * 1000
local CLOSE_RANGE = 30

local Dashboard = ISCollapsableWindow:derive("LiveWireDashboard")
LiveWire.Dashboard = Dashboard
Dashboard.instance = nil

local function T(key, ...) return getText(key, ...) end

local function fmtKWh(v) return string.format("%.2f", v or 0) end

function Dashboard.open(player, inverterId)
    if Dashboard.instance then Dashboard.instance:close() end
    local x = getPlayerScreenLeft(player:getPlayerNum()) + 80
    local y = getPlayerScreenTop(player:getPlayerNum()) + 60
    local w = Dashboard:new(x, y, WIDTH, 300, player, inverterId)
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
    -- Close when the player walks away from the inverter.
    local a = LiveWire.Anchor.table()[self.inverterId]
    if a then
        local dx, dy = self.player:getX() - a.x, self.player:getY() - a.y
        if dx * dx + dy * dy > CLOSE_RANGE * CLOSE_RANGE then self:close() end
    end
end

function Dashboard:buildLines(snap)
    local lines = {}
    local function add(text, r, g, b) lines[#lines + 1] = { text = text, r = r or 1, g = g or 1, b = b or 1 } end
    if not snap then
        add(T("IGUI_LW_Waiting"), 0.8, 0.8, 0.8)
        return lines
    end
    local inv = snap.inverter
    local level = self.player:getPerkLevel(Perks.Electricity)
    if snap.name and snap.name ~= "" then add(snap.name, 1, 0.9, 0.6) end
    local stateKey = "IGUI_LW_State_" .. tostring(inv.state)
    if inv.state == "on" and not inv.powered then stateKey = "IGUI_LW_State_idle" end
    add(T("IGUI_LW_Inverter_Line", T("IGUI_LW_Model_" .. inv.model), T(stateKey), inv.cond))
    add(T("IGUI_LW_Demand_Line", snap.demand, inv.maxW))
    if inv.maxW > 0 and snap.demand > inv.maxW * 0.9 then add(T("IGUI_LW_Alert_Overload"), 1, 0.5, 0.3) end
    add(T("IGUI_LW_Production_Line", snap.production))
    if snap.capacity and snap.capacity > 0 then
        local pct = math.floor(snap.stock / snap.capacity * 100 + 0.5)
        add(T("IGUI_LW_Stock_Line", fmtKWh(snap.stock), fmtKWh(snap.capacity), pct))
    else
        add(T("IGUI_LW_NoBattery"), 0.8, 0.8, 0.8)
    end
    if level >= 4 and snap.autonomyH then
        add(T("IGUI_LW_Autonomy", math.floor(snap.autonomyH + 0.5)))
    end
    if snap.lost and snap.lost > 0.0005 then add(T("IGUI_LW_Lost", fmtKWh(snap.lost)), 1, 0.8, 0.4) end
    add(" ")
    add(T("IGUI_LW_Sources"), 0.7, 0.9, 1)
    if #snap.sources == 0 then add("  " .. T("IGUI_LW_None"), 0.7, 0.7, 0.7) end
    for i = 1, #snap.sources do
        local s = snap.sources[i]
        local r, g, b = 1, 1, 1
        if s.cond <= 0 then r, g, b = 1, 0.4, 0.4 end
        add("  " .. T("IGUI_LW_Source_Line", T("IGUI_LW_Model_" .. s.model), s.w, s.cond), r, g, b)
    end
    add(T("IGUI_LW_Batteries"), 0.7, 0.9, 1)
    if #snap.batteries == 0 then add("  " .. T("IGUI_LW_None"), 0.7, 0.7, 0.7) end
    for i = 1, #snap.batteries do
        local bt = snap.batteries[i]
        local item = getScriptManager():FindItem(bt.model)
        local name = item and item:getDisplayName() or bt.model
        local r, g, b = 1, 1, 1
        if bt.cond < 30 then r, g, b = 1, 0.6, 0.3 end
        add("  " .. T("IGUI_LW_Battery_Line", name, math.floor(bt.charge * 100 + 0.5), bt.cond), r, g, b)
    end
    if #snap.options > 0 then
        add(T("IGUI_LW_Options"), 0.7, 0.9, 1)
        for i = 1, #snap.options do
            local o = snap.options[i]
            add("  " .. T("IGUI_LW_Option_Line", T("IGUI_LW_Model_" .. o.model), o.cond))
        end
    end
    return lines
end

function Dashboard:render()
    ISCollapsableWindow.render(self)
    if self.isCollapsed then return end
    local lines = self:buildLines(LiveWire.Client.snapshot(self.inverterId))
    local y = self:titleBarHeight() + PAD
    local widest = WIDTH - 2 * PAD
    for i = 1, #lines do
        local l = lines[i]
        self:drawText(l.text, PAD, y, l.r, l.g, l.b, 1, FONT)
        local w = getTextManager():MeasureStringX(FONT, l.text)
        if w > widest then widest = w end
        y = y + FH
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
