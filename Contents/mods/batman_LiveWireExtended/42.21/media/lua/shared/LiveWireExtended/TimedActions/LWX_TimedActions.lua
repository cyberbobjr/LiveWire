-- LiveWire Extended: timed actions. Global classes: NetTimedAction finds them by name
-- and new() parameter names equal the fields (NetTimedAction.java:47-55, 145-172).
-- complete() runs in single player and on the server only, and re-checks everything.
require "LiveWire/TimedActions/LW_BaseAction"
require "LiveWireExtended/LWX_Core"
require "LiveWireExtended/LWX_Inverters"
require "LiveWireExtended/LWX_Terminal"
require "LiveWireExtended/LWX_Panel"
require "LiveWireExtended/LWX_Breakers"
require "LiveWireExtended/LWX_Points"

local X = LiveWire.Extended

local stillThere = LWBaseAction.objectStillThere

--------------------------------------------------------------------------------
-- Connect the building of an inverter, or disconnect one of its areas.
--------------------------------------------------------------------------------
LWXBuildingAction = LWBaseAction:derive("LWXBuildingAction")
LWXBuildingAction.duration = 300
LWXBuildingAction.subject = "target"
LWXBuildingAction.facing = true

function LWXBuildingAction:isValid() return stillThere(self.target) end

function LWXBuildingAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWXBuildingAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
end

function LWXBuildingAction:complete()
    if not self:guard() or not X.Connect then return false end
    local ch, obj = self.character, self.target
    local sq = obj:getSquare()
    if X.Terminal.isTerminal(obj) then
        -- Relay: the building the terminal touches, fed by the terminal's inverter (E8).
        if not X.Terminals then return false end
        local t = X.Terminal.recordAt(sq)
        local dev = t and X.Inverters.get(t.inv)
        if self.disconnect then return dev ~= nil and X.Connect.disconnect(ch, dev, self.areaKey) end
        return X.Terminals.connectBuilding(ch, obj)
    end
    local dev = X.Inverters.ofObject(obj)
    if not dev then return false end
    if self.disconnect then return X.Connect.disconnect(ch, dev, self.areaKey) end
    return X.Connect.connectBuilding(ch, dev, dev.x, dev.y, dev.z, LiveWire.Config.tileRange(), nil)
end

function LWXBuildingAction:new(character, target, disconnect, areaKey)
    return LWBaseAction.new(self, character, { target = target, disconnect = disconnect == true, areaKey = areaKey })
end

--------------------------------------------------------------------------------
-- Link a power terminal or a breaker board to an inverter with electric wire, or
-- unlink it (LWX_Link kinds).
--------------------------------------------------------------------------------
LWXTerminalAction = LWBaseAction:derive("LWXTerminalAction")
LWXTerminalAction.duration = 250
LWXTerminalAction.subject = "target"
LWXTerminalAction.facing = true

function LWXTerminalAction:isValid()
    return stillThere(self.target) and (self.unlink or stillThere(self.inverter))
end

function LWXTerminalAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWXTerminalAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    self:setOverrideHandModels("Screwdriver", nil)
end

function LWXTerminalAction:complete()
    if not self:guard() or not X.Linked then return false end
    local ch, obj = self.character, self.target
    if not X.Link.kindOf(obj) then return false end
    if self.unlink then return X.Linked.unlink(ch, obj) end
    if not stillThere(self.inverter) then return false end
    return X.Linked.link(ch, obj, self.inverter)
end

function LWXTerminalAction:new(character, target, inverter, unlink)
    return LWBaseAction.new(self, character, { target = target, inverter = inverter, unlink = unlink == true })
end

--------------------------------------------------------------------------------
-- Set the zone of a linked terminal (rectangle drawn with LWX_ZoneTool).
--------------------------------------------------------------------------------
LWXZoneAction = LWBaseAction:derive("LWXZoneAction")
LWXZoneAction.duration = 150
LWXZoneAction.subject = "target"
LWXZoneAction.facing = true

function LWXZoneAction:isValid() return stillThere(self.target) end

function LWXZoneAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWXZoneAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    self:setOverrideHandModels("Screwdriver", nil)
end

function LWXZoneAction:complete()
    if not self:guard() or not X.Terminals then return false end
    local ch, obj = self.character, self.target
    if not X.Terminal.isTerminal(obj) then return false end
    local n = { tonumber(self.x0), tonumber(self.y0), tonumber(self.x1), tonumber(self.y1) }
    for i = 1, 4 do
        if not n[i] or n[i] ~= n[i] or math.abs(n[i]) > 1000000 then return false end
    end
    return X.Terminals.setZone(ch, obj, n[1], n[2], n[3], n[4])
end

