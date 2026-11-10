-- Live Wire: timed actions. Classes are global because NetTimedAction finds them by
-- name (NetTimedAction.java:145-172). new() parameter names must equal the fields
-- (NetTimedAction.java:47-55). The server never calls isValid: complete() re-checks
-- everything (knowledge/multiplayer.md:43-49, 230). complete() runs in single player
-- and on the server only (LuaTimedActionNew.java:158-163).

require "LiveWire/TimedActions/LW_BaseAction"

LiveWire = LiveWire or {}

local function I() return LiveWire.Install end
local function R() return LiveWire.Registry end

local instant = LWBaseAction.instant
local objectStillThere = LWBaseAction.objectStillThere

-- Item types used by several actions.
local ELECTRIC_WIRE = "Base.ElectricWire"
local ELECTRONICS_SCRAP = "Base.ElectronicsScrap"
local VOLTAGE_TESTER = "LiveWire.VoltageTester"

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


--------------------------------------------------------------------------------
-- Link a source, a power bank, an optional device, a vanilla generator (backup)
-- or a vanilla desktop computer (management) to an inverter. Placing and picking
-- up the devices themselves is vanilla (furniture cursor, LW_Placement.lua).
--------------------------------------------------------------------------------
-- GUI disconnection can walk to the equipment before using the existing command.
LWUnlinkAction = LWBaseAction:derive("LWUnlinkAction")
LWUnlinkAction.duration = 1
LWUnlinkAction.subject = "target"
function LWUnlinkAction:isValid() return objectStillThere(self.target) end
function LWUnlinkAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    I().showScrewdriver(self)
end
function LWUnlinkAction:complete()
    if not self:guard() then return false end
    local m=LiveWire.Marks.get(self.target) or I().vanillaMark(self.target)
    if not m or m.id~=self.device then return false end
    LiveWire.Commands.handle(self.character,LiveWire.Protocol.C_UNLINK,{device=self.device})
    return true
end
function LWUnlinkAction:new(character,target,device)
    return LWBaseAction.new(self,character,{target=target,device=device})
end

LWLinkAction = LWBaseAction:derive("LWLinkAction")
LWLinkAction.duration = 150
LWLinkAction.subject = "target"
LWLinkAction.partners = { "inverter" }
LWLinkAction.facing = true

function LWLinkAction:isValid()
    return objectStillThere(self.target) and objectStillThere(self.inverter)
        and I().checkLink(self.character, self.target, self.inverter)
end

function LWLinkAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWLinkAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    I().showScrewdriver(self)
end

function LWLinkAction:complete()
    if not self:guard() then return false end
    local ch, target, invObj = self.character, self.target, self.inverter
    local ok, why, wires, extra = I().checkLink(ch, target, invObj)
    if not ok then
        -- On refusal the third and fourth results are the message arguments.
        LiveWire.notify(ch, why, { wires, extra }, true)
        LiveWire.log("link refused for " .. tostring(ch:getUsername()) .. ": " .. tostring(why)
            .. " " .. tostring(wires or "") .. " " .. tostring(extra or ""))
        return false
    end
    local inv = deviceOf(invObj)
    local grid = inv and inv.grid and R().grid(inv.grid)
    if not grid then return false end

    local kind = I().linkKind(target)
    if LiveWire.Maintenance.liveWork(ch, grid) then return false end
    if kind == "backup" or kind == "computer" then
        return LWLinkAction.linkVanilla(ch, target, kind, grid, wires, inv)
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
    if not I().consume(ch, ELECTRIC_WIRE, wires or 0) then return false end
    -- Moved from another network: the old cable comes back.
    local oldWires = LiveWire.Devices.linkWires(tdev)

    R().link(tdev, grid)
    tdev.wires = wires or 0  -- given back when the link is undone (Devices.linkWires)
    local xp = LiveWire.Devices.wired(ch, tdev, inv)
    LiveWire.Devices.syncMark(tdev)
    LiveWire.Devices.syncMark(inv)
    if tdef and tdef.role == "pump" and LiveWire.Pump then LiveWire.Pump.maintain(tdev) end
    LiveWire.Xp.award(ch, xp)
    LiveWire.Sim.refresh(grid)
    LiveWire.notify(ch, "IGUI_LW_Linked", {})
    LiveWire.Devices.returnWires(ch, oldWires)
    return true
end

