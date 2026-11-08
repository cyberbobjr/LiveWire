-- LiveWire Extended: draw the zone of a power terminal. Same principle as the vanilla
-- animal zone tool (ISAddDesignationAnimalZoneUI: onMouseDownOutside / MoveOutside /
-- UpOutside, world menu disabled while drawing). The preview outlines the chunks the
-- engine will really power (the rectangle rounded to 8 x 8 blocks): green when allowed,
-- red otherwise. Floor highlights are persistent, set once per change and removed on
-- close (knowledge: ui-windows.md, stable ground highlight); no per-frame hook.
if isServer() then return end
require "ISUI/ISPanel"
require "LiveWireExtended/LWX_Zone"
require "LiveWireExtended/LWX_Terminal"

local X = LiveWire.Extended
local Z = X.Zone
local Tool = ISPanel:derive("LWXZoneTool")
X.ZoneTool = Tool

local CHUNK = 8
local MAX_OUTLINE = 600
local FONT = getTextManager():getFontHeight(UIFont.Small)

function Tool:initialise()
    ISPanel.initialise(self)
    local pad, w = 10, self.width - 20
    self.title = ISLabel:new(pad, pad, FONT + 4, getText("IGUI_LWX_ZoneToolTitle"), 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.title)
    self.info = ISLabel:new(pad, pad + FONT + 8, FONT + 4, getText("IGUI_LWX_ZoneToolHelp"), 0.9, 0.9, 0.9, 1, UIFont.Small, true)
    self:addChild(self.info)
    local by = self.height - pad - FONT - 8
    self.apply = ISButton:new(pad, by, w / 2 - 4, FONT + 8, getText("IGUI_LWX_ZoneApply"), self, Tool.onApply)
    self.apply:initialise(); self:addChild(self.apply)
    self.cancel = ISButton:new(pad + w / 2 + 4, by, w / 2 - 4, FONT + 8, getText("UI_Cancel"), self, Tool.close)
    self.cancel:initialise(); self:addChild(self.cancel)
    self:refresh()
end

function Tool:pickSquare(screenX, screenY)
    local z = self.terminal:getSquare():getZ()
    local x = math.floor(screenToIsoX(self.playerNum, screenX, screenY, z))
    local y = math.floor(screenToIsoY(self.playerNum, screenX, screenY, z))
    return x, y
end

function Tool:onMouseDownOutside(x, y)
    if self.startX then return end
    self.startX, self.startY = self:pickSquare(getMouseX(), getMouseY())
    self.endX, self.endY = self.startX, self.startY
    self.drawing = true
    ISWorldObjectContextMenu.disableWorldMenu = true
    self:refresh()
end

function Tool:onMouseMoveOutside(dx, dy)
    if not self.drawing then return end
    local x, y = self:pickSquare(getMouseX(), getMouseY())
    if x ~= self.endX or y ~= self.endY then
        self.endX, self.endY = x, y
        self:refresh()
    end
end

function Tool:onMouseUpOutside(x, y)
    if not self.drawing then return end
    self.drawing = false
    ISWorldObjectContextMenu.disableWorldMenu = false
    self:refresh()
end

-- Programmatic rectangle (also used by the in-game tests).
function Tool:setRect(x0, y0, x1, y1)
    self.startX, self.startY, self.endX, self.endY = x0, y0, x1, y1
    self.drawing = false
    self:refresh()
end

function Tool:clearHighlights()
    for _, o in ipairs(self.lit or {}) do
        if o:getObjectIndex() ~= -1 then o:setHighlighted(false) end
    end
    self.lit = {}
end

-- Outline the chunk rectangle `c` on the floor of the terminal.
function Tool:outline(c, r, g, b)
    self:clearHighlights()
    local cell, z = getCell(), self.terminal:getSquare():getZ()
    local x0, y0 = c.cx0 * CHUNK, c.cy0 * CHUNK
    local x1, y1 = c.cx1 * CHUNK + CHUNK - 1, c.cy1 * CHUNK + CHUNK - 1
    local function lit(x, y)
        if #self.lit >= MAX_OUTLINE then return end
        local sq = cell:getGridSquare(x, y, z)
        local floor = sq and sq:getFloor()
        if floor and not floor:isHighlighted() then
            floor:setHighlightColor(r, g, b, 0.7)
            floor:setHighlighted(true, false)
            self.lit[#self.lit + 1] = floor
        end
    end
    for x = x0, x1 do lit(x, y0); lit(x, y1) end
    for y = y0 + 1, y1 - 1 do lit(x0, y); lit(x1, y) end
end

function Tool:refresh()
    if not self.startX then
        self.apply.enable = false
        return
    end
    local c = Z.round(self.startX, self.startY, self.endX, self.endY)
    local sq = self.terminal:getSquare()
    local ok, why = Z.allowed(c, sq:getX(), sq:getY())
    self.rect = c
    self.valid = ok
    local w, h = (c.cx1 - c.cx0 + 1) * CHUNK, (c.cy1 - c.cy0 + 1) * CHUNK
    if ok then
        self.info:setName(getText("IGUI_LWX_ZoneToolSize", tostring(w), tostring(h)))
        self:outline(c, 0.2, 0.9, 0.3)
    else
        self.info:setName(getText(why))
        self:outline(c, 0.95, 0.25, 0.2)
    end
    self.apply.enable = ok and not self.drawing
end

function Tool:onApply()
    if not self.valid or not self.rect then return end
    local c = self.rect
    local o = self.terminal
    if luautils.walkAdj(self.player, o:getSquare()) then
        ISTimedActionQueue.add(LWXZoneAction:new(self.player, o, c.cx0 * CHUNK, c.cy0 * CHUNK,
            c.cx1 * CHUNK + CHUNK - 1, c.cy1 * CHUNK + CHUNK - 1))
    end
    self:close()
end

function Tool:close()
    self:clearHighlights()
    ISWorldObjectContextMenu.disableWorldMenu = false
    self:setVisible(false)
    self:removeFromUIManager()
    if Tool.instance == self then Tool.instance = nil end
end

function Tool:new(player, terminal)
    local w, h = 320, 3 * FONT + 50
    local o = ISPanel.new(self, getCore():getScreenWidth() / 2 - w / 2, 60, w, h)
    o.player, o.playerNum, o.terminal = player, player:getPlayerNum(), terminal
    o.lit = {}
    o.moveWithMouse = true
    return o
end

function Tool.open(player, terminal)
    if Tool.instance then Tool.instance:close() end
    local t = Tool:new(player, terminal)
    t:initialise()
    t:addToUIManager()
    Tool.instance = t
    return t
end
