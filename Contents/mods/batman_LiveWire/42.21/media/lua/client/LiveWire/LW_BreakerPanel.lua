-- Live Wire: compact DIN enclosure, native switch handles and authoritative state.
-- Drawn with the enclosure kit LW_Enclosure (D-54, mockup proposal A): the layout (sizes,
-- help text, button grid) is computed once when the window opens, from the font size (R2);
-- the drawing helpers multiply the 1080p reference coordinates below by the window factor
-- `lwK`, set once when the window is created (LW_UIScale.lua).
if isServer() then return end
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "LiveWire/LW_UIScale"
require "LiveWire/LW_UIKit"
require "LiveWire/LW_Enclosure"
LiveWire = LiveWire or {}
local Panel = ISPanel:derive("LiveWireBreakerPanel")
LiveWire.BreakerPanel = Panel
LiveWire.UIKit.singleton("BreakerPanel", Panel)
local E = LiveWire.Enclosure
local C = E.C
local rect, border = LiveWire.UIKit.rect, LiveWire.UIKit.border
local CLOSE_RANGE = 4 -- the window closes when the player is farther than this, in tiles
-- Reference size at the 1080p font: 750 x 477 (the layout gives the size at any font).
Panel.BASE = { w = 750, h = 477 }
-- Fixed parts of the enclosure, reference units: the LCD block, the breaker grid beside it.
local LCD_W, GRID_W = 246, 382
local HINT_KEYS = { "IGUI_LW_BoardHint", "IGUI_LW_BoardResetHint" }
local MODULE_TOP = 150 -- top of the module bodies and of the LCD block
local text = E.text

local function measureAt(k)
    local tm = getTextManager()
    return function(s) return tm:MeasureStringX(UIFont.Small, s) / k end
end