-- A vanilla generator (backup power) or desktop computer (management computer):
-- one of each per network. The vanilla object is only marked in its ModData.
function LWLinkAction.linkVanilla(ch, target, kind, grid, wires, inv)
    local m = I().vanillaMark(target)
    local old = m and R().device(m.id)
    if old and old.grid == grid.id then
        LiveWire.notify(ch, "Tooltip_LW_AlreadyLinked", {}, true)
        return false
    end
    local list = R().membersByRole(grid, kind == "computer" and "computer" or "backup")
    if #list > 0 then
        LiveWire.notify(ch, "Tooltip_LW_OneOptionPerGrid", {}, true)
        return false
    end
    if not I().consume(ch, ELECTRIC_WIRE, wires or 0) then return false end
    -- Linked to another network before: move it, its old cable comes back.
    local oldWires = LiveWire.Devices.linkWires(old)
    if old then R().forgetVanilla(old) end
    local dev
    if kind == "backup" then
        dev = LiveWire.Backup.register(target, grid)
    else
        dev = LiveWire.Computer.register(target, grid, I().level(ch))
    end
    if dev then dev.wires = wires or 0 end
    local xp = inv and LiveWire.Devices.wired(ch, nil, inv) or 0
    if inv then LiveWire.Devices.syncMark(inv) end
    LiveWire.Xp.award(ch, 3 + xp)
    LiveWire.Sim.refresh(grid)
    LiveWire.notify(ch, "IGUI_LW_Linked", {})
    LiveWire.Devices.returnWires(ch, oldWires)
    return true
end

function LWLinkAction:new(character, target, inverter)
    return LWBaseAction.new(self, character, { target = target, inverter = inverter })
end

--------------------------------------------------------------------------------
-- Couple an inverter (slave) to a master inverter (docs/annexes/conception/choix-et-extensions.md, section 5): the
-- slave loses its own grid and anchor and joins the master's grid. complete() runs
-- on the authority only.
--------------------------------------------------------------------------------
LWCoupleAction = LWBaseAction:derive("LWCoupleAction")
LWCoupleAction.duration = 150
LWCoupleAction.subject = "slave"
LWCoupleAction.partners = { "master" }
LWCoupleAction.facing = true

function LWCoupleAction:isValid()
    return objectStillThere(self.slave) and objectStillThere(self.master)
        and I().checkCouple(self.character, self.slave, self.master)
end

function LWCoupleAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWCoupleAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    I().showScrewdriver(self)
end

function LWCoupleAction:complete()
    if not self:guard() then return false end
    local ch, slaveObj, masterObj = self.character, self.slave, self.master
    local ok, why, wires, extra = I().checkCouple(ch, slaveObj, masterObj)
    if not ok then
        -- On refusal the third and fourth results are the message arguments.
        LiveWire.notify(ch, why, { wires, extra }, true)
        LiveWire.log("couple refused for " .. tostring(ch:getUsername()) .. ": " .. tostring(why)
            .. " " .. tostring(wires or "") .. " " .. tostring(extra or ""))
        return false
    end
    local sdev, mdev = deviceOf(slaveObj), deviceOf(masterObj)
    if not sdev or not mdev or sdev.role ~= "inverter" or mdev.role ~= "inverter"
        or sdev.coupled ~= nil or mdev.coupled ~= nil then
        return false
    end

    -- The slave owns no equipment and no slave of its own (the registry is only
    -- visible here, not on the client).
    local sgrid = sdev.grid and R().grid(sdev.grid)
    if not sgrid then return false end
    local owned = 0
    for _, list in pairs(R().members(sgrid)) do owned = owned + #list end
    if owned > 0 or #R().slaves(sgrid) > 0 then
        LiveWire.notify(ch, "Tooltip_LW_CoupleHasEquipment", {}, true)
        return false
    end
    local mgrid = mdev.grid and R().grid(mdev.grid)
    if not mgrid then return false end
    if #R().slaves(mgrid) >= LiveWire.Defs.MAX_SLAVES then
        LiveWire.notify(ch, "Tooltip_LW_TooManySlaves", { tostring(LiveWire.Defs.MAX_SLAVES) }, true)
        return false
    end

    if not I().consume(ch, ELECTRIC_WIRE, wires or 0) then return false end
    if not I().consume(ch, LiveWire.Defs.COUPLING_KIT, 1) then return false end
    -- The slave's anchor goes off, as when its device is removed (Devices.remove).
    LiveWire.Sim.updateAnchor(sdev, false)
    LiveWire.Anchor.set(sdev.id, R().anchors[sdev.id] or sdev, false)
    LiveWire.Demand.invalidate(sdev.id)
    R().couple(sdev, mgrid)
    sdev.wires = wires or 0
    local xp = LiveWire.Devices.wired(ch, sdev, mdev)
    LiveWire.Devices.syncMark(sdev)
    LiveWire.Devices.syncMark(mdev)
    LiveWire.Xp.award(ch, 5 + xp)
    LiveWire.Sim.refresh(mgrid)
    LiveWire.notify(ch, "IGUI_LW_Coupled", {})
    return true
