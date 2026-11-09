-- LiveWire Extended: window of a breaker board (D-36, E19). One row per breaker: its
-- lever (switch off, switch on, reset after a trip), its label (written with a pen or a
-- pencil), its load in W and A against its rating, its points, and "Locate", which
-- lights the floor under its appliances until pressed again or the window closes
-- (persistent highlights set once, no per-frame hook). Reads the public table only;
-- every change goes through a timed action checked on the authority.
if isServer() then return end
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextBox"
require "LiveWire/LW_UIScale"
require "LiveWireExtended/LWX_Points"

local X = LiveWire.Extended
local B = X.Breakers
local Window = ISPanel:derive("LWXBoardWindow")
X.BoardWindow = Window

local BASE_W, ROW_H, PAD = 780, 44, 10
local FONT_H = getTextManager():getFontHeight(UIFont.Small)

function Window:record()
    local sq = self.board and self.board:getSquare()
    return sq and X.Panel.recordAt(sq) or nil
end

local function queue(self, action)
    if luautils.walkAdj(self.player, self.board:getSquare()) then ISTimedActionQueue.add(action) end
end

function Window:onLever(button)
    local slot = button.slot
    local mode = (slot.off or slot.tripped) and "on" or "off"
    queue(self, LWXBreakerAction:new(self.player, self.board, nil, slot.pos, mode))
end

function Window:onRename(button)
    local slot, me = button.slot, self
    local box = ISTextBox:new(0, 0, 320, 140, getText("IGUI_LWX_LabelPrompt", tostring(slot.pos)), slot.label or "",
        nil, function(_, b)
            if b.internal == "OK" then
                queue(me, LWXBreakerAction:new(me.player, me.board, nil, slot.pos, "label", b.parent.entry:getText()))
            end
        end)
    box:initialise()
    box:addToUIManager()
    box.entry:setMaxTextLength(B.LABEL_MAX)
end

function Window:clearLocate()
    for _, o in ipairs(self.lit or {}) do
        if o:getObjectIndex() ~= -1 then o:setHighlighted(false) end
    end
    self.lit, self.locating = {}, nil
end

