-- Live Wire: show the area powered by an inverter (client only, local display).
-- The circle covered by the inverter (GeneratorTileRange around it, vanilla rule)
-- is drawn on screen as a line, projected from the ground of the player's floor
-- (when within the vertical range, else the inverter's floor) by isoToScreenX/Y at
-- every frame. A 1 x 1 UI element hosts the drawing (it draws outside its own
-- bounds and never takes the mouse). Floor highlights were tried first and could
-- not be seen in game. Hidden when the player walks far away.
-- With a coverage provider (LW_Coverage, D-32), the 8 x 8 blocks it adds on the
-- player's floor are outlined too: the engine powers them whole.
if isServer() then return end

require "ISUI/ISUIElement"

LiveWire = LiveWire or {}

local RV = {}
LiveWire.RangeView = RV

RV.HIDE_DISTANCE = 60
RV.SEGMENTS = 96
RV.COLOR = { r = 0.25, g = 0.9, b = 1.0, a = 0.9 }
RV.PUMP_COLOR = { r = 0.30, g = 0.55, b = 1.0, a = 0.9 }

RV.inverterId = nil
RV.center = nil       -- { x, y, z }
RV.element = nil
RV.opts = nil         -- optional { radius, color, floors } of the current view (nil = inverter)

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
    local opts = RV.opts or {}
    local R = opts.radius or LiveWire.Config.tileRange()
    local floors = opts.floors or LiveWire.Config.verticalRange()
    local pz = math.floor(player:getZ())
    if math.abs(pz - c.z) <= floors then z = pz end
    local cx, cy = c.x + 0.5, c.y + 0.5
    local col = opts.color or RV.COLOR
    local px, py = nil, nil
    -- An inverter has no circle when a coverage provider replaces the disc (D-44);
    -- other ranges (opts, e.g. a pump) keep theirs.
    local segments = (RV.opts or LiveWire.Coverage.hasDisc()) and RV.SEGMENTS or -1
    for i = 0, segments do
        local ang = 2 * math.pi * i / RV.SEGMENTS
        local x = isoToScreenX(idx, cx + R * math.cos(ang), cy + R * math.sin(ang), z)
        local y = isoToScreenY(idx, cx + R * math.cos(ang), cy + R * math.sin(ang), z)
        if px then self:drawLine(nil, px, py, x, y, 3, col.a, col.r, col.g, col.b) end
        px, py = x, y
    end
    -- Blocks added by a coverage provider, on the floor drawn (none without one).
    if not RV.opts then
        local rects = RV.extraOutlines(RV.inverterId, c, pz)
        for i = 1, #rects do
            local r = rects[i]
            local x0, y0 = isoToScreenX(idx, r.x0, r.y0, pz), isoToScreenY(idx, r.x0, r.y0, pz)
            local x1, y1 = isoToScreenX(idx, r.x1, r.y0, pz), isoToScreenY(idx, r.x1, r.y0, pz)
            local x2, y2 = isoToScreenX(idx, r.x1, r.y1, pz), isoToScreenY(idx, r.x1, r.y1, pz)
            local x3, y3 = isoToScreenX(idx, r.x0, r.y1, pz), isoToScreenY(idx, r.x0, r.y1, pz)
            self:drawLine(nil, x0, y0, x1, y1, 2, col.a, col.r, col.g, col.b)
            self:drawLine(nil, x1, y1, x2, y2, 2, col.a, col.r, col.g, col.b)
            self:drawLine(nil, x2, y2, x3, y3, 2, col.a, col.r, col.g, col.b)
            self:drawLine(nil, x3, y3, x0, y0, 2, col.a, col.r, col.g, col.b)
        end
    end
    -- The inverter itself: a small cross on its square.
    local ix, iy = isoToScreenX(idx, cx, cy, c.z), isoToScreenY(idx, cx, cy, c.z)
    self:drawLine(nil, ix - 8, iy, ix + 8, iy, 3, col.a, col.r, col.g, col.b)
    self:drawLine(nil, ix, iy - 8, ix, iy + 8, 3, col.a, col.r, col.g, col.b)
end

-- Chunk outlines { x0, y0, x1, y1 } (x1, y1 exclusive) of the provider positions whose
-- vertical range reaches floor `pz`, one per chunk.
function RV.extraOutlines(inverterId, a, pz)
    local out, seen = {}, {}
    local V = LiveWire.Config.verticalRange()
    local list = LiveWire.Coverage.extraPositions(inverterId, a)
    for i = 1, #list do
        local p = list[i]
        local key = p.cx .. "," .. p.cy
        if not seen[key] and math.abs(pz - p.z) <= V then
            seen[key] = true
            out[#out + 1] = { x0 = p.cx * 8, y0 = p.cy * 8, x1 = p.cx * 8 + 8, y1 = p.cy * 8 + 8 }
        end
    end
    return out
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
    RV.inverterId, RV.center, RV.opts = nil, nil, nil
end

-- `opts` (optional) changes the circle: radius in tiles, colour, vertical range.
-- Without it the circle is the inverter's powered area.
function RV.show(inverterId, x, y, z, opts)
    RV.hide()
    RV.inverterId = inverterId
    RV.center = { x = x, y = y, z = z }
    RV.opts = opts
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