end

function LWCoupleAction:new(character, slave, master)
    return LWBaseAction.new(self, character, { slave = slave, master = master })
end

--------------------------------------------------------------------------------
-- Connect a water barrel to a water pump (one metal pipe, LW_Pump.lua). The
-- barrel must stand next to the pump. complete() runs on the authority only.
--------------------------------------------------------------------------------
LWLinkBarrelAction = LWBaseAction:derive("LWLinkBarrelAction")
LWLinkBarrelAction.duration = 150
LWLinkBarrelAction.subject = "barrel"
LWLinkBarrelAction.partners = { "pump" }
LWLinkBarrelAction.facing = true

function LWLinkBarrelAction:isValid()
    return objectStillThere(self.barrel) and objectStillThere(self.pump)
        and I().checkBarrelLink(self.character, self.barrel, self.pump)
end

function LWLinkBarrelAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWLinkBarrelAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
end

function LWLinkBarrelAction:complete()
    if not self:guard() then return false end
    local ch, barrel, pumpObj = self.character, self.barrel, self.pump
    if not LiveWire.Pump then return false end
    local ok, why = I().checkBarrelLink(ch, barrel, pumpObj)
    if not ok then
        LiveWire.notify(ch, why, {}, true)
        LiveWire.log("barrel link refused for " .. tostring(ch:getUsername()) .. ": " .. tostring(why))
        return false
    end
    local dev = deviceOf(pumpObj)
    local def = dev and LiveWire.Defs.devices[dev.model]
    if not dev or not def or def.role ~= "pump" then return false end
    if not I().consume(ch, LiveWire.Defs.PUMP_PIPE, 1) then return false end
    LiveWire.Pump.linkBarrel(dev, barrel)
    LiveWire.Xp.award(ch, 3)
    LiveWire.notify(ch, "IGUI_LW_BarrelLinked", {})
    return true
end

function LWLinkBarrelAction:new(character, barrel, pump)
    return LWBaseAction.new(self, character, { barrel = barrel, pump = pump })
end

--------------------------------------------------------------------------------
-- Repair (overhaul = false) or overhaul (overhaul = true) a placed device.
--------------------------------------------------------------------------------
LWRepairAction = LWBaseAction:derive("LWRepairAction")
LWRepairAction.subject = "target"
LWRepairAction.facing = true

LWRepairAction.OVERHAUL_LEVEL = 3
LWRepairAction.TICKS = 250            -- repair, before the skill bonus
LWRepairAction.OVERHAUL_TICKS = 400   -- overhaul, before the skill bonus
LWRepairAction.MIN_TICKS = 100
LWRepairAction.TICKS_PER_LEVEL = 5    -- ticks saved per Electrical level

function LWRepairAction.parts(overhaul)
    if overhaul then return 4, 2 end
    return 1, 1
end

function LWRepairAction.canRepair(character, obj, overhaul)
    local m = LiveWire.Marks.get(obj)
    if not m then return false, "Tooltip_LW_Invalid" end
    if not I().screwdriver(character) then return false, "Tooltip_LW_NeedScrewdriver" end
    local scrap, wire = LWRepairAction.parts(overhaul)
    if I().countType(character, ELECTRONICS_SCRAP) < scrap
        or I().countType(character, ELECTRIC_WIRE) < wire then
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

function LWRepairAction:update()
    self.character:setMetabolicTarget(Metabolics.UsingTools)
end

function LWRepairAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    I().showScrewdriver(self)
end

