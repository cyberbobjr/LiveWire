-- Live Wire: local load map and wiring display, using subscribed primitive snapshots.
if isServer() then return end
require "ISUI/ISUIElement"
require "ISUI/ISCollapsableWindow"
LiveWire = LiveWire or {}
local View = {}
LiveWire.NetworkView = View
local Overlay = ISUIElement:derive("LiveWireNetworkOverlay")
-- Legend of the consumers view: a vanilla window (title bar, close button), top centre.
local Legend = ISCollapsableWindow:derive("LiveWireConsumersLegend")
View.KEYS = { { "IGUI_LW_ConsumerKey_Low", { 0.2, 1, 0.2 } }, { "IGUI_LW_ConsumerKey_Mid", { 1, 0.65, 0.2 } },
    { "IGUI_LW_ConsumerKey_High", { 1, 0.2, 0.2 } }, { "IGUI_LW_ConsumerKey_Off", { 0.3, 0.6, 1 } },
    { "IGUI_LW_ConsumerKey_Other", { 0.5, 0.5, 0.5 } }, { "IGUI_LW_ConsumerKey_Grid", { 1, 1, 1 } } }
local PAD, SWATCH, COLS = 10, 12, 3
View.HIDE_DISTANCE = 60
View.GONE_CHECK_MS = 500  -- how often an open view checks that its inverter is still there
View.lastCheck = 0
View.highlights = {}
-- The OnTick handler exists only while the view is open.
local watching = false
local onTick

local function watch()
    if not watching then watching = true; Events.OnTick.Add(onTick) end
end

local function unwatch()
    if watching then watching = false; Events.OnTick.Remove(onTick) end
end
local function sameColor(o,idx,c)
    local v=o:getHighlightColor(idx)
    -- ColorInfo is a Java object, not a Lua {r,g,b,a} table.
    return v and math.abs(v:getR()-c[1])<0.001 and math.abs(v:getG()-c[2])<0.001
        and math.abs(v:getB()-c[3])<0.001 and math.abs(v:getA()-0.85)<0.001
end
local function release(o,h)
    if o:getObjectIndex()~=-1 and sameColor(o,h.idx,h.color) then
        o:setHighlighted(h.idx,false,false)
        o:setHighlightColor(h.idx,h.old[1],h.old[2],h.old[3],h.old[4])
    end
end
function View.hide()
    for o,h in pairs(View.highlights) do release(o,h) end
    View.highlights = {}
    local legend = View.legend
    View.legend = nil
    if legend then legend:removeFromUIManager() end
    if View.element then View.element:removeFromUIManager() end
    View.element, View.inverter, View.at = nil, nil, nil
    unwatch()
end
function View.show(id, mode)
    if View.inverter == id and View.mode == mode then View.hide(); return end
    View.hide()
    View.inverter, View.mode, View.lastSubscribe = id, mode, 0
    View.lastHighlight = -1000
    View.lastCheck = getTimestampMs()
    watch()
    if mode=="consumers" and LiveWire.PumpView then LiveWire.PumpView.hide() end
    View.gridTold = false
    if mode=="consumers" then View.openLegend() end
    local o = ISUIElement:new(0, 0, 1, 1)
    setmetatable(o, Overlay); Overlay.__index = Overlay
    o:initialise(); o:addToUIManager(); o:backMost()
    View.element = o
    LiveWire.Client.send(LiveWire.Protocol.C_SUBSCRIBE, { inverter = id })
end
function Overlay:onMouseDown() return false end
function Overlay:onRightMouseDown() return false end
local COLORS = { source = { 0.2, 1, 0.4 }, storage = { 1, 0.8, 0.2 },
    option = { 1, 0.5, 0.2 }, pump = { 0.3, 0.7, 1 }, computer = { 0.7, 0.5, 1 } }
-- Resolve only the <=200 reported consumers, once a second. Object list indices
-- are hints, never persistent IDs; local overlays can shift them. Ambiguity skips.
function View.consumerObject(d)
    if type(d.sprite)~="string" then return nil end
    local sq=getCell():getGridSquare(d.x,d.y,d.z)
    local objects=sq and sq:getObjects()
    if not objects then return nil end
    local function matches(o)
        local s=o and o:getSprite();return s and s:getName()==d.sprite
    end
    local i=d.objectIndex
    if type(i)=="number" and i>=0 and i<objects:size() then
        local o=objects:get(i);if matches(o) then return o end
    end
    local found
    for n=0,objects:size()-1 do
        local o=objects:get(n)
        if matches(o) then if found then return nil end;found=o end
    end
    return found
end
function View.refreshHighlights()
    local p=getPlayer()
    local snap=View.inverter and LiveWire.Client.snapshot(View.inverter)
    if not p or not snap then return end
    local wanted,idx={},p:getPlayerNum()
    for _,d in ipairs(snap.consumers or {}) do
        local o=View.consumerObject(d)
        if o then
            local c={0.2,1,0.2}
            if d.w>=50 then c={1,0.65,0.2} end
            if d.w>300 then c={1,0.2,0.2} end
            if d.circuitOff or not d.served then c={0.3,0.6,1} end
            if d.owned==false then c={0.5,0.5,0.5} end
            if d.grid then c={1,1,1} end
            wanted[o]=c
        end
    end
    if not View.gridTold and View.gridActive(snap) then
        View.gridTold = true
        HaloTextHelper.addText(p, getText("IGUI_LW_ConsumerGridHalo"))
    end
    local keep={}
    for o,h in pairs(View.highlights) do
        if wanted[o] and o:getObjectIndex()~=-1 and sameColor(o,h.idx,h.color) then keep[o]=h
        else release(o,h) end
    end
    View.highlights=keep
    for o,c in pairs(wanted) do
        local h=keep[o]
        if h or not o:isHighlighted(idx) then
            if not h then
                local old=o:getHighlightColor(idx)
                h={idx=idx,old=old and {old:getR(),old:getG(),old:getB(),old:getA()} or {1,1,1,1}}
                keep[o]=h
            end
            h.color=c
            o:setHighlightColor(idx,c[1],c[2],c[3],0.85)
            o:setHighlighted(idx,true,false)
        end
    end
