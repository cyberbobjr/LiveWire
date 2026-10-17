-- Live Wire: show the area powered by an inverter (client only, local display).
-- The circle covered by the inverter (GeneratorTileRange around it, vanilla rule)
-- is drawn on screen as a line, projected from the ground of the player's floor
-- (when within the vertical range, else the inverter's floor) by isoToScreenX/Y at
-- every frame. A 1 x 1 UI element hosts the drawing (it draws outside its own
-- bounds and never takes the mouse). Floor highlights were tried first and could
-- not be seen in game. Hidden when the player walks far away.
if isServer() then return end

require "ISUI/ISUIElement"

LiveWire = LiveWire or {}

local RV = {}
LiveWire.RangeView = RV

RV.HIDE_DISTANCE = 60
RV.SEGMENTS = 96
RV.COLOR = { r = 0.25, g = 0.9, b = 1.0, a = 0.9 }

RV.inverterId = nil
RV.center = nil       -- { x, y, z }
RV.element = nil

local Overlay = ISUIElement:derive("LiveWireRangeOverlay")

function Overlay:new()
    local o = ISUIElement:new(0, 0, 1, 1)
    setmetatable(o, self)
    self.__index = self
    return o
end

function Overlay:onMouseDown() return false end
function Overlay:onRightMouseDown() return false end

function Overlay:render()
    local c = RV.center
    local player = getPlayer()
    if not c or not player then return end
    local idx = player:getPlayerNum()
    local z = c.z
    local pz = math.floor(player:getZ())
    if math.abs(pz - c.z) <= LiveWire.Config.verticalRange() then z = pz end
    local R = LiveWire.Config.tileRange()
    local cx, cy = c.x + 0.5, c.y + 0.5
    local col = RV.COLOR
    local px, py = nil, nil
    for i = 0, RV.SEGMENTS do
        local ang = 2 * math.pi * i / RV.SEGMENTS
        local x = isoToScreenX(idx, cx + R * math.cos(ang), cy + R * math.sin(ang), z)
        local y = isoToScreenY(idx, cx + R * math.cos(ang), cy + R * math.sin(ang), z)
        if px then self:drawLine(nil, px, py, x, y, 3, col.a, col.r, col.g, col.b) end
        px, py = x, y
    end
    -- The inverter itself: a small cross on its square.
    local ix, iy = isoToScreenX(idx, cx, cy, c.z), isoToScreenY(idx, cx, cy, c.z)
    self:drawLine(nil, ix - 8, iy, ix + 8, iy, 3, col.a, col.r, col.g, col.b)
    self:drawLine(nil, ix, iy - 8, ix, iy + 8, 3, col.a, col.r, col.g, col.b)
end

function RV.isShown(inverterId)
    return RV.inverterId ~= nil and RV.inverterId == inverterId
end

function RV.hide()
    if RV.element then
        RV.element:setVisible(false)
        RV.element:removeFromUIManager()
        RV.element = nil
    end
    RV.inverterId, RV.center = nil, nil
end

function RV.show(inverterId, x, y, z)
    RV.hide()
    RV.inverterId = inverterId
    RV.center = { x = x, y = y, z = z }
    local el = Overlay:new()
    el:initialise()
    el:addToUIManager()
    el:backMost()
    RV.element = el
end

local function onTick()
    if not RV.center then return end
    local player = getPlayer()
    if not player then return end
    local dx, dy = player:getX() - RV.center.x, player:getY() - RV.center.y
    if dx * dx + dy * dy > RV.HIDE_DISTANCE * RV.HIDE_DISTANCE then RV.hide() end
end

Events.OnTick.Add(onTick)