function LWXZoneAction:new(character, target, x0, y0, x1, y1)
    return LWBaseAction.new(self, character, { target = target, x0 = x0, y0 = y0, x1 = x1, y1 = y1 })
end

--------------------------------------------------------------------------------
-- Install a breaker item in a linked board, remove the breaker of a module, or switch
-- it (mode nil = install, "remove", "on", "off").
--------------------------------------------------------------------------------
LWXBreakerAction = LWBaseAction:derive("LWXBreakerAction")
LWXBreakerAction.duration = 200
LWXBreakerAction.subject = "target"
LWXBreakerAction.facing = true

function LWXBreakerAction:isValid()
    if not stillThere(self.target) then return false end
    if self.mode == "label" then return X.Breakers.hasPen(self.character) end
    return self.mode == "on" or self.mode == "off" or LiveWire.API.screwdriver(self.character) ~= nil
end

function LWXBreakerAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWXBreakerAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    if self.mode ~= "on" and self.mode ~= "off" and self.mode ~= "label" then LiveWire.API.showScrewdriver(self) end
end

function LWXBreakerAction:complete()
    if not self:guard() or not X.Panels then return false end
    local ch, obj = self.character, self.target
    if not X.Panel.isPanel(obj) then return false end
    if self.mode == "remove" then return X.Panels.removeBreaker(ch, obj, tonumber(self.pos)) end
    if self.mode == "on" or self.mode == "off" then
        return X.Panels.setBreaker ~= nil and X.Panels.setBreaker(ch, obj, tonumber(self.pos), self.mode == "off")
    end
    if self.mode == "label" then
        return X.Panels.setLabel ~= nil and X.Panels.setLabel(ch, obj, tonumber(self.pos), self.text)
    end
    if self.mode == "twilightOn" or self.mode == "twilightOff" then
        return X.Panels.setTwilight ~= nil and X.Panels.setTwilight(ch, obj, tonumber(self.pos), self.mode == "twilightOn")
    end
    if type(self.fullType) ~= "string" or not X.Breakers.TYPES[self.fullType] then return false end
    return X.Panels.installBreaker(ch, obj, self.fullType, tonumber(self.pos))
end

-- The length depends on the mode; 200 (the class duration) is install and remove.
function LWXBreakerAction:getDuration()
    if LWBaseAction.instant(self.character) then return 1 end
    if self.mode == "on" or self.mode == "off" then return 30 end
    if self.mode == "label" then return 100 end
    return self.duration
end

function LWXBreakerAction:new(character, target, fullType, pos, mode, text)
    return LWBaseAction.new(self, character, { target = target, fullType = fullType, pos = pos, mode = mode, text = text })
end

--------------------------------------------------------------------------------
-- Wire a point (appliance, multi-tile appliance, room) to a breaker, or unwire it.
-- The action targets the appliance; the board is checked again on the authority.
--------------------------------------------------------------------------------
LWXPointAction = LWBaseAction:derive("LWXPointAction")
LWXPointAction.duration = 250
LWXPointAction.subject = "target"
LWXPointAction.facing = true

function LWXPointAction:isValid()
    return stillThere(self.target) and (self.disconnect or stillThere(self.board))
end

function LWXPointAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWXPointAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    LiveWire.API.showScrewdriver(self)
end

function LWXPointAction:complete()
    if not self:guard() or not X.Points.connect then return false end
    local ch, obj = self.character, self.target
    if not X.Adapters.find(obj) then return false end
    if self.disconnect then return X.Points.disconnect(ch, obj) end
    if not stillThere(self.board) or not X.Panel.isPanel(self.board) then return false end
    return X.Points.connect(ch, obj, self.board, tonumber(self.pos))
end

function LWXPointAction:new(character, target, board, pos, disconnect)
    return LWBaseAction.new(self, character, { target = target, board = board, pos = pos, disconnect = disconnect == true })
end

--------------------------------------------------------------------------------
-- Enlarge a placed board one size on its spot (D-55): 8 -> 16, 16 -> 24.
--------------------------------------------------------------------------------
LWXEnlargeAction = LWBaseAction:derive("LWXEnlargeAction")
LWXEnlargeAction.duration = 300
LWXEnlargeAction.subject = "target"
LWXEnlargeAction.facing = true

function LWXEnlargeAction:isValid()
    return stillThere(self.target) and LiveWire.API.screwdriver(self.character) ~= nil
end

function LWXEnlargeAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWXEnlargeAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    self:setOverrideHandModels("Screwdriver", nil)
end

function LWXEnlargeAction:complete()
    if not self:guard() or not X.Panels then return false end
    return X.Panels.enlarge(self.character, self.target)
end

function LWXEnlargeAction:new(character, target)
    return LWBaseAction.new(self, character, { target = target })
end