end
-- Does the public grid still feed an appliance of this view?
function View.gridActive(snap)
    for _,d in ipairs(snap and snap.consumers or {}) do
        if d.grid then return true end
    end
    return false
end
function Overlay:render()
    local player = getPlayer()
    local snap = View.inverter and LiveWire.Client.snapshot(View.inverter)
    if not player or not snap or not snap.origin then return end
    local idx = player:getPlayerNum()
    local a = snap.origin
    local ax, ay = isoToScreenX(idx, a.x + 0.5, a.y + 0.5, a.z), isoToScreenY(idx, a.x + 0.5, a.y + 0.5, a.z)
    if View.mode == "links" then
        for _, d in ipairs(snap.links or {}) do
            local bx, by = isoToScreenX(idx, d.x + 0.5, d.y + 0.5, d.z), isoToScreenY(idx, d.x + 0.5, d.y + 0.5, d.z)
            local col = COLORS[d.role] or { 0.8, 0.8, 0.8 }
            local steps = d.z == a.z and 1 or 20
            for i = 0, steps - 1 do
                if steps == 1 or i % 2 == 0 then
                    self:drawLine(nil, ax + (bx - ax) * i / steps, ay + (by - ay) * i / steps,
                        ax + (bx - ax) * (i + 1) / steps, ay + (by - ay) * (i + 1) / steps,
                        2, 0.85, col[1], col[2], col[3])
                end
            end
        end
    end
end
function View.openLegend()
    local tm = getTextManager()
    local fh = tm:getFontHeight(UIFont.Small)
    local colW = 0
    for _, k in ipairs(View.KEYS) do
        colW = math.max(colW, SWATCH + 6 + tm:MeasureStringX(UIFont.Small, getText(k[1])) + 16)
    end
    local warnW = tm:MeasureStringX(UIFont.Small, getText("IGUI_LW_ConsumerGridActive"))
    local rows = math.ceil(#View.KEYS / COLS)
    local w = math.max(COLS * colW, warnW) + 2 * PAD
    local h = ISCollapsableWindow.TitleBarHeight() + PAD + (rows + 1) * (fh + 6) + PAD
    local o = Legend:new(math.floor((getCore():getScreenWidth() - w) / 2), 60, w, h)
    o.colW, o.fh = colW, fh
    o:initialise()
    o:setTitle(getText("IGUI_LW_App_Tab_Consumers"))
    o:setResizable(false)
    o:addToUIManager()
    View.legend = o
end
-- The window's close button closes the whole view.
function Legend:close() View.hide() end
function Legend:render()
    ISCollapsableWindow.render(self)
    local y0 = self:titleBarHeight() + PAD
    local step = self.fh + 6
    for i, k in ipairs(View.KEYS) do
        local x = PAD + ((i - 1) % COLS) * self.colW
        local y = y0 + math.floor((i - 1) / COLS) * step
        local c, sy = k[2], y + math.floor((self.fh - SWATCH) / 2)
        self:drawRect(x, sy, SWATCH, SWATCH, 1, c[1], c[2], c[3])
        self:drawRectBorder(x, sy, SWATCH, SWATCH, 1, 0, 0, 0)
        self:drawText(getText(k[1]), x + SWATCH + 6, y, 1, 1, 1, 1, UIFont.Small)
    end
    local snap = View.inverter and LiveWire.Client.snapshot(View.inverter)
    if View.gridActive(snap) then
        local rows = math.ceil(#View.KEYS / COLS)
        self:drawText(getText("IGUI_LW_ConsumerGridActive"), PAD, y0 + rows * step + 2, 1, 0.85, 0.2, 1, UIFont.Small)
    end
end
-- Square of the open view's inverter: its anchor, else the origin of its last snapshot,
-- else the last one known (a removed inverter may lose both, solo first).
local function inverterSquare()
    local a = LiveWire.Anchor.table()[View.inverter]
    if not a then
        local snap = LiveWire.Client.snapshot(View.inverter)
        a = snap and snap.origin
    end
    if a then View.at = { x = a.x, y = a.y, z = a.z } end
    return View.at
end

onTick = function()
    if not View.inverter then return end
    local p = getPlayer()
    local a = inverterSquare()
    if not p or p:isDead() or (a and (p:getX() - a.x)^2 + (p:getY() - a.y)^2 > View.HIDE_DISTANCE^2) then
        View.hide(); return
    end
    local now = getTimestampMs()
    -- The inverter picked up or destroyed: the view and its highlights go with it. In
    -- multiplayer the last snapshot stays on the client, so the snapshot cannot tell.
    if now - View.lastCheck >= View.GONE_CHECK_MS then
        View.lastCheck = now
        if a and LiveWire.Marks.goneAt(View.inverter, a.x, a.y, a.z) then View.hide(); return end
    end
    if View.mode=="consumers" and now-View.lastHighlight>=1000 then
        View.lastHighlight=now;View.refreshHighlights()
    end
    if now - View.lastSubscribe >= 60000 then
        View.lastSubscribe = now
        LiveWire.Client.send(LiveWire.Protocol.C_SUBSCRIBE, { inverter = View.inverter })
    end
end
