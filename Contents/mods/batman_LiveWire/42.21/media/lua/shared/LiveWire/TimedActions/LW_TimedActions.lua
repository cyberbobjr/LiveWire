-- Live Wire: timed actions. Classes are global because NetTimedAction finds them by
-- name (NetTimedAction.java:145-172). new() parameter names must equal the fields
-- (NetTimedAction.java:47-55). The server never calls isValid: complete() re-checks
-- everything (knowledge/multiplayer.md:43-49, 230). complete() runs in single player
-- and on the server only (LuaTimedActionNew.java:158-163).

require "TimedActions/ISBaseTimedAction"

LiveWire = LiveWire or {}

local function I() return LiveWire.Install end
local function R() return LiveWire.Registry end

local function instant(character)
    return character:isTimedActionInstant()
end

local function objectStillThere(obj)
    return obj and obj:getSquare() and obj:getObjectIndex() ~= -1
end

-- Device record behind a placed object, checked against the registry.
local function deviceOf(obj)
    local m = LiveWire.Marks.get(obj)
    if not m then return nil end
    local dev = R() and R().device(m.id)
    if not dev then return nil end
    local sq = obj:getSquare()
    if not sq or dev.x ~= sq:getX() or dev.y ~= sq:getY() or dev.z ~= sq:getZ() then return nil end
    return dev
end

local function near(character, sq, range)
    if not sq then return false end
    if math.floor(character:getZ()) ~= sq:getZ() then return false end
    return math.abs(character:getX() - (sq:getX() + 0.5)) <= range + 0.5
        and math.abs(character:getY() - (sq:getY() + 0.5)) <= range + 0.5
end

local function allowed(character, sq)
    if not SafeHouse then return true end
    return SafeHouse.isSafehouseAllowInteract(sq, character)
end

--------------------------------------------------------------------------------
-- Link a source, a power bank, an optional device, a vanilla generator (backup)
-- or a vanilla desktop computer (management) to an inverter. Placing and picking
-- up the devices themselves is vanilla (furniture cursor, LW_Placement.lua).
--------------------------------------------------------------------------------
LWLinkAction = ISBaseTimedAction:derive("LWLinkAction")

function LWLinkAction:isValid()
    return objectStillThere(self.target) and objectStillThere(self.inverter)
        and I().checkLink(self.character, self.target, self.inverter)
end

function LWLinkAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function LWLinkAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWLinkAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
end

function LWLinkAction:stop() ISBaseTimedAction.stop(self) end
function LWLinkAction:perform() ISBaseTimedAction.perform(self) end

function LWLinkAction:complete()
    local ch, target, invObj = self.character, self.target, self.inverter
    if not objectStillThere(target) or not objectStillThere(invObj) then return false end
    local tsq = target:getSquare()
    if not near(ch, tsq, 2) or not allowed(ch, tsq) then return false end
    local ok, why, wires = I().checkLink(ch, target, invObj)
    if not ok then
        LiveWire.notify(ch, why, {}, true)
        return false
    end
    local inv = deviceOf(invObj)
    local grid = inv and inv.grid and R().grid(inv.grid)
    if not grid then return false end

    local kind = I().linkKind(target)
    if kind == "backup" or kind == "computer" then
        return LWLinkAction.linkVanilla(ch, target, kind, grid, wires)
    end

    -- Already on this network: nothing to do (no wire, no XP).
    local already = deviceOf(target)
    if already and already.grid == grid.id then
        LiveWire.notify(ch, "Tooltip_LW_AlreadyLinked", {}, true)
        return false
    end

    -- Breaker and alarm: one per network, checked before anything is consumed.
    local tdev = deviceOf(target)
    local tdef = tdev and LiveWire.Defs.devices[tdev.model]
    if not tdev or tdev.role == "inverter" then return false end
    if tdef and tdef.role == "option" and tdef.kind then
        local existing = R().hasOption(grid, tdef.kind)
        if existing and existing.id ~= tdev.id then
            LiveWire.notify(ch, "Tooltip_LW_OneOptionPerGrid", {}, true)
            return false
        end
    end
    if not I().consume(ch, "Base.ElectricWire", wires or 0) then return false end

    R().link(tdev, grid)
    LiveWire.Devices.syncMark(tdev)
    LiveWire.Xp.award(ch, 3)
    LiveWire.Sim.refresh(grid)
    LiveWire.notify(ch, "IGUI_LW_Linked", {})
    return true
end

