-- Live Wire: our own computer screen, used when the Computer Mod is not there (or
-- for a computer it does not handle). A monitor (bezel, power light, brand) shows
-- a short start-up, then the management software (LW_SoftwareApp.lua) full screen
-- with a small status bar (game time). Opened from a linked desktop computer:
-- right-click, "Live Wire" > management computer > open the software.
if isServer() then return end

require "ISUI/ISPanel"
require "LiveWire/LW_UIScale"

LiveWire = LiveWire or {}

local Screen = ISPanel:derive("LiveWireSoftwareScreen")
LiveWire.SoftwareScreen = Screen
Screen.instance = nil

-- Sizes at the 1080p reference font, scaled once per window (LW_UIScale.lua).
local BASE = { bezel = 22, screenW = 640, screenH = 400, bottom = 34, frame = 6, bootX = 20,
    osX = 8, barPad = 4, barText = 2, brandY = 9, ledX = 48, ledY = 13, ledW = 10, ledH = 6,
    closeX = 30, closeRight = 8, closeY = 6, closeW = 22, closeInset = 14, closeTextX = 19, closeTextY = 8 }
BASE.w = BASE.screenW + 2 * BASE.bezel
BASE.h = BASE.screenH + BASE.bezel + BASE.bottom
Screen.BASE = BASE
local BOOT_MS = 900
local CLOSE_RANGE = 6

function Screen.open(player, inverterId, computer)
    if Screen.instance then Screen.instance:close() end
    local UI = LiveWire.UIScale
    local L = UI.layout(UI.factor(BASE.w, BASE.h), BASE)
    -- The case is built around the scaled screen (no rounding gap).
    local w, h = L.screenW + 2 * L.bezel, L.screenH + L.bezel + L.bottom
    local x = getPlayerScreenLeft(player:getPlayerNum()) + (getPlayerScreenWidth(player:getPlayerNum()) - w) / 2
    local y = getPlayerScreenTop(player:getPlayerNum()) + (getPlayerScreenHeight(player:getPlayerNum()) - h) / 2
    x, y = UI.fit(x, y, w, h)
    local s = Screen:new(x, y, w, h, player, inverterId, computer)
    s.L = L
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
    o.L = LiveWire.UIScale.layout(1, BASE)
    o.player = player
    o.computer = computer
    o.app = LiveWire.SoftwareApp.new(player, inverterId)
    o.app.computer = computer
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
    local L = self.L
    return x >= self.width - L.closeX and x < self.width - L.closeRight
        and y >= self.height - L.bottom + L.closeY and y < self.height - L.closeRight
end

function Screen:onMouseDown(x, y)
    if inClose(self, x, y) then
        self:close()
        return true
    end
    local L = self.L
    local sx, sy = L.bezel, L.bezel
    if x >= sx and x < sx + L.screenW and y >= sy and y < sy + L.screenH then
        if getTimestampMs() - self.openedAt >= BOOT_MS then self.app:onMouseDown(x, y) end
        return true
    end
    return ISPanel.onMouseDown(self, x, y)
end

function Screen:render()
    local w, h = self.width, self.height
    local L = self.L
    local SCREEN_W, SCREEN_H = L.screenW, L.screenH
    -- Monitor case.
    self:drawRect(0, 0, w, h, 1, 0.78, 0.76, 0.70)
    self:drawRectBorder(0, 0, w, h, 1, 0.45, 0.43, 0.40)
    self:drawRect(L.bezel - L.frame, L.bezel - L.frame, SCREEN_W + 2 * L.frame, SCREEN_H + 2 * L.frame, 1, 0.20, 0.20, 0.21)
    -- Screen.
    local sx, sy = L.bezel, L.bezel
    local now = getTimestampMs()
    if now - self.openedAt < BOOT_MS then
        self:drawRect(sx, sy, SCREEN_W, SCREEN_H, 1, 0, 0, 0)
        local s = getText("IGUI_LW_App_Booting")
        local dots = string.rep(".", math.floor((now - self.openedAt) / 250) % 4)
        self:drawText(s .. dots, sx + L.bootX, sy + L.bootX, 0.3, 0.9, 0.4, 1, LiveWire.Client.lcdFont())
    else
        local barH = self.barH
        if not barH then
            barH = getTextManager():getFontHeight(UIFont.Small) + L.barPad
            self.barH = barH
        end
        self.app:draw(self, sx, sy, SCREEN_W, SCREEN_H - barH)
        -- Status bar: game time.
        local gt = getGameTime()
        local clock = string.format("%02d:%02d", gt:getHour(), gt:getMinutes())
        self:drawRect(sx, sy + SCREEN_H - barH, SCREEN_W, barH, 1, 0.05, 0.06, 0.07)
        self:drawText(getText("IGUI_LW_App_OS"), sx + L.osX, sy + SCREEN_H - barH + L.barText, 0.55, 0.6, 0.65, 1, UIFont.Small)
        self:drawTextRight(clock, sx + SCREEN_W - L.osX, sy + SCREEN_H - barH + L.barText, 0.85, 0.9, 0.92, 1, UIFont.Small)
    end
    -- Bottom of the case: brand, power light, close button.
    local by = h - L.bottom
    self:drawText(getText("IGUI_LW_App_Brand"), L.bezel, by + L.brandY, 0.35, 0.34, 0.31, 1, UIFont.Small)
    self:drawRect(w - L.ledX, by + L.ledY, L.ledW, L.ledH, 1, 0.25, 0.95, 0.3)
    local over = inClose(self, self:getMouseX(), self:getMouseY())
    self:drawRect(w - L.closeX, by + L.closeY, L.closeW, L.bottom - L.closeInset, 1, over and 0.55 or 0.62, over and 0.2 or 0.6, over and 0.18 or 0.55)
    self:drawRectBorder(w - L.closeX, by + L.closeY, L.closeW, L.bottom - L.closeInset, 1, 0.4, 0.38, 0.35)
    self:drawTextCentre("x", w - L.closeTextX, by + L.closeTextY, 0.1, 0.1, 0.1, 1, UIFont.Small)
end

function Screen:close()
    self.app:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if Screen.instance == self then Screen.instance = nil end
end