function LWRepairAction:complete()
    if not self:guard() then return false end
    local ch, obj, overhaul = self.character, self.target, self.overhaul == true
    local dev = deviceOf(obj)
    if not dev then return false end
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
    local repairGrid = dev.grid and R().grid(dev.grid)
    if LiveWire.Maintenance.liveWork(ch, repairGrid) then return false end
    I().consume(ch, ELECTRONICS_SCRAP, scrap)
    I().consume(ch, ELECTRIC_WIRE, wire)
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
    local base = LWRepairAction.TICKS
    if self.overhaul then base = LWRepairAction.OVERHAUL_TICKS end
    return math.max(LWRepairAction.MIN_TICKS, base - I().level(self.character) * LWRepairAction.TICKS_PER_LEVEL)
end

function LWRepairAction:new(character, target, overhaul)
    return LWBaseAction.new(self, character, { target = target, overhaul = overhaul == true, caloriesModifier = 4 })
end

--------------------------------------------------------------------------------
-- Inspect a placed device: report and small daily XP, without changing its controls.
--------------------------------------------------------------------------------
LWInspectAction = LWBaseAction:derive("LWInspectAction")
LWInspectAction.duration = 100
LWInspectAction.range = 3
LWInspectAction.subject = "target"
LWInspectAction.facing = true

function LWInspectAction:isValid()
    return objectStillThere(self.target) and LiveWire.Marks.isOurs(self.target)
end

function LWInspectAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
end

function LWInspectAction:complete()
    if not self:guard() then return false end
    local ch, obj = self.character, self.target
    local dev = deviceOf(obj)
    if not dev then return false end
    local def = LiveWire.Defs.devices[dev.model] or {}
    LiveWire.Xp.awardLimited(ch, "inspect:" .. dev.id, 2, 24)
    local grid = dev.grid and R().grid(dev.grid)
    if grid and grid.name and grid.name ~= "" then LiveWire.notify(ch, "IGUI_LW_NetworkName", { grid.name }) end
    if def.kind == "solar" then
        LiveWire.notify(ch, "IGUI_LW_PanelFactors", { "IGUI_LW_Facing_" .. tostring(dev.facing or 0),
            tostring(math.floor((dev.dirt or 0) * 100)), tostring(math.floor((dev.snow or 0) * 100)) })
    end
    local cond = tostring(math.floor((dev.cond or 0) + 0.5))
    if def.role == "source" then
        LiveWire.notify(ch, "IGUI_LW_InspectSource",
            { "IGUI_LW_Model_" .. dev.model, cond, tostring(math.floor((dev.pOut or 0) + 0.5)),
              tostring(math.floor((dev.raw or 0) + 0.5)) })
    elseif def.role == "inverter" then
        LiveWire.notify(ch, "IGUI_LW_InspectInverter",
            { "IGUI_LW_Model_" .. dev.model, cond, "IGUI_LW_State_" .. tostring(dev.state) })
        if dev.muffled then LiveWire.notify(ch, "IGUI_LW_InspectMuffled", {}) end
    else
        LiveWire.notify(ch, "IGUI_LW_InspectOther", { "IGUI_LW_Model_" .. dev.model, cond })
    end
    return true
end

function LWInspectAction:new(character, target)
    return LWBaseAction.new(self, character, { target = target })
end

--------------------------------------------------------------------------------
-- Fit (remove = false) or remove (remove = true) the soundproofing kit of an
-- inverter: silent for players and zombies, 25 % more wear.
--------------------------------------------------------------------------------
LWMuffleAction = LWBaseAction:derive("LWMuffleAction")
LWMuffleAction.duration = 200
LWMuffleAction.subject = "target"
LWMuffleAction.facing = true

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

function LWMuffleAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWMuffleAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    self:setOverrideHandModels("Screwdriver", nil)
end

function LWMuffleAction:complete()
    if not self:guard() then return false end
    local ch, obj, remove = self.character, self.target, self.remove == true
    local dev = deviceOf(obj)
    if not dev or dev.role ~= "inverter" then return false end
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

function LWMuffleAction:new(character, target, remove)
    return LWBaseAction.new(self, character, { target = target, remove = remove == true })
end

--------------------------------------------------------------------------------
-- Clear the snow from a solar panel.
--------------------------------------------------------------------------------
LWClearSnowAction = LWBaseAction:derive("LWClearSnowAction")
LWClearSnowAction.duration = 120
LWClearSnowAction.subject = "target"
LWClearSnowAction.facing = true

function LWClearSnowAction:isValid()
    return objectStillThere(self.target) and LiveWire.Marks.isOurs(self.target)
end

function LWClearSnowAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function LWClearSnowAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
end

