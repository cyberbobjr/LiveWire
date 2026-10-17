-- Live Wire: our own computer screen, used when the Computer Mod is not there (or
-- for a computer it does not handle). A monitor (bezel, power light, brand) shows
-- a short start-up, then the management software (LW_SoftwareApp.lua) full screen
-- with a small status bar (game time). Opened from a linked desktop computer:
-- right-click, "Live Wire" > management computer > open the software.
if isServer() then return end

require "ISUI/ISPanel"

LiveWire = LiveWire or {}

local Screen = ISPanel:derive("LiveWireSoftwareScreen")
LiveWire.SoftwareScreen = Screen
Screen.instance = nil

local BEZEL = 22
local SCREEN_W, SCREEN_H = 640, 400
local BOTTOM = 34
local BOOT_MS = 900
local CLOSE_RANGE = 6

function Screen.open(player, inverterId, computer)
    if Screen.instance then Screen.instance:close() end
    local w, h = SCREEN_W + 2 * BEZEL, SCREEN_H + BEZEL + BOTTOM
    local x = getPlayerScreenLeft(player:getPlayerNum()) + (getPlayerScreenWidth(player:getPlayerNum()) - w) / 2
    local y = getPlayerScreenTop(player:getPlayerNum()) + (getPlayerScreenHeight(player:getPlayerNum()) - h) / 2
    local s = Screen:new(x, y, w, h, player, inverterId, computer)
    s:initialise()
    s:addToUIManager()
    s:setVisible(true)
    Screen.instance = s
    getSoundManager():playUISound("UIActivateButton")
end

function Screen:new(x, y, w, h, player, inverterId, computer)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.computer = computer
    o.app = LiveWire.SoftwareApp.new(player, inverterId)
    o.openedAt = getTimestampMs()
    o.moveWithMouse = true
    o.background = false
    return o
end

function Screen:update()
    ISPanel.update(self)
    self.app:update()
    local c = self.computer
    local sq = c and c.getSquare and c:getSquare()
    if c and (not sq or c:getObjectIndex() == -1) then
        self:close()
        return
    end
    if sq then
        local dx, dy = self.player:getX() - (sq:getX() + 0.5), self.player:getY() - (sq:getY() + 0.5)
        if dx * dx + dy * dy > CLOSE_RANGE * CLOSE_RANGE then self:close() end
    end
end

local function inClose(self, x, y)
    return x >= self.width - 30 and x < self.width - 8 and y >= self.height - BOTTOM + 6 and y < self.height - 8
end

function Screen:onMouseDown(x, y)
    if inClose(self, x, y) then
        self:close()
        return true
    end
    local sx, sy = BEZEL, BEZEL
    if x >= sx and x < sx + SCREEN_W and y >= sy and y < sy + SCREEN_H then
        if getTimestampMs() - self.openedAt >= BOOT_MS then self.app:onMouseDown(x, y) end
        return true
    end
    return ISPanel.onMouseDown(self, x, y)
end

function Screen:render()
    local w, h = self.width, self.height
    -- Monitor case.
    self:drawRect(0, 0, w, h, 1, 0.78, 0.76, 0.70)
    self:drawRectBorder(0, 0, w, h, 1, 0.45, 0.43, 0.40)
    self:drawRect(BEZEL - 6, BEZEL - 6, SCREEN_W + 12, SCREEN_H + 12, 1, 0.20, 0.20, 0.21)
    -- Screen.
    local sx, sy = BEZEL, BEZEL
    local now = getTimestampMs()
    if now - self.openedAt < BOOT_MS then
        self:drawRect(sx, sy, SCREEN_W, SCREEN_H, 1, 0, 0, 0)
        local s = getText("IGUI_LW_App_Booting")
        local dots = string.rep(".", math.floor((now - self.openedAt) / 250) % 4)
        self:drawText(s .. dots, sx + 20, sy + 20, 0.3, 0.9, 0.4, 1, UIFont.Code or UIFont.Small)
    else
        local barH = getTextManager():getFontHeight(UIFont.Small) + 4
        self.app:draw(self, sx, sy, SCREEN_W, SCREEN_H - barH)
        -- Status bar: game time.
        local gt = getGameTime()
        local clock = string.format("%02d:%02d", gt:getHour(), gt:getMinutes())
        self:drawRect(sx, sy + SCREEN_H - barH, SCREEN_W, barH, 1, 0.05, 0.06, 0.07)
        self:drawText(getText("IGUI_LW_App_OS"), sx + 8, sy + SCREEN_H - barH + 2, 0.55, 0.6, 0.65, 1, UIFont.Small)
        self:drawTextRight(clock, sx + SCREEN_W - 8, sy + SCREEN_H - barH + 2, 0.85, 0.9, 0.92, 1, UIFont.Small)
    end
    -- Bottom of the case: brand, power light, close button.
    local by = h - BOTTOM
    self:drawText(getText("IGUI_LW_App_Brand"), BEZEL, by + 9, 0.35, 0.34, 0.31, 1, UIFont.Small)
    self:drawRect(w - 48, by + 13, 10, 6, 1, 0.25, 0.95, 0.3)
    local over = inClose(self, self:getMouseX(), self:getMouseY())
    self:drawRect(w - 30, by + 6, 22, BOTTOM - 14, 1, over and 0.55 or 0.62, over and 0.2 or 0.6, over and 0.18 or 0.55)
    self:drawRectBorder(w - 30, by + 6, 22, BOTTOM - 14, 1, 0.4, 0.38, 0.35)
    self:drawTextCentre("x", w - 19, by + 8, 0.1, 0.1, 0.1, 1, UIFont.Small)
end

function Screen:close()
    self.app:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if Screen.instance == self then Screen.instance = nil end
end
