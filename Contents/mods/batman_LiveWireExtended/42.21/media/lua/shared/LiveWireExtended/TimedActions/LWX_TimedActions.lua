-- LiveWire Extended: timed actions. Global classes: NetTimedAction finds them by name
-- and new() parameter names equal the fields (NetTimedAction.java:47-55, 145-172).
-- complete() runs in single player and on the server only, and re-checks everything.
require "TimedActions/ISBaseTimedAction"
require "LiveWireExtended/LWX_Core"
require "LiveWireExtended/LWX_Terminal"
require "LiveWireExtended/LWX_Panel"
require "LiveWireExtended/LWX_Breakers"

local X = LiveWire.Extended

local function stillThere(obj)
    return obj and obj:getSquare() and obj:getObjectIndex() ~= -1
end

local function near(character, sq, range)
    if not sq or math.floor(character:getZ()) ~= sq:getZ() then return false end
    return math.abs(character:getX() - (sq:getX() + 0.5)) <= range + 0.5
        and math.abs(character:getY() - (sq:getY() + 0.5)) <= range + 0.5
end

local function allowed(character, sq)
    if not SafeHouse then return true end
    return SafeHouse.isSafehouseAllowInteract(sq, character)
end

--------------------------------------------------------------------------------
-- Connect the building of an inverter, or disconnect one of its areas.
--------------------------------------------------------------------------------
LWXBuildingAction = ISBaseTimedAction:derive("LWXBuildingAction")

function LWXBuildingAction:isValid() return stillThere(self.target) end

function LWXBuildingAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function LWXBuildingAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWXBuildingAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
end

function LWXBuildingAction:stop() ISBaseTimedAction.stop(self) end
function LWXBuildingAction:perform() ISBaseTimedAction.perform(self) end

function LWXBuildingAction:complete()
    local ch, obj = self.character, self.target
    if not stillThere(obj) or not X.Connect then return false end
    local sq = obj:getSquare()
    if not near(ch, sq, 2) or not allowed(ch, sq) then return false end
    if X.Terminal.isTerminal(obj) then
        -- Relay: the building the terminal touches, fed by the terminal's inverter (E8).
        if not X.Terminals then return false end
        local t = X.Terminal.recordAt(sq)
        local dev = t and X.Connect.inverter(t.inv)
        if self.disconnect then return dev ~= nil and X.Connect.disconnect(ch, dev, self.areaKey) end
        return X.Terminals.connectBuilding(ch, obj)
    end
    local dev = X.inverterOf(obj)
    if not dev then return false end
    if self.disconnect then return X.Connect.disconnect(ch, dev, self.areaKey) end
    return X.Connect.connectBuilding(ch, dev, dev.x, dev.y, dev.z, LiveWire.Config.tileRange(), nil)
end

function LWXBuildingAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 300
end

function LWXBuildingAction:new(character, target, disconnect, areaKey)
    local o = ISBaseTimedAction.new(self, character)
    o.target = target
    o.disconnect = disconnect == true
    o.areaKey = areaKey
    o.maxTime = o:getDuration()
    return o
end

--------------------------------------------------------------------------------
-- Link a power terminal or a breaker board to an inverter with electric wire, or
-- unlink it (LWX_Link kinds).
--------------------------------------------------------------------------------
LWXTerminalAction = ISBaseTimedAction:derive("LWXTerminalAction")

function LWXTerminalAction:isValid()
    return stillThere(self.target) and (self.unlink or stillThere(self.inverter))
end

function LWXTerminalAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function LWXTerminalAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWXTerminalAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    self:setOverrideHandModels("Screwdriver", nil)
end

function LWXTerminalAction:stop() ISBaseTimedAction.stop(self) end
function LWXTerminalAction:perform() ISBaseTimedAction.perform(self) end

function LWXTerminalAction:complete()
    local ch, obj = self.character, self.target
    if not stillThere(obj) or not X.Linked or not X.Link.kindOf(obj) then return false end
    local sq = obj:getSquare()
    if not near(ch, sq, 2) or not allowed(ch, sq) then return false end
    if self.unlink then return X.Linked.unlink(ch, obj) end
    if not stillThere(self.inverter) then return false end
    return X.Linked.link(ch, obj, self.inverter)
end

function LWXTerminalAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 250
end

function LWXTerminalAction:new(character, target, inverter, unlink)
    local o = ISBaseTimedAction.new(self, character)
    o.target = target
    o.inverter = inverter
    o.unlink = unlink == true
    o.maxTime = o:getDuration()
    return o
end

--------------------------------------------------------------------------------
-- Set the zone of a linked terminal (rectangle drawn with LWX_ZoneTool).
--------------------------------------------------------------------------------
LWXZoneAction = ISBaseTimedAction:derive("LWXZoneAction")

function LWXZoneAction:isValid() return stillThere(self.target) end

function LWXZoneAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function LWXZoneAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWXZoneAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    self:setOverrideHandModels("Screwdriver", nil)
end

function LWXZoneAction:stop() ISBaseTimedAction.stop(self) end
function LWXZoneAction:perform() ISBaseTimedAction.perform(self) end

function LWXZoneAction:complete()
    local ch, obj = self.character, self.target
    if not stillThere(obj) or not X.Terminals or not X.Terminal.isTerminal(obj) then return false end
    local sq = obj:getSquare()
    if not near(ch, sq, 2) or not allowed(ch, sq) then return false end
    local n = { tonumber(self.x0), tonumber(self.y0), tonumber(self.x1), tonumber(self.y1) }
    for i = 1, 4 do
        if not n[i] or n[i] ~= n[i] or math.abs(n[i]) > 1000000 then return false end
    end
    return X.Terminals.setZone(ch, obj, n[1], n[2], n[3], n[4])
end

function LWXZoneAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 150
end

function LWXZoneAction:new(character, target, x0, y0, x1, y1)
    local o = ISBaseTimedAction.new(self, character)
    o.target = target
    o.x0, o.y0, o.x1, o.y1 = x0, y0, x1, y1
    o.maxTime = o:getDuration()
    return o
end

--------------------------------------------------------------------------------
-- Install a breaker item in a linked board, or remove the breaker of a module.
--------------------------------------------------------------------------------
LWXBreakerAction = ISBaseTimedAction:derive("LWXBreakerAction")

function LWXBreakerAction:isValid()
    return stillThere(self.target) and LiveWire.Install.screwdriver(self.character) ~= nil
end

function LWXBreakerAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function LWXBreakerAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWXBreakerAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    LiveWire.Install.showScrewdriver(self)
end

function LWXBreakerAction:stop() ISBaseTimedAction.stop(self) end
function LWXBreakerAction:perform() ISBaseTimedAction.perform(self) end

function LWXBreakerAction:complete()
    local ch, obj = self.character, self.target
    if not stillThere(obj) or not X.Panels or not X.Panel.isPanel(obj) then return false end
    local sq = obj:getSquare()
    if not near(ch, sq, 2) or not allowed(ch, sq) then return false end
    if self.remove then return X.Panels.removeBreaker(ch, obj, tonumber(self.pos)) end
    if type(self.fullType) ~= "string" or not X.Breakers.TYPES[self.fullType] then return false end
    return X.Panels.installBreaker(ch, obj, self.fullType)
end

function LWXBreakerAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 200
end

function LWXBreakerAction:new(character, target, fullType, pos, remove)
    local o = ISBaseTimedAction.new(self, character)
    o.target = target
    o.fullType = fullType
    o.pos = pos
    o.remove = remove == true
    o.maxTime = o:getDuration()
    return o
end