function Window:onLocate(button)
    local pos = button.slot.pos
    local again = self.locating == pos
    self:clearLocate()
    if again then return end
    self.locating = pos
    for _, key in ipairs(B.pointList(button.slot)) do
        for _, found in ipairs(X.Points.objectsOf(key, X.Points.point(key))) do
            -- every piece of a multi-tile appliance, every switch of a room
            for _, o in ipairs(X.Adapters.find(found).pieces(found)) do
                if not o:isHighlighted() then
                    o:setHighlightColor(0.95, 0.75, 0.2, 1)
                    o:setHighlighted(true, false)
                    self.lit[#self.lit + 1] = o
                end
            end
        end
    end
end

-- Rebuild the buttons when the breakers change (count, positions).
function Window:layoutSignature(record)
    local t = {}
    for _, s in ipairs(record and record.slots or {}) do t[#t + 1] = s.pos .. ":" .. s.poles end
    return table.concat(t, ",")
end

function Window:rebuild(record)
    for _, b in ipairs(self.buttons or {}) do self:removeChild(b) end
    self.buttons = {}
    local k = self.lwK
    local y = (PAD + FONT_H + 14) * k
    for _, slot in ipairs(record and record.slots or {}) do
        local function add(x, w, title, fn)
            local b = ISButton:new(x * k, y, w * k, (ROW_H - 6) * k, title, self, fn)
            b:initialise()
            b.slot = slot
            self:addChild(b)
            self.buttons[#self.buttons + 1] = b
            return b
        end
        add(PAD, 70, "", Window.onLever).lever = true
        add(BASE_W - PAD - 170, 80, getText("IGUI_LWX_Rename"), Window.onRename)
        add(BASE_W - PAD - 85, 85, getText("IGUI_LWX_Locate"), Window.onLocate)
        y = y + ROW_H * k
    end
    self.signature = self:layoutSignature(record)
    self:setHeight(y + (PAD + 4) * k)
end

function Window:prerender()
    ISPanel.prerender(self)
    local record = self:record()
    if not record then self:close(); return end
    if self:layoutSignature(record) ~= self.signature then self:rebuild(record) end
    -- Keep each button on the CURRENT slot table (the public table is replaced on receipt).
    for _, b in ipairs(self.buttons) do
        b.slot = B.slotAt(record, b.slot.pos) or b.slot
        if b.lever then
            b:setTitle(getText(b.slot.tripped and "IGUI_LWX_LeverReset" or b.slot.off and "IGUI_LWX_LeverOff"
                or "IGUI_LWX_LeverOn"))
        end
    end
end

function Window:render()
    ISPanel.render(self)
    local record = self:record()
    if not record then return end
    local k = self.lwK
    self:drawText(getText("IGUI_LWX_BoardTitle", tostring(record.size), tostring(B.usedModules(record))),
        PAD * k, PAD * k, 1, 1, 1, 1, UIFont.Small)
    local y = (PAD + FONT_H + 14) * k
    if #(record.slots or {}) == 0 then
        self:drawText(getText("IGUI_LWX_BoardEmpty"), PAD * k, y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    for _, slot in ipairs(record.slots or {}) do
        local ty = y + 2 * k
        local name = slot.label ~= "" and slot.label or getText("IGUI_LWX_ModuleName", tostring(slot.pos))
        if slot.twilight then name = getText("IGUI_LWX_TwilightTag", name) end
        self:setStencilRect((PAD + 80) * k, y, 165 * k, ROW_H * k)
        self:drawText(name, (PAD + 80) * k, ty, 1, 1, 1, 1, UIFont.Small)
        self:clearStencilRect()
        local rating = slot.amps .. " A " .. slot.volts .. " V"
        local load = getText("IGUI_LWX_Load", tostring(slot.load or 0), string.format("%.1f", B.amps(slot)), rating,
            tostring(#B.pointList(slot)))
        local r, g, bl = 0.75, 0.85, 0.75
        if slot.tripped then r, g, bl = 0.95, 0.35, 0.3 elseif slot.off then r, g, bl = 0.6, 0.6, 0.6 end
        self:setStencilRect((PAD + 250) * k, y, (BASE_W - 2 * PAD - 425) * k, ROW_H * k)
        self:drawText(load, (PAD + 250) * k, ty, r, g, bl, 1, UIFont.Small)
        -- Energy meter of the circuit (E24).
        local m = B.meterSummary(slot)
        self:drawText(getText("IGUI_LWX_Meter", string.format("%.1f", m.today), string.format("%.1f", m.yesterday),
            string.format("%.1f", m.week)), (PAD + 250) * k, ty + FONT_H, 0.6, 0.65, 0.6, 1, UIFont.Small)
        self:clearStencilRect()
        y = y + ROW_H * k
    end
end

function Window:close()
    self:clearLocate()
    self:setVisible(false)
    self:removeFromUIManager()
    if Window.instance == self then Window.instance = nil end
end

function Window:onMouseDownOutside() end

function Window:createChildren()
    ISPanel.createChildren(self)
    local k = self.lwK
    local c = ISButton:new((BASE_W - PAD - 24) * k, PAD * k * 0.6, 24 * k, 20 * k, "X", self, Window.close)
    c:initialise()
    self:addChild(c)
    self:rebuild(self:record())
end

function Window:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.backgroundColor = { r = 0.08, g = 0.09, b = 0.1, a = 0.92 }
    o.moveWithMouse = true
    o.buttons, o.lit = {}, {}
    return o
end

function Window.open(player, board)
    if Window.instance then Window.instance:close() end
    local k = LiveWire.UIScale.factor(BASE_W, 200)
    local w = BASE_W * k
    local x = getPlayerScreenLeft(player:getPlayerNum()) + 120
    local y = getPlayerScreenTop(player:getPlayerNum()) + 100
    local win = Window:new(x, y, w, 120 * k)
    win.lwK, win.player, win.board = k, player, board
    win:initialise()
    win:addToUIManager()
    Window.instance = win
    return win
end

-- Inverter software, House tab (Live Wire hook): energy of each breaker of the boards
-- linked to this inverter.
local function softwareLines(inverterId)
    local out = {}
    for _, r in pairs(X.Data.table().panels or {}) do
        if tostring(r.inv) == tostring(inverterId) then
            for _, slot in ipairs(r.slots or {}) do
                local m = B.meterSummary(slot)
                local name = slot.label ~= "" and slot.label or getText("IGUI_LWX_ModuleName", tostring(slot.pos))
                out[#out + 1] = getText("IGUI_LWX_SoftwareMeter", name, string.format("%.1f", m.today),
                    string.format("%.1f", m.yesterday))
            end
        end
    end
    return out
end

Events.OnGameStart.Add(function()
    if LiveWire.SoftwareApp then LiveWire.SoftwareApp.houseProvider = softwareLines end
end)