-- A vanilla generator (backup power) or desktop computer (management computer):
-- one of each per network. The vanilla object is only marked in its ModData.
function LWLinkAction.linkVanilla(ch, target, kind, grid, wires)
    local m = I().vanillaMark(target)
    local old = m and R().device(m.id)
    if old and old.grid == grid.id then
        LiveWire.notify(ch, "Tooltip_LW_AlreadyLinked", {}, true)
        return false
    end
    local _, _, _, backups, computers = R().members(grid)
    local list = backups
    if kind == "computer" then list = computers end
    if #list > 0 then
        LiveWire.notify(ch, "Tooltip_LW_OneOptionPerGrid", {}, true)
        return false
    end
    if not I().consume(ch, "Base.ElectricWire", wires or 0) then return false end
    -- Linked to another network before: move it.
    if old then R().forgetVanilla(old) end
    if kind == "backup" then
        LiveWire.Backup.register(target, grid)
    else
        LiveWire.Computer.register(target, grid, I().level(ch))
    end
    LiveWire.Xp.award(ch, 3)
    LiveWire.Sim.refresh(grid)
    LiveWire.notify(ch, "IGUI_LW_Linked", {})
    return true
end

function LWLinkAction:getDuration()
    if instant(self.character) then return 1 end
    return 150
end

function LWLinkAction:new(character, target, inverter)
    local o = ISBaseTimedAction.new(self, character)
    o.target = target
    o.inverter = inverter
    o.maxTime = o:getDuration()
    return o
end

--------------------------------------------------------------------------------
-- Repair (overhaul = false) or overhaul (overhaul = true) a placed device.
--------------------------------------------------------------------------------
LWRepairAction = ISBaseTimedAction:derive("LWRepairAction")

LWRepairAction.OVERHAUL_LEVEL = 8

function LWRepairAction.parts(overhaul)
    if overhaul then return 4, 2 end
    return 1, 1
end

function LWRepairAction.canRepair(character, obj, overhaul)
    local m = LiveWire.Marks.get(obj)
    if not m then return false, "Tooltip_LW_Invalid" end
    if not I().screwdriver(character) then return false, "Tooltip_LW_NeedScrewdriver" end
    local scrap, wire = LWRepairAction.parts(overhaul)
    if I().countType(character, "Base.ElectronicsScrap") < scrap
        or I().countType(character, "Base.ElectricWire") < wire then
        return false, "Tooltip_LW_NeedParts"
    end
    if overhaul and not I().hasLevel(character, LWRepairAction.OVERHAUL_LEVEL) then
        return false, "Tooltip_LW_NeedLevel", LiveWire.Config.requiredLevel(LWRepairAction.OVERHAUL_LEVEL)
    end
    return true
end

function LWRepairAction:isValid()
    return objectStillThere(self.target) and LWRepairAction.canRepair(self.character, self.target, self.overhaul)
end

function LWRepairAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function LWRepairAction:update()
    self.character:setMetabolicTarget(Metabolics.UsingTools)
end

function LWRepairAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    self:setOverrideHandModels("Screwdriver", nil)
end

function LWRepairAction:stop() ISBaseTimedAction.stop(self) end
function LWRepairAction:perform() ISBaseTimedAction.perform(self) end

function LWRepairAction:complete()
    local ch, obj, overhaul = self.character, self.target, self.overhaul == true
    if not objectStillThere(obj) then return false end
    local sq = obj:getSquare()
    local dev = deviceOf(obj)
    if not dev or not near(ch, sq, 2) or not allowed(ch, sq) then return false end
    local ok, why = LWRepairAction.canRepair(ch, obj, overhaul)
    if not ok then
        LiveWire.notify(ch, why, {}, true)
        return false
    end
    if dev.role == "inverter" and dev.state == "on" and (dev.cond or 0) > 0 then
        LiveWire.notify(ch, "Tooltip_LW_TurnOffFirst", {}, true)
        return false
    end
    local cond = dev.cond or 0
    if not overhaul and cond >= 90 then
        LiveWire.notify(ch, "Tooltip_LW_NeedOverhaul", {}, true)
        return false
    end
    local scrap, wire = LWRepairAction.parts(overhaul)
    I().consume(ch, "Base.ElectronicsScrap", scrap)
    I().consume(ch, "Base.ElectricWire", wire)
    local level = I().level(ch)
    if not overhaul and ZombRand(100) < LiveWire.Defs.repairFailChance(level) then
        LiveWire.notify(ch, "IGUI_LW_RepairFailed", {}, true)
        return true
    end
    local newCond
    if overhaul then newCond = 100 else newCond = math.min(90, cond + 5 + level) end
    local gained = newCond - cond
    dev.cond = newCond
    if dev.role == "inverter" and dev.state == "broken" then dev.state = "off" end
    LiveWire.Xp.award(ch, math.min(15, 5 + math.floor(gained)))
    local grid = dev.grid and R().grid(dev.grid)
    if grid then LiveWire.Sim.refresh(grid) end
    LiveWire.notify(ch, "IGUI_LW_Repaired", { tostring(math.floor(newCond + 0.5)) })
    return true
