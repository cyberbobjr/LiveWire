-- Live Wire: debug and test tools (authority only). Every command is re-checked:
-- debug mode in single player, admin role in multiplayer (LW_Debug.lua), device
-- within 30 tiles. Every use is written to the server console.
if isClient() then return end

LiveWire = LiveWire or {}

local DebugCommands = {}
LiveWire.DebugCommands = DebugCommands

local P = LiveWire.Protocol
local function R() return LiveWire.Registry end

-- Items given by "spawnKit".
DebugCommands.KIT = {
    { "Base.Screwdriver", 1 }, { "Base.ElectricWire", 20 }, { "Base.ElectronicsScrap", 10 },
    { "LiveWire.VoltageTester", 1 }, { "Base.CarBattery2", 4 }, { "LiveWire.DeepCycleBattery", 2 },
}

local function gridOf(dev)
    if not dev then return nil end
    return dev.grid and R().grid(dev.grid)
end

-- Every battery of the network at `frac` of its capacity.
local function setBatteries(grid, frac)
    local _, banks = R().members(grid)
    for i = 1, #banks do
        local entries = LiveWire.Batteries.read(banks[i])
        for j = 1, #entries do entries[j].charge = entries[j].capacity * frac end
        LiveWire.Batteries.write(banks[i], entries)
    end
end

local function advance(grid, hours)
    local now = getGameTime():getWorldAgeHours()
    grid.lastTick = (grid.lastTick or now) - hours
    local ok, err = pcall(LiveWire.Sim.stepGrid, grid, now, LiveWire.Sim.weather())
    if not ok then LiveWire.warn("debug advance failed: " .. tostring(err)) end
end

