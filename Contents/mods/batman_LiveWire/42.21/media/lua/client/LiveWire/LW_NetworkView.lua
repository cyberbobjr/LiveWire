-- Live Wire: local load map and wiring display, using subscribed primitive snapshots.
if isServer() then return end
require "ISUI/ISUIElement"
LiveWire = LiveWire or {}
local View = {}
LiveWire.NetworkView = View
local Overlay = ISUIElement:derive("LiveWireNetworkOverlay")
View.highlights = {}
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
    if View.element then View.element:removeFromUIManager() end
    View.element, View.inverter = nil, nil
end
function View.show(id, mode)
    if View.inverter == id and View.mode == mode then View.hide(); return end
    View.hide()
    View.inverter, View.mode, View.lastSubscribe = id, mode, 0
    View.lastHighlight = -1000
    if mode=="consumers" and LiveWire.PumpView then LiveWire.PumpView.hide() end
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
            wanted[o]=c
        end
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
    else
        self:drawText(getText("IGUI_LW_ConsumerGhostLegend"),20,80,1,1,1,1,UIFont.Small)
    end
end
Events.OnTick.Add(function()
    if not View.inverter then return end
    local p = getPlayer()
    local a = LiveWire.Anchor.table()[View.inverter]
    if not p or p:isDead() or (a and (p:getX() - a.x)^2 + (p:getY() - a.y)^2 > 60^2) then View.hide(); return end
    local now = getTimestampMs()
    if View.mode=="consumers" and now-View.lastHighlight>=1000 then
        View.lastHighlight=now;View.refreshHighlights()
    end
    if now - View.lastSubscribe >= 60000 then
        View.lastSubscribe = now
        LiveWire.Client.send(LiveWire.Protocol.C_SUBSCRIBE, { inverter = View.inverter })
    end
end)