end

function LWRepairAction:getDuration()
    if instant(self.character) then return 1 end
    local base = 250
    if self.overhaul then base = 400 end
    return math.max(100, base - I().level(self.character) * 5)
end

function LWRepairAction:new(character, target, overhaul)
    local o = ISBaseTimedAction.new(self, character)
    o.target = target
    o.overhaul = overhaul == true
    o.maxTime = o:getDuration()
    o.caloriesModifier = 4
    return o
end

--------------------------------------------------------------------------------
-- Inspect a placed device: report, small daily XP, wind brake from level 7.
--------------------------------------------------------------------------------
LWInspectAction = ISBaseTimedAction:derive("LWInspectAction")

LWInspectAction.BRAKE_LEVEL = 7

function LWInspectAction:isValid()
    return objectStillThere(self.target) and LiveWire.Marks.isOurs(self.target)
end

function LWInspectAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function LWInspectAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
end

function LWInspectAction:stop() ISBaseTimedAction.stop(self) end
function LWInspectAction:perform() ISBaseTimedAction.perform(self) end

function LWInspectAction:complete()
    local ch, obj = self.character, self.target
    if not objectStillThere(obj) then return false end
    local dev = deviceOf(obj)
    if not dev or not near(ch, obj:getSquare(), 3) then return false end
    local def = LiveWire.Defs.devices[dev.model] or {}
    local level = I().level(ch)
    if def.kind == "wind" and level >= LiveWire.Config.requiredLevel(LWInspectAction.BRAKE_LEVEL) then
        dev.brake = true
    end
    LiveWire.Xp.awardLimited(ch, "inspect:" .. dev.id, 2, 24)
    local cond = tostring(math.floor((dev.cond or 0) + 0.5))
    if def.role == "source" then
        LiveWire.notify(ch, "IGUI_LW_InspectSource",
            { "IGUI_LW_Model_" .. dev.model, cond, tostring(math.floor((dev.pOut or 0) + 0.5)),
              tostring(math.floor((dev.raw or 0) + 0.5)) })
    elseif def.role == "inverter" then
        LiveWire.notify(ch, "IGUI_LW_InspectInverter",
            { "IGUI_LW_Model_" .. dev.model, cond, "IGUI_LW_State_" .. tostring(dev.state) })
    else
        LiveWire.notify(ch, "IGUI_LW_InspectOther", { "IGUI_LW_Model_" .. dev.model, cond })
    end
    return true
end

function LWInspectAction:getDuration()
    if instant(self.character) then return 1 end
    return 100
end

function LWInspectAction:new(character, target)
    local o = ISBaseTimedAction.new(self, character)
    o.target = target
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    return o
end

--------------------------------------------------------------------------------
-- Fit (remove = false) or remove (remove = true) the soundproofing kit of an
-- inverter: silent for players and zombies, 25 % more wear.
--------------------------------------------------------------------------------
LWMuffleAction = ISBaseTimedAction:derive("LWMuffleAction")

function LWMuffleAction.canDo(character, obj, remove)
    local m = LiveWire.Marks.get(obj)
    if not m or not LiveWire.Defs.devices[m.model] or LiveWire.Defs.devices[m.model].role ~= "inverter" then
        return false, "Tooltip_LW_Invalid"
    end
    if not I().screwdriver(character) then return false, "Tooltip_LW_NeedScrewdriver" end
    if not remove and I().countType(character, LiveWire.Defs.SOUNDPROOF_KIT) <= 0 then
        return false, "Tooltip_LW_NeedSoundproofKit"
    end
    return true
end

function LWMuffleAction:isValid()
    return objectStillThere(self.target) and LWMuffleAction.canDo(self.character, self.target, self.remove)
end

function LWMuffleAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function LWMuffleAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWMuffleAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    self:setOverrideHandModels("Screwdriver", nil)
end

function LWMuffleAction:stop() ISBaseTimedAction.stop(self) end
function LWMuffleAction:perform() ISBaseTimedAction.perform(self) end