function LWClearSnowAction:complete()
    if not self:guard() then return false end
    local dev = deviceOf(self.target)
    if not dev then return false end
    dev.snow = 0
    LiveWire.Devices.syncMark(dev)
    return true
end

function LWClearSnowAction:new(character, target)
    return LWBaseAction.new(self, character, { target = target })
end

--------------------------------------------------------------------------------
-- Measure a square with the voltage tester.
--------------------------------------------------------------------------------
LWMeasureAction = LWBaseAction:derive("LWMeasureAction")
LWMeasureAction.duration = 60
LWMeasureAction.subject = "square"
LWMeasureAction.subjectIsSquare = true
LWMeasureAction.facing = true

function LWMeasureAction:isValid()
    return self.square ~= nil and I().countType(self.character, VOLTAGE_TESTER) > 0
end

function LWMeasureAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
end

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
                if LiveWire.Coverage.covers(id, a, sq:getX(), sq:getY(), sq:getZ(), range, V) then
                    return "IGUI_LW_Measure_Source_LiveWire"
                end
            end
        end
    end
    return "IGUI_LW_Measure_Source_Generator"
end

function LWMeasureAction:complete()
    if not self:guard() then return false end
    local ch, sq = self.character, self.square
    if I().countType(ch, VOLTAGE_TESTER) <= 0 then return false end
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
                best = math.max(best, LiveWire.Consumption.watts(o))
            end
        end
        if best > 0 then
            local w = math.floor(best + 0.5)
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
    LiveWire.Xp.awardMeasurement(ch, "measure:" .. sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ())
    return true
end

function LWMeasureAction:new(character, square)
    return LWBaseAction.new(self, character, { square = square })
end

--------------------------------------------------------------------------------
-- Recondition a battery held in the inventory (level 4).
--------------------------------------------------------------------------------
LWReconditionAction = LWBaseAction:derive("LWReconditionAction")
LWReconditionAction.duration = 300

LWReconditionAction.LEVEL = 4
LWReconditionAction.DEAD_LEVEL = 6  -- level needed to bring back a battery whose condition is 0
LWReconditionAction.WATER_LITRES = 0.5
LWReconditionAction.MAX_COND = 80
LWReconditionAction.GAIN = 15
LWReconditionAction.REPAIRS_KEY = "LiveWireRepairs"
LWReconditionAction.MAX_REPAIRS = 4

local function isWater(item)
    local fc = item:getFluidContainer()
    return fc ~= nil and fc:getSpecificFluidAmount(Fluid.Water) >= LWReconditionAction.WATER_LITRES
end

local function waterSource(character)
    return character:getInventory():getFirstEvalRecurse(isWater)
end

function LWReconditionAction.canRecondition(character, item)
    if not item or not LiveWire.Defs.isBattery(item:getFullType()) then return false, "Tooltip_LW_NotABattery" end
    if (item:getModData()[LWReconditionAction.REPAIRS_KEY] or 0) >= LWReconditionAction.MAX_REPAIRS then
        return false, "Tooltip_LW_RepairLimit"
    end
    if item:getCondition() >= LWReconditionAction.MAX_COND then return false, "Tooltip_LW_TooGood" end
    if not I().hasLevel(character, LWReconditionAction.LEVEL) then
        return false, "Tooltip_LW_NeedLevel", LiveWire.Config.requiredLevel(LWReconditionAction.LEVEL)
    end
    if item:getCondition() <= 0 and not I().hasLevel(character, LWReconditionAction.DEAD_LEVEL) then
        return false, "Tooltip_LW_NeedLevel", LiveWire.Config.requiredLevel(LWReconditionAction.DEAD_LEVEL)
    end
    if not I().screwdriver(character) then return false, "Tooltip_LW_NeedScrewdriver" end
    if I().countType(character, ELECTRIC_WIRE) < 1 then return false, "Tooltip_LW_NeedParts" end
    if I().countType(character, ELECTRONICS_SCRAP) < 1 then return false, "Tooltip_LW_NeedParts" end
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