-- Layout at window factor k: the help text takes as many lines as its longest version, so
-- the window keeps its size when the breaker is tripped.
function Panel.layoutAt(k)
    local tm = getTextManager()
    local fr = tm:getFontHeight(UIFont.Small) / k
    local fmr = tm:getFontHeight(UIFont.Medium) / k
    local fl = tm:getFontHeight(E.lcdFont()) / k
    local spec = { fr = fr, fmr = fmr, fl = fl, compact = false, lcdW = LCD_W, gridW = GRID_W, gridH = 0,
        buttons = { count = 1, widest = 0 } }
    spec.hintLines = 1
    local base = E.layout(spec)
    local lines = 1
    for _, key in ipairs(HINT_KEYS) do
        lines = math.max(lines, #E.wrap(getText(key), base.inW, measureAt(k)))
    end
    spec.hintLines = lines
    return E.layout(spec)
end

-- Two tied pole handles belong to one circuit. Only this UI instance draws them.
local function lever(button)
    local color = button.main and C.orange or C.handle
    local width = button.width / (button.lwK or 1)
    local thumbY = button.off and 45 or 17
    local poles = button.main and 1 or 2
    local poleWidth = width / poles
    for i = 0, poles - 1 do
        local x = i * poleWidth
        rect(button, x + 15, 6, poleWidth - 30, 70, C.ink)
        border(button, x + 15, 6, poleWidth - 30, 70, C.shadow)
    end
    rect(button, 5, thumbY + 4, width - 10, 31, C.shadow)
    rect(button, 3, thumbY, width - 6, 29, color)
    rect(button, 3, thumbY, width - 6, 3, button.main and C.orange or C.edge)
    for i = 1, 3 do rect(button, 9, thumbY + 17 + i * 3, width - 18, 1, C.ink, 0.5) end
    text(button, button.off and "O" or "I", width / 2 - 4, thumbY + 1, 16, C.light, UIFont.Small)
    if not button.enable then rect(button, 3, thumbY, width - 6, 29, C.white, 0.25) end
    if button:isMouseOver() and button.enable then border(button, 1, thumbY - 2, width - 2, 33, C.orange) end
end

-- Work only from the detached snapshot, once per received revision. Use the
-- aggregate breakdown, never the consumer list (limited to 200 display rows).
function Panel.readings(snap)
    local r = { pending = true }
    local b = snap and snap.breaker
    if not b then return r end
    local mainOff = b.mainOff or b.state == "tripped"
    r.lightsOff = mainOff or b.lightsOff
    r.equipmentOff = mainOff or b.equipmentOff
    local supplied = snap.inverter and snap.inverter.powered and not mainOff
    if r.lightsOff or not supplied then r.lights = 0 end
    if r.equipmentOff or not supplied then r.equipment = 0 end
    if snap.demandReady == true and supplied then
        local lights, equipment = 0, 0
        for _, v in ipairs(snap.appliances or {}) do
            if v.cat == "light" then lights = lights + v.w else equipment = equipment + v.w end
        end
        equipment = equipment + (snap.pumps and snap.pumps.w or 0)
        -- In overlapping networks this anchor can supply appliances assigned to
        -- another panel. Preserve its measured watts instead of hiding them.
        r.lights = math.floor(lights + 0.5)
        r.equipment = math.floor(equipment + 0.5)
    end
    if r.lights ~= nil and r.equipment ~= nil then
        r.total = r.lights + r.equipment
        r.pending = false
    end
    return r
end

function Panel.open(player, obj)
    local m = LiveWire.Marks.get(obj)
    if not m then return end
    Panel.closeInstance()
    local UI = LiveWire.UIScale
    local k, w, h = E.twoPass(function(kk)
        local L = Panel.layoutAt(kk)
        return L.W, L.H
    end, UI.factor, UI.fontScale())
    local x, y, ww, hh = UI.fit(getPlayerScreenLeft(player:getPlayerNum()) + 100,
        getPlayerScreenTop(player:getPlayerNum()) + 90, UI.px(w, k), UI.px(h, k))
    local p = Panel:new(x, y, ww, hh)
    p.lwK = k
    p.L = Panel.layoutAt(k)
    p.player, p.obj, p.device, p.inverterId = player, obj, m.id, m.inv
    LiveWire.Client.discardSnapshot(m.inv)
    p.reading = Panel.readings(nil)
    p.moveWithMouse, p.lastSubscribe = true, 0
    p.backgroundColor = { r = 0.11, g = 0.15, b = 0.17, a = 0.99 }
    p:initialise(); p:addToUIManager(); Panel.instance = p
end

function Panel:createChildren()
    ISPanel.createChildren(self)
    local k = self.lwK or 1
    local L = self.L
    local lcdX, mx = L.recessX + 14, L.recessX + 14 + LCD_W + 20
    local function S(v) return LiveWire.UIScale.px(v, k) end
    local function control(x, w, action, main)
        local b = ISButton:new(S(x), S(MODULE_TOP + 51), S(w), S(88), "", self, Panel.onButton)
        b.internal, b.main, b.displayBackground, b.lwK = action, main, false, k
        b:initialise(); b:instantiate(); b.render = lever
        self:addChild(b)
        return b
    end
    self.lightButton = control(mx + 2, 108, "lights", false)
    self.lightButton.tooltip = getText("IGUI_LW_CircuitLights")
    self.equipmentButton = control(mx + 136, 108, "equipment", false)
    self.equipmentButton.tooltip = getText("IGUI_LW_CircuitEquipment")
    self.mainButton = control(mx + 285, 74, "main", true)
    self.mainButton.tooltip = getText("IGUI_LW_BoardMain")
    LiveWire.UIKit.button(self, L.W - 14 - L.closeS, (L.headH - L.closeS) / 2, L.closeS, L.closeS, "x",
        Panel.onButton, "close", k)
    E.cellButton(self, L, 1, getText("IGUI_LW_Connections"), Panel.onButton, "links")
    self.hintLines, self.hintKey = nil, nil
end

function Panel:onButton(b)
    if self.closed then return end
    if b.internal == "close" then self:close(); return end
    if b.internal == "links" then
        if LiveWire.Equipment.accessible(self.player, self.obj, 3.5) then
            LiveWire.ConnectionPanel.open(self.player, self.obj)
        end
        return
    end
    local snap = LiveWire.Client.snapshot(self.inverterId)
    local breaker = snap and snap.breaker
    if not breaker then return end
    if b.internal == "main" then
        if breaker.state == "tripped" then
            LiveWire.Client.send(LiveWire.Protocol.C_RESET_BREAKER, { device = self.device })
        else
            LiveWire.Client.send(LiveWire.Protocol.C_SET_CIRCUIT,
                { device = self.device, circuit = "main", off = not breaker.mainOff })
        end
    elseif b.internal == "lights" or b.internal == "equipment" then
        LiveWire.Client.send(LiveWire.Protocol.C_SET_CIRCUIT,
            { device = self.device, circuit = b.internal,
                off = not (b.internal == "lights" and breaker.lightsOff or b.internal == "equipment" and breaker.equipmentOff) })
    end
end

function Panel:update()
    if self.closed then return end
    ISPanel.update(self)
    local sq = self.obj:getSquare()
    if not sq or self.obj:getObjectIndex() == -1 or self.player:isDead()
        or math.abs(self.player:getX() - sq:getX()) > CLOSE_RANGE or math.abs(self.player:getY() - sq:getY()) > CLOSE_RANGE
        or math.floor(self.player:getZ()) ~= sq:getZ() then self:close(); return end
    local now = getTimestampMs()
    local mark = LiveWire.Marks.get(self.obj)
    local inv = mark and mark.inv
    if self.inverterId ~= inv then
        LiveWire.Client.discardSnapshot(inv)
        self.inverterId, self.lastSubscribe = inv, 0
    end
    if self.inverterId and (self.lastSubscribe == 0 or now - self.lastSubscribe > LiveWire.UIKit.RESUBSCRIBE_MS) then
        self.lastSubscribe = now
        LiveWire.Client.send(LiveWire.Protocol.C_SUBSCRIBE, { inverter = self.inverterId })
    end
    local snap = LiveWire.Client.snapshot(self.inverterId)
    if snap ~= self.viewSnapshot then
        self.viewSnapshot, self.reading = snap, Panel.readings(snap)
    end
    local b = snap and snap.breaker
    self.lightButton:setEnable(b ~= nil); self.mainButton:setEnable(b ~= nil)
    self.lightButton.off = b and b.lightsOff or false
    self.equipmentButton:setEnable(b ~= nil)
    self.equipmentButton.off = b and b.equipmentOff or false
    self.mainButton.off = b and (b.mainOff or b.state == "tripped") or false
end

function Panel:prerender()
    if self.closed then return end
    ISPanel.prerender(self)
    local L, k = self.L, self.lwK or 1
    local snap = self.viewSnapshot
    local b = snap and snap.breaker
    E.frame(self, L, getText("IGUI_LW_BoardTitle"), getText("IGUI_LW_BoardBrand"))
    -- Three-line wattmeter LCD (the condition strip sits in the recess under it), then the
    -- breaker modules on the rail, to its right.
    local r = self.reading
    local function row(key, value, off)
        local s = value == nil and "-- W" or off and value == 0 and getText("IGUI_LW_BoardCutWatts")
            or tostring(value) .. " W"
        return { getText(key), s }
    end
    local own = LiveWire.Marks.get(self.obj)
    local led = snap and snap.inverter.powered and C.green or C.red
    E.lcd(self, L.recessX + 14, MODULE_TOP, LCD_W, {
        title = getText("IGUI_LW_BoardPowerTitle"),
        rows = { row("IGUI_LW_CircuitLightsLabel", r.lights, r.lightsOff),
            row("IGUI_LW_CircuitEquipment", r.equipment, r.equipmentOff),
            row("IGUI_LW_BoardPowerTotal", r.total, false) },
        led = led,
        line = snap and snap.name ~= "" and snap.name or getText("IGUI_LW_Network"),
        status = self:statusText(snap, b, r),
        strip = LiveWire.Client.equipmentCondition(own and own.cond),
    }, L.fr)
    self:drawModules(L, b)
    -- Help text, its screws and the connections button (drawn in the enclosure's lower part).
    local hintKey = b and b.state == "tripped" and "IGUI_LW_BoardResetHint" or "IGUI_LW_BoardHint"
    if self.hintKey ~= hintKey then
        self.hintKey = hintKey
        self.hintText = E.wrap(getText(hintKey), L.inW, measureAt(k))
    end
    for i, line in ipairs(self.hintText) do text(self, line, L.inX, L.hintY + (i - 1) * L.lineH, L.inW, C.ink) end
    E.hintScrews(self, L)
end

function Panel:statusText(snap, b, r)
    local status = b and getText("IGUI_LW_State_" .. b.state)
        or getText(self.inverterId and "IGUI_LW_Waiting" or "IGUI_LW_BankIndependent")
    if b and b.mainOff then status = getText("IGUI_LW_CircuitOff")
    elseif b and b.state == "ok" and snap and not snap.inverter.powered then
        status = getText("IGUI_LW_State_" .. (snap.inverter.state == "off" and "off" or "idle"))
    elseif b and r.pending then status = getText("IGUI_LW_BoardPowerUpdating")
    end
    return status
end

-- The three modules (lights, equipment, main) with their levers, numbers and terminal
-- screws, and the circuit strips under them.
function Panel:drawModules(L, b)
    local gx = L.recessX + 14 + LCD_W + 20
    local function module(x, width, number, main)
        rect(self, x + 2, MODULE_TOP + 4, width, 163, C.shadow)
        rect(self, x, MODULE_TOP, width, 163, C.light)
        border(self, x, MODULE_TOP, width, 163, C.edge)
        local count = main and 1 or 2
        local unit = width / count
        for pole = 0, count - 1 do
            local px = x + pole * unit
            if pole > 0 then rect(self, px, MODULE_TOP + 1, 1, 161, C.edge) end
            rect(self, px + 9, MODULE_TOP + 7, unit - 18, 4, main and C.orange or C.glass)
            text(self, number, px + 8, 170, unit - 12, C.ink)
            E.screw(self, px + unit / 2 - 6, 185)
            E.screw(self, px + unit / 2 - 6, 295)
            text(self, "I", px + 7, 207, 16, C.ink)
            text(self, "O", px + 7, 274, 16, C.ink)
        end
    end
    local m1, m2, m3 = gx, gx + 134, gx + 279
    module(m1, 112, "01", false)
    module(m2, 112, "02", false)
    module(m3, 86, "03", true)
    -- Printed circuit strips under the rail, as on a domestic enclosure.
    local function strip(x, w, key)
        rect(self, x, 338, w, 23, C.light); border(self, x, 338, w, 23, C.edge)
        text(self, getText(key), x + 5, 340, w - 10, C.ink)
    end
    strip(m1, 112, "IGUI_LW_CircuitLightsLabel")
    strip(m2, 112, "IGUI_LW_CircuitEquipment")
    strip(m3 - 7, 100, "IGUI_LW_BoardMain")
    text(self, getText(b and b.equipmentOff and "IGUI_LW_CircuitOff" or "IGUI_LW_CircuitOn"), m2, 365, 124, C.shadow)
end

function Panel:close()
    if self.closed then return end
    -- UIManager defers removal: stop callbacks and hide before releasing data.
    self.closed = true
    self:setVisible(false)
    self:removeFromUIManager()
    self.obj, self.player, self.viewSnapshot, self.reading = nil, nil, nil, nil
    Panel.releaseInstance(self)
end