function LWMuffleAction:complete()
    local ch, obj, remove = self.character, self.target, self.remove == true
    if not objectStillThere(obj) then return false end
    local dev = deviceOf(obj)
    if not dev or dev.role ~= "inverter" or not near(ch, obj:getSquare(), 2) or not allowed(ch, obj:getSquare()) then
        return false
    end
    local ok, why = LWMuffleAction.canDo(ch, obj, remove)
    if not ok then
        LiveWire.notify(ch, why, {}, true)
        return false
    end
    if remove then
        if not dev.muffled then return false end
        dev.muffled = nil
        I().giveItem(ch, LiveWire.Defs.SOUNDPROOF_KIT)
        LiveWire.notify(ch, "IGUI_LW_Unmuffled", {})
    else
        if dev.muffled then return false end
        if not I().consume(ch, LiveWire.Defs.SOUNDPROOF_KIT, 1) then return false end
        dev.muffled = true
        LiveWire.Xp.award(ch, 3)
        LiveWire.notify(ch, "IGUI_LW_Muffled", {})
    end
    LiveWire.Devices.syncMark(dev)
    return true
end

function LWMuffleAction:getDuration()
    if instant(self.character) then return 1 end
    return 200
end

function LWMuffleAction:new(character, target, remove)
    local o = ISBaseTimedAction.new(self, character)
    o.target = target
    o.remove = remove == true
    o.maxTime = o:getDuration()
    return o
end

--------------------------------------------------------------------------------
-- Clear the snow from a solar panel.
--------------------------------------------------------------------------------
LWClearSnowAction = ISBaseTimedAction:derive("LWClearSnowAction")

function LWClearSnowAction:isValid()
    return objectStillThere(self.target) and LiveWire.Marks.isOurs(self.target)
end

function LWClearSnowAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function LWClearSnowAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWClearSnowAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
end

function LWClearSnowAction:stop() ISBaseTimedAction.stop(self) end
function LWClearSnowAction:perform() ISBaseTimedAction.perform(self) end

function LWClearSnowAction:complete()
    local ch, obj = self.character, self.target
    if not objectStillThere(obj) then return false end
    local dev = deviceOf(obj)
    if not dev or not near(ch, obj:getSquare(), 2) then return false end
    dev.snow = 0
    return true
end

function LWClearSnowAction:getDuration()
    if instant(self.character) then return 1 end
    return 120
end

function LWClearSnowAction:new(character, target)
    local o = ISBaseTimedAction.new(self, character)
    o.target = target
    o.maxTime = o:getDuration()
    return o
end

--------------------------------------------------------------------------------
-- Measure a square with the voltage tester.
--------------------------------------------------------------------------------
LWMeasureAction = ISBaseTimedAction:derive("LWMeasureAction")

function LWMeasureAction:isValid()
    return self.square ~= nil and I().countType(self.character, "LiveWire.VoltageTester") > 0
end

function LWMeasureAction:waitToStart()
    self.character:faceLocation(self.square:getX(), self.square:getY())
    return self.character:shouldBeTurning()
end

function LWMeasureAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
end

function LWMeasureAction:stop() ISBaseTimedAction.stop(self) end
function LWMeasureAction:perform() ISBaseTimedAction.perform(self) end

-- Which source powers a square (authority side, also correct in single player).
local function powerSource(sq)
    if sq:hasGridPower() and sq:getRoom() ~= nil then return "IGUI_LW_Measure_Source_Grid" end
    if not sq:haveElectricity() then return nil end
    local Rg = R()
    if Rg then
        local range = LiveWire.Config.tileRange()
        local V = LiveWire.Config.verticalRange()
        for id, a in pairs(Rg.anchors or {}) do
            if a.on then
                local dx, dy = sq:getX() - a.x, sq:getY() - a.y
                if dx * dx + dy * dy <= range * range and math.abs(sq:getZ() - a.z) <= V then
                    return "IGUI_LW_Measure_Source_LiveWire"
                end
            end
        end
    end
    return "IGUI_LW_Measure_Source_Generator"
end