function LWReconditionAction:complete()
    if not self:guard() then return false end
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
    I().consume(ch, ELECTRONICS_SCRAP, 1)
    I().consume(ch, ELECTRIC_WIRE, 1)
    local oldCondition = LiveWire.Batteries.condition(item)
    local oldCap = LiveWire.Batteries.capacity(item:getFullType(), oldCondition)
    local energy = LiveWire.Batteries.energy(item, oldCap)
    local newCond = math.min(LWReconditionAction.MAX_COND, oldCondition + LWReconditionAction.GAIN)
    LiveWire.Batteries.setCondition(item, newCond)
    local newCap = LiveWire.Batteries.capacity(item:getFullType(), newCond)
    LiveWire.Batteries.setEnergy(item, energy, newCap)
    local md = item:getModData()
    md[LWReconditionAction.REPAIRS_KEY] = (md[LWReconditionAction.REPAIRS_KEY] or 0) + 1
    syncItemFields(ch, item)
    LiveWire.Xp.award(ch, 8)
    LiveWire.notify(ch, "IGUI_LW_Reconditioned", { tostring(math.floor(newCond + 0.5)) })
    return true
end

function LWReconditionAction:new(character, item)
    return LWBaseAction.new(self, character, { item = item })
end

-- Inventory diagnostic: always read authoritative condition, charge and cycles.
LWTestBatteryAction = LWBaseAction:derive("LWTestBatteryAction")
LWTestBatteryAction.duration = 60
LWTestBatteryAction.LEVEL = 1
function LWTestBatteryAction:isValid()
    return self.item and self.character:getInventory():containsRecursive(self.item)
        and LiveWire.Defs.isBattery(self.item:getFullType())
        and I().hasLevel(self.character, LWTestBatteryAction.LEVEL)
        and I().countType(self.character, VOLTAGE_TESTER) > 0
end
function LWTestBatteryAction:start() self:setActionAnim(CharacterActionAnims.Craft) end
function LWTestBatteryAction:complete()
    if not self:guard() or not self:isValid() then return false end
    local ch, it = self.character, self.item
    local level = I().level(ch)
    local condition = LiveWire.Batteries.condition(it)
    local cap = LiveWire.Batteries.capacity(it:getFullType(), condition)
    local energy = LiveWire.Batteries.energy(it, cap)
    LiveWire.notify(ch, "IGUI_LW_BatteryCharge", { tostring(math.floor((cap > 0 and energy / cap or 0) * 100 + 0.5)) })
    if level >= 3 then
        LiveWire.notify(ch, "IGUI_LW_BatteryCapacity", { string.format("%.2f", energy),
            string.format("%.2f", cap), tostring(it:getCondition()) })
    end
    if level >= 5 then
        local cycles = it:getModData()[LiveWire.Batteries.CYCLES_KEY] or 0
        local def = LiveWire.Batteries.def(it:getFullType())
        LiveWire.notify(ch, "IGUI_LW_BatteryCycles", { string.format("%.1f", cycles),
            tostring(math.floor(def.lifeCycles * condition / 100)),
            tostring(it:getModData()[LWReconditionAction.REPAIRS_KEY] or 0) })
    end
    return true
end
function LWTestBatteryAction:new(character, item)
    return LWBaseAction.new(self, character, { item = item })
end

-- Snow-only legacy action remains usable; cleaning additionally removes dirt and costs water.
LWCleanPanelAction = LWBaseAction:derive("LWCleanPanelAction")
LWCleanPanelAction.duration = 180
LWCleanPanelAction.subject = "target"
LWCleanPanelAction.facing = true
function LWCleanPanelAction:isValid()
    local m = LiveWire.Marks.get(self.target)
    local def = m and LiveWire.Defs.devices[m.model]
    return objectStillThere(self.target) and def and def.kind == "solar"
        and I().countType(self.character, "Base.RippedSheets") > 0 and waterSource(self.character) ~= nil
end
function LWCleanPanelAction:start() self:setActionAnim("Loot") end
function LWCleanPanelAction:complete()
    if not self:guard() or not self:isValid() then return false end
    local ch, obj = self.character, self.target
    local dev = deviceOf(obj)
    if not dev then return false end
    if (dev.dirt or 0) <= 0 and (dev.snow or 0) <= 0 then return false end
    local water = waterSource(ch)
    local fc = water:getFluidContainer()
    fc:adjustSpecificFluidAmount(Fluid.Water,
        fc:getSpecificFluidAmount(Fluid.Water) - LWReconditionAction.WATER_LITRES)
    water:syncItemFields()
    dev.dirt, dev.snow = 0, 0
    LiveWire.Devices.syncMark(dev)
    LiveWire.Xp.awardLimited(ch, "clean:" .. dev.id, 2, 24)
    return true
end
function LWCleanPanelAction:new(character, target)
    return LWBaseAction.new(self, character, { target = target })
end