local function dump(player, grid)
    local snap = LiveWire.Sim.snapshot(grid)
    if not snap then return end
    LiveWire.log(string.format("debug dump %s: inverter %s %s cond %d, prod %d W, demand %d W, stock %.3f/%.3f kWh",
        grid.id, snap.inverter.id, tostring(snap.inverter.state), snap.inverter.cond,
        snap.production, snap.demand, snap.stock, snap.capacity))
    for i = 1, #snap.sources do
        local s = snap.sources[i]
        LiveWire.log(string.format("  source %s %s %d W (raw %d) cond %d", s.id, s.model, s.w, s.raw, s.cond))
    end
    if snap.backup then
        LiveWire.log(string.format("  backup %s %s fuel %.2f %d W", snap.backup.id, snap.backup.state,
            snap.backup.fuel, snap.backup.w))
    end
    if snap.computer then
        LiveWire.log("  computer " .. snap.computer.id .. " powered " .. tostring(snap.computer.powered)
            .. " history " .. tostring(#(grid.history or {})))
    end
    LiveWire.notify(player, "IGUI_LW_Debug_Dump",
        { tostring(snap.production), tostring(snap.demand), string.format("%.2f", snap.stock),
          string.format("%.2f", snap.capacity) })
end

local actions = {}

actions.dump = function(player, dev, grid) dump(player, grid) end
actions.battery100 = function(player, dev, grid) setBatteries(grid, 1.0) end
actions.battery50 = function(player, dev, grid) setBatteries(grid, 0.5) end
actions.battery15 = function(player, dev, grid) setBatteries(grid, 0.15) end
actions.battery0 = function(player, dev, grid) setBatteries(grid, 0) end
actions.advance1 = function(player, dev, grid) advance(grid, 1) end
actions.advance12 = function(player, dev, grid) advance(grid, 12) end

actions.repairAll = function(player, dev, grid)
    local inv = R().device(grid.inverter)
    if inv then
        inv.cond = 100
        if inv.state == "broken" then inv.state = "off" end
    end
    for id in pairs(grid.members) do
        local m = R().device(id)
        if m and m.cond then m.cond = 100 end
    end
end

actions.damageInverter = function(player, dev, grid)
    local inv = R().device(grid.inverter)
    if inv then inv.cond = 10 end
end

-- Same rule as an overload: the breaker trips when there is one, else the inverter.
actions.trip = function(player, dev, grid)
    local brk = R().hasOption(grid, "breaker")
    local inv = R().device(grid.inverter)
    if brk then
        brk.state = "tripped"
    elseif inv and inv.state == "on" then
        inv.state = "tripped"
    end
end

actions.refuel = function(player, dev, grid)
    local _, _, _, backups = R().members(grid)
    for i = 1, #backups do
        local gen = LiveWire.Backup.find(backups[i])
        if gen then gen:setFuel(gen:getMaxFuel()) end
        backups[i].fuel = 10
        backups[i].fuelSeen = 10
    end
end

actions.reanchor = function(player, dev, grid)
    LiveWire.Demand.invalidate(grid.inverter)
    local inv = R().device(grid.inverter)
    if inv then LiveWire.Anchor.appliedState[inv.id] = nil end
end

local function spawnKit(player)
    local list = {}
    for _, def in pairs(LiveWire.Defs.devices) do list[#list + 1] = { def.item, 1 } end
    for i = 1, #DebugCommands.KIT do list[#list + 1] = DebugCommands.KIT[i] end
    for i = 1, #list do
        for _ = 1, list[i][2] do LiveWire.Install.giveItem(player, list[i][1]) end
    end
end

-- Remove every water relay of every pump, and disable the pumps so that they do not
-- place them again. Loaded relays go now; the entries of relays on unloaded squares
-- are dropped too, so Pump.onLoadChunk removes those relays when their chunk loads.
local function removeRelays(player)
    local Rg = R()
    local removed, remaining = 0, 0
    if not LiveWire.Pump then return end
    Rg.data.pumpsDisabled = true
    for _, dev in pairs(Rg.devices()) do
        if dev.role == "pump" and dev.relays then
            local keys = {}
            for key in pairs(dev.relays) do keys[#keys + 1] = key end
            for i = 1, #keys do
                LiveWire.Pump.removeRelay(dev, keys[i])
                if dev.relays[keys[i]] then remaining = remaining + 1 else removed = removed + 1 end
                dev.relays[keys[i]] = nil
            end
            dev.state = "idle"
            LiveWire.Devices.syncMark(dev)
        end
    end
    LiveWire.log("debug removeRelays: pumps disabled, " .. tostring(removed) .. " relay(s) removed, "
        .. tostring(remaining) .. " left in unloaded areas (removed when their chunk loads)")
end

-- Lift the block set by removeRelays: the pumps place their relays again.
local function enablePumps(player)
    local Rg = R()
    if not LiveWire.Pump then return end
    Rg.data.pumpsDisabled = nil
    for _, dev in pairs(Rg.devices()) do
        if dev.role == "pump" then LiveWire.Pump.maintain(dev) end
    end
    LiveWire.log("debug enablePumps: pumps enabled again")
end

local function setDeviceCondition(player, dev, grid, value)
    local def = LiveWire.Defs.devices[dev.model]
    if not def or def.role ~= dev.role or not LiveWire.Devices.find(dev) then
        return LiveWire.notify(player, "Tooltip_LW_Invalid", {}, true)
    end
    dev.cond = LiveWire.clamp(value < 0 and (dev.cond or 100) + value or value, 0, 100)
    if dev.cond == 0 then
        if dev.role == "inverter" or dev.role == "pump" then dev.state = "broken" end
        if dev.role == "source" then dev.pOut, dev.raw = 0, 0 end
    elseif dev.state == "broken" then
        if dev.role == "inverter" then dev.state = "off"
        elseif dev.role == "pump" then dev.state = "idle" end
    end
    -- Only device health changes. Slots, battery health/charge, links, brake,
    -- circuit choices and persistent ids stay intact. No XP or item creation.
    LiveWire.Devices.syncMark(dev)
    if grid then
        grid.forecastAt = nil
        LiveWire.Sim.refresh(grid)
    end
    LiveWire.notify(player, "IGUI_LW_Debug_Condition",
        { "IGUI_LW_Model_" .. dev.model, tostring(math.floor(dev.cond + 0.5)) })
end

local function onDebug(player, args)
    if not player or player:isDead() or not R().ready or R().readOnly then return end
    if not LiveWire.Debug.allowed(player) then
        LiveWire.warn("debug command refused for " .. tostring(player:getUsername()))
        return
    end
    local action = args.action
    if type(action) ~= "string" or LiveWire.Debug.ACTIONS[action] == nil then return end
    LiveWire.log("debug " .. action .. " by " .. tostring(player:getUsername())
        .. " on " .. tostring(args.device))
    if action == "spawnKit" then return spawnKit(player) end
    if action == "removeRelays" or action == "enablePumps" then
        if action == "removeRelays" then removeRelays(player) else enablePumps(player) end
        return LiveWire.notify(player, "IGUI_LW_Debug_Done", { action })
    end

    local dev, why = LiveWire.Commands.checkDevice(player, args.device, LiveWire.Debug.RANGE)
    if not dev then return LiveWire.notify(player, why, {}, true) end
    local grid = gridOf(dev)
    local condition = LiveWire.Debug.CONDITIONS[action]
    if condition ~= nil then
        return setDeviceCondition(player, dev, grid, condition)
    end
    if not grid then return LiveWire.notify(player, "IGUI_LW_Debug_NoGrid", {}, true) end
    actions[action](player, dev, grid)
    if action ~= "dump" and action ~= "advance1" and action ~= "advance12" then
        LiveWire.Sim.refresh(grid)
    end
    LiveWire.notify(player, "IGUI_LW_Debug_Done", { action })
end

LiveWire.Commands.register(P.C_DEBUG, onDebug)