function LWMeasureAction:complete()
    local ch, sq = self.character, self.square
    if not sq or not near(ch, sq, 2) then return false end
    if I().countType(ch, "LiveWire.VoltageTester") <= 0 then return false end
    local level = I().level(ch)
    local source = powerSource(sq)
    if not source then
        LiveWire.notify(ch, "IGUI_LW_Measure_NoPower", {})
    elseif level < 1 then
        LiveWire.notify(ch, "IGUI_LW_Measure_Powered", {})
    else
        LiveWire.notify(ch, source, {})
    end
    if level >= 2 then
        local objs = sq:getObjects()
        local best = 0
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            if o:couldBePoweredByGenerator() then
                best = math.max(best, o:getGeneratorPowerConsumption() or 0)
            end
        end
        if best > 0 then
            local w = math.floor(best * 1000 * LiveWire.Config.get("PowerScale") + 0.5)
            LiveWire.notify(ch, "IGUI_LW_Measure_Draw", { tostring(w) })
        end
    end
    if level >= 4 then
        local obj = LiveWire.Marks.firstOnSquare(sq)
        local dev = obj and deviceOf(obj)
        local grid = dev and dev.grid and R().grid(dev.grid)
        if grid then
            local snap = LiveWire.Sim.snapshot(grid)
            if snap then
                local auto = "-"
                if snap.autonomyH then auto = tostring(math.floor(snap.autonomyH + 0.5)) end
                LiveWire.notify(ch, "IGUI_LW_Measure_Grid",
                    { tostring(snap.production), tostring(snap.demand),
                      string.format("%.2f", snap.stock), auto })
            end
        end
    end
    LiveWire.Xp.awardLimited(ch, "measure:" .. sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ(), 1, 1)
    return true
end

function LWMeasureAction:getDuration()
    if instant(self.character) then return 1 end
    return 60
end

function LWMeasureAction:new(character, square)
    local o = ISBaseTimedAction.new(self, character)
    o.square = square
    o.maxTime = o:getDuration()
    return o
end

--------------------------------------------------------------------------------
-- Recondition a battery held in the inventory (level 4).
--------------------------------------------------------------------------------
LWReconditionAction = ISBaseTimedAction:derive("LWReconditionAction")

LWReconditionAction.LEVEL = 4
LWReconditionAction.WATER_LITRES = 0.5
LWReconditionAction.MAX_COND = 80
LWReconditionAction.GAIN = 15

local function isWater(item)
    local fc = item:getFluidContainer()
    return fc ~= nil and fc:getSpecificFluidAmount(Fluid.Water) >= LWReconditionAction.WATER_LITRES
end

local function waterSource(character)
    return character:getInventory():getFirstEvalRecurse(isWater)
end

function LWReconditionAction.canRecondition(character, item)
    if not item or not LiveWire.Defs.isBattery(item:getFullType()) then return false, "Tooltip_LW_NotABattery" end
    if item:getCondition() <= 0 then return false, "Tooltip_LW_DeadBattery" end
    if item:getCondition() >= LWReconditionAction.MAX_COND then return false, "Tooltip_LW_TooGood" end
    if not I().hasLevel(character, LWReconditionAction.LEVEL) then
        return false, "Tooltip_LW_NeedLevel", LiveWire.Config.requiredLevel(LWReconditionAction.LEVEL)
    end
    if I().countType(character, "Base.ElectronicsScrap") < 1 then return false, "Tooltip_LW_NeedParts" end
    if not waterSource(character) then return false, "Tooltip_LW_NeedWater" end
    return true
end

function LWReconditionAction:isValid()
    return self.character:getInventory():containsRecursive(self.item)
        and LWReconditionAction.canRecondition(self.character, self.item)
end

function LWReconditionAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWReconditionAction:start()
    self:setActionAnim(CharacterActionAnims.Craft)
end

function LWReconditionAction:stop() ISBaseTimedAction.stop(self) end
function LWReconditionAction:perform() ISBaseTimedAction.perform(self) end

function LWReconditionAction:complete()
    local ch, item = self.character, self.item
    if not item or not ch:getInventory():containsRecursive(item) then return false end
    local ok, why = LWReconditionAction.canRecondition(ch, item)
    if not ok then
        LiveWire.notify(ch, why, {}, true)
        return false
    end
    local water = waterSource(ch)
    local fc = water:getFluidContainer()
    -- Remove water only (adjustAmount would scale every fluid, FluidContainer.java:647-660).
    fc:adjustSpecificFluidAmount(Fluid.Water,
        fc:getSpecificFluidAmount(Fluid.Water) - LWReconditionAction.WATER_LITRES)
    water:syncItemFields()
    I().consume(ch, "Base.ElectronicsScrap", 1)
    local newCond = math.min(LWReconditionAction.MAX_COND, item:getCondition() + LWReconditionAction.GAIN)
    item:setConditionNoSound(newCond)
    syncItemFields(ch, item)
    LiveWire.Xp.award(ch, 8)
    LiveWire.notify(ch, "IGUI_LW_Reconditioned", { tostring(newCond) })
    return true
end

function LWReconditionAction:getDuration()
    if instant(self.character) then return 1 end
    return 300
end

function LWReconditionAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.maxTime = o:getDuration()
    return o
end
