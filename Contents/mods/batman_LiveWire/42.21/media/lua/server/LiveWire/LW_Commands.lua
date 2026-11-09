-- Live Wire: client commands, fully re-validated on the authority
-- (docs/architecture.md section 5.3). sendClientCommand also reaches this handler
-- in single player, one tick later (knowledge/multiplayer.md:280-282).
if isClient() then return end
require "LiveWire/LW_Maintenance"
require "LiveWire/LW_Circuits"
require "LiveWire/LW_DeviceView"

LiveWire = LiveWire or {}

local Commands = {}
LiveWire.Commands = Commands

local P = LiveWire.Protocol
Commands.ACT_RANGE = 3
-- Distance to the management computer for a software command: the distance at which
-- our computer screen closes (LW_SoftwareScreen.lua CLOSE_RANGE).
Commands.SOFTWARE_RANGE = 6
Commands.RATE_PER_SECOND = 4

-- Refusal codes. The value is the translation key sent to the client.
Commands.ERR = {
    INVALID = "Tooltip_LW_Invalid",
    TOO_FAR = "Tooltip_LW_TooFar",
    SAFEHOUSE = "Tooltip_LW_Safehouse",
    NEED_SCREWDRIVER = "Tooltip_LW_NeedScrewdriver",
}
local ERR = Commands.ERR

-- May `player` act on square `sq`? False inside a safehouse that does not allow them.
Commands.canTouch = LiveWire.canTouch

local rate = {}  -- username -> { windowStart = ms, count = n, warned = bool }

function Commands.purgeRate()
    local now, stale = getTimestampMs(), {}
    for who, r in pairs(rate) do
        if now - r.windowStart >= 60000 or now < r.windowStart then stale[#stale + 1] = who end
    end
    for i = 1, #stale do rate[stale[i]] = nil end
end
Events.EveryHours.Add(Commands.purgeRate)

local function allowRate(player)
    local who = player:getUsername() or "local"
    local now = getTimestampMs()
    local r = rate[who]
    if not r or now - r.windowStart >= 1000 then
        r = { windowStart = now, count = 0, warned = r and r.warned or false }
        rate[who] = r
    end
    r.count = r.count + 1
    if r.count > Commands.RATE_PER_SECOND then
        if not r.warned then
            LiveWire.warn("command rate limit hit by " .. tostring(who))
            r.warned = true
        end
        return false
    end
    return true
end

local function refuse(player, key)
    LiveWire.notify(player, key, {}, true)
end

-- Chebyshev distance <= range on the same floor (or within `floors` floors).
function Commands.isNear(player, x, y, z, range, floors)
    if math.abs(math.floor(player:getZ()) - z) > (floors or 0) then return false end
    return math.abs(player:getX() - (x + 0.5)) <= range + 0.5
        and math.abs(player:getY() - (y + 0.5)) <= range + 0.5
end

-- Common checks for a command that touches a device.
function Commands.checkDevice(player, id, range)
    if not P.isDeviceId(id) then return nil, ERR.INVALID end
    local dev = LiveWire.Registry.device(id)
    if not dev then return nil, ERR.INVALID end
    local sq = getCell():getGridSquare(dev.x, dev.y, dev.z)
    if not sq then return nil, ERR.TOO_FAR end
    if not Commands.isNear(player, dev.x, dev.y, dev.z, range or Commands.ACT_RANGE) then
        return nil, ERR.TOO_FAR
    end
    if not Commands.canTouch(player, sq) then
        return nil, ERR.SAFEHOUSE
    end
    return dev, nil, sq
end

-- Command sent by the management software (C02): `via` = {x, y, z} of the computer it
-- runs on. Accepted when the player stands at that computer, and a powered management
-- computer of the inverter's network is on that square.
function Commands.checkVia(player, via, inv)
    if type(via) ~= "table" or not inv or not inv.grid then return false end
    local x, y, z = P.parsePos(via)
    if not x then return false end
    local grid = LiveWire.Registry.grid(inv.grid)
    if not grid or not LiveWire.Computer then return false end
    if not Commands.isNear(player, x, y, z, Commands.SOFTWARE_RANGE) then return false end
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return false end
    if not Commands.canTouch(player, sq) then return false end
    local list = LiveWire.Registry.devicesAt(x, y, z)
    for i = 1, #list do
        local d = list[i]
        if d.role == "computer" and d.grid == grid.id and LiveWire.Computer.powered(d, grid) then
            return true
        end
    end
    return false
end

-- An inverter command (switch, reset): from the inverter itself, or from the
-- management software on a computer of its network.
-- The coupled inverters of master `inv`'s network, when a coupling add-on is
-- registered (D-45): each opens the master's screen and may stand past the cable
-- range, so standing at one counts as standing at the master for that screen.
local function coupledOf(inv)
    if not LiveWire.Coupling.active() or not inv or inv.coupled then return {} end
    local grid = inv.grid and LiveWire.Registry.grid(inv.grid)
    return grid and LiveWire.Registry.slaves(grid) or {}
end

local function checkInverterCommand(player, args)
    local dev, why = Commands.checkDevice(player, args.inverter)
    if dev then return dev end
    local inv = P.isDeviceId(args.inverter) and LiveWire.Registry.device(args.inverter)
    if inv and inv.role == "inverter" and Commands.checkVia(player, args.via, inv) then
        return inv
    end
    if inv and inv.role == "inverter" and why == ERR.TOO_FAR then
        local slaves = coupledOf(inv)
        if #slaves > 0 then
            local msq = getCell():getGridSquare(inv.x, inv.y, inv.z)
            if msq and not Commands.canTouch(player, msq) then
                return nil, ERR.SAFEHOUSE
            end
            for i = 1, #slaves do
                if Commands.checkDevice(player, slaves[i].id) then return inv end
            end
        end
    end
    return nil, why
end

-- A command handler behind a check: `check(player, args)` returns the device (or nil and the
-- translation key of the refusal, then the player is told) and may return one more value.
-- `fn(player, args, dev, extra)` runs only when the check passed.
local function guarded(check, fn)
    return function(player, args)
        local dev, why, extra = check(player, args)
        if not dev then
            if why then refuse(player, why) end
            return
        end
        return fn(player, args, dev, extra)
    end
end

local function deviceIn(field)
    return function(player, args) return Commands.checkDevice(player, args[field]) end
end

local handlers = {}
handlers[P.C_READ_SERVICES] = function(player, args) LiveWire.ServiceSync.reply(player, args) end
handlers[P.C_READ_DEVICE] = function(player, args)
    local dev = Commands.checkDevice(player, args.device)
    if not dev or type(args.seq) ~= "number" or args.seq ~= math.floor(args.seq)
        or args.seq < 1 or args.seq > 1000000000 or not LiveWire.Devices.find(dev) then return end
    local snap = LiveWire.DeviceView.snapshot(dev)
    if snap and isServer() then
        snap.seq = args.seq
        sendServerCommand(player, LiveWire.MODULE, P.S_DEVICE, snap)
    end
end
handlers[P.C_READ_BANK] = function(player, args)
    local dev = Commands.checkDevice(player, args.device)
    if not dev or dev.role ~= "storage" or type(args.seq) ~= "number"
        or args.seq ~= math.floor(args.seq) or args.seq < 1 or args.seq > 1000000000 then return end
    local snap = LiveWire.Batteries.snapshot(dev)
    if snap and isServer() then
        snap.seq = args.seq
        sendServerCommand(player, LiveWire.MODULE, P.S_BANK, snap)
    end
end
handlers[P.C_SET_CIRCUIT] = function(player, args) LiveWire.Circuits.set(player, args) end

handlers[P.C_RESUME_BACKUP] = guarded(deviceIn("device"), function(player, args, dev)
    if dev.role ~= "backup" or not LiveWire.Backup.resume(dev) then return end
    LiveWire.Sim.refresh(LiveWire.Registry.grid(dev.grid))
end)

handlers[P.C_SET_BRAKE] = guarded(deviceIn("device"), function(player, args, dev)
    local def = LiveWire.Defs.devices[dev.model]
    if not def or not LiveWire.Defs.sourceField(def.kind, "brake") or not P.isBool(args.brake) then return end
    dev.brake = args.brake
    LiveWire.Devices.syncMark(dev)
    LiveWire.Sim.refresh(dev.grid and LiveWire.Registry.grid(dev.grid))
end)

-- Other server files add their commands here (LW_DebugCommands.lua).
function Commands.register(command, fn)
    handlers[command] = fn
end

-- Run a command handler at once on the authority (in-game tests; a client command
-- sent in single player is only handled at the next update).
function Commands.handle(player, command, args)
    local h = handlers[command]
    if h then h(player, args or {}) end
end

local function gridOfInverter(id)
    if not P.isDeviceId(id) then return nil end
    local inv = LiveWire.Registry.device(id)
    if not inv or inv.role ~= "inverter" or not inv.grid then return nil end
    return LiveWire.Registry.grid(inv.grid), inv
end

-- Dashboard subscription, by inverter id (clients read it from the object mark).
handlers[P.C_SUBSCRIBE] = function(player, args)
    local grid, inv = gridOfInverter(args.inverter)
    if not grid then return end
    local range, floors = LiveWire.Sim.SUBSCRIBE_RANGE, LiveWire.Config.verticalRange()
    local near = Commands.isNear(player, inv.x, inv.y, inv.z, range, floors)
    if not near then
        local slaves = coupledOf(inv)
        for i = 1, #slaves do
            local d = slaves[i]
            if Commands.isNear(player, d.x, d.y, d.z, range, floors) then near = true break end
        end
    end
    if not near and not Commands.checkVia(player, args.via, inv) then
        return
    end
    LiveWire.Sim.subscribe(player, grid.id)
    local snap = LiveWire.Sim.snapshot(grid)
    if snap and isServer() then
        sendServerCommand(player, LiveWire.MODULE, P.S_SNAPSHOT, snap)
    end
end

handlers[P.C_UNSUBSCRIBE] = function(player, args)
    local grid = gridOfInverter(args.inverter)
    if grid then LiveWire.Sim.unsubscribe(player, grid.id) end
end

local function checkUnlink(player, args)
    local dev, why = Commands.checkDevice(player, args.device)
    if not dev and why == ERR.TOO_FAR then
        -- Also allowed from the inverter of its network (inverter menu).
        local d = P.isDeviceId(args.device) and LiveWire.Registry.device(args.device)
        local g = d and d.grid and LiveWire.Registry.grid(d.grid)
        if g and Commands.checkDevice(player, g.inverter) then dev = d end
    end
    return dev, why
end

handlers[P.C_UNLINK] = guarded(checkUnlink, function(player, args, dev)
    if dev.role == "inverter" or not dev.grid then return end
    if not LiveWire.Install.screwdriver(player) then
        return refuse(player, ERR.NEED_SCREWDRIVER)
    end
    local grid = LiveWire.Registry.grid(dev.grid)
    -- A linked vanilla generator or computer leaves the registry entirely.
    if LiveWire.Maintenance.liveWork(player, grid) then return end
    local wires = LiveWire.Devices.linkWires(dev)
    if not LiveWire.Registry.forgetVanilla(dev) then
        LiveWire.Registry.unlink(dev)
        LiveWire.Devices.syncMark(dev)
        if dev.role == "pump" and LiveWire.Pump then LiveWire.Pump.maintain(dev) end
    end
    LiveWire.Sim.refresh(grid)
    LiveWire.notify(player, "IGUI_LW_Unlinked", {})
    LiveWire.Devices.returnWires(player, wires)
end)

-- Make a slave independent again: it gets its own empty grid, the coupling kit and
-- the wire of the coupling go back to the player.
handlers[P.C_UNCOUPLE] = guarded(deviceIn("inverter"), function(player, args, dev)
    if dev.role ~= "inverter" or not dev.coupled then return end
    local R = LiveWire.Registry
    local mgrid = R.grid(dev.grid)
    local master = mgrid and R.device(mgrid.inverter)
    local wires = LiveWire.Devices.linkWires(dev)
    R.uncouple(dev)
    -- Anchor off until the first step of its new grid.
    LiveWire.Sim.updateAnchor(dev, false)
    LiveWire.Sim.refresh(R.grid(dev.grid))
    if mgrid then LiveWire.Sim.refresh(mgrid) end
    LiveWire.Devices.syncMark(dev)
    if master then LiveWire.Devices.syncMark(master) end
    LiveWire.Install.giveItem(player, LiveWire.Defs.COUPLING_KIT)
    LiveWire.notify(player, "IGUI_LW_Uncoupled", {})
    LiveWire.Devices.returnWires(player, wires)
end)

-- Disconnect one barrel from a pump: the pipe goes back to the player.
handlers[P.C_UNLINK_BARREL] = guarded(deviceIn("pump"), function(player, args, dev)
    if dev.role ~= "pump" or not LiveWire.Pump then return end
    local x, y, z = P.parsePos(args)
    if not x then return end
    local key = LiveWire.posKey(x, y, z)
    if not dev.barrels or not dev.barrels[key] then return end
    LiveWire.Pump.unlinkBarrel(dev, key)
    LiveWire.Install.giveItem(player, LiveWire.Defs.PUMP_PIPE)
    LiveWire.notify(player, "IGUI_LW_BarrelUnlinked", {})
end)

-- Same overload test as the simulation trip (LW_Simulation.lua stepGrid): house
-- demand plus the pumps against the capacity in service. Returns the notification
-- arguments when the master would trip again at once, nil otherwise.
local function overload(inv, grid)
    local demand = LiveWire.Demand.measureGrid(grid, inv) or (grid and grid.demand) or 0
    if grid then grid.demand = demand end
    local total = demand + (grid and grid.pumpW or 0)
    local def = LiveWire.Defs.devices[inv.model]
    local cap = grid and LiveWire.Sim.capacityW(grid) or (def and def.maxW)
    if cap and total > cap then
        return { tostring(math.floor(total + 0.5)), tostring(cap) }
    end
end

handlers[P.C_SET_INVERTER] = guarded(checkInverterCommand, function(player, args, dev)
    if dev.role ~= "inverter" or not P.isBool(args.on) then return end
    if args.on then
        if dev.state == "off" then
            dev.state = "on"
            -- Switching a master back on runs the reset test: isolating a tripped
            -- unit then switching it on must not bypass it. A slave only adds
            -- capacity; with a breaker, the breaker trips and the inverter still charges.
            local grid = LiveWire.Registry.grid(dev.grid)
            local stuck = not dev.coupled and not (grid and LiveWire.Registry.hasOption(grid, "breaker"))
                and overload(dev, grid)
            if stuck then
                dev.state = "off"
                return LiveWire.notify(player, "IGUI_LW_StillOverloaded", stuck, true)
            end
        end
    else
        -- Explicit isolation must remain available after a trip or a failure.
        dev.state = "off"
    end
    LiveWire.Sim.refresh(LiveWire.Registry.grid(dev.grid))
end)

handlers[P.C_RESET] = guarded(checkInverterCommand, function(player, args, dev)
    -- A slave never trips: its master is the one to reset.
    if dev.coupled then dev = LiveWire.Registry.device(dev.coupled) or dev end
    if dev.role ~= "inverter" or dev.state ~= "tripped" then return end
    local grid = LiveWire.Registry.grid(dev.grid)
    local stuck = overload(dev, grid)
    if stuck then return LiveWire.notify(player, "IGUI_LW_StillOverloaded", stuck, true) end
    dev.state = "on"
    LiveWire.Xp.awardLimited(player, "reset:" .. dev.id, 5, 1)
    LiveWire.Sim.refresh(grid)
end)

-- Reset a tripped wall breaker (from the breaker itself).
handlers[P.C_RESET_BREAKER] = guarded(deviceIn("device"), function(player, args, dev)
    local bdef = LiveWire.Defs.devices[dev.model]
    if not bdef or bdef.kind ~= "breaker" or dev.state ~= "tripped" then return end
    local grid = dev.grid and LiveWire.Registry.grid(dev.grid)
    local inv = grid and LiveWire.Registry.device(grid.inverter)
    if inv then
        local stuck = overload(inv, grid)
        if stuck then return LiveWire.notify(player, "IGUI_LW_StillOverloaded", stuck, true) end
    end
    dev.state = "ok"
    LiveWire.Xp.awardLimited(player, "reset:" .. dev.id, 5, 1)
    if grid then LiveWire.Sim.refresh(grid) else LiveWire.Devices.syncMark(dev) end
    LiveWire.notify(player, "IGUI_LW_BreakerReset", {})
end)

-- Silence a ringing low battery alarm (its beacon stays lit until the stock recovers).
handlers[P.C_ACK_ALARM] = guarded(deviceIn("device"), function(player, args, dev)
    local adef = LiveWire.Defs.devices[dev.model]
    local grid = dev.grid and LiveWire.Registry.grid(dev.grid)
    if not adef or adef.kind ~= "alarm" or not grid or not grid.alarmOn then return end
    grid.alarmAck = true
    LiveWire.notify(player, "IGUI_LW_AlarmSilenced", {})
end)

-- An unknown inverter is ignored without a refusal.
local function checkRename(player, args)
    local grid = gridOfInverter(args.inverter)
    if not grid then return nil, nil end
    local dev, why = checkInverterCommand(player, args)
    return dev, why, grid
end

handlers[P.C_RENAME] = guarded(checkRename, function(player, args, _dev, grid)
    local name = P.cleanName(args.name)
    if name then
        grid.name = name
        grid.rev = (grid.rev or 0) + 1
        local master = LiveWire.Registry.device(grid.inverter)
        if master then LiveWire.Devices.syncMark(master) end
        LiveWire.Sim.publish(grid)
    end
end)

-- A client sees a Live Wire tile without a valid mark for some seconds (placed by a
-- path that skipped our placement wrapper): register it if it really is unbound.
Commands.ADOPT_RANGE = 40
handlers[P.C_ADOPT] = function(player, args)
    local x, y, z = P.parsePos(args)
    if not x then return end
    if math.abs(player:getX() - x) > Commands.ADOPT_RANGE or math.abs(player:getY() - y) > Commands.ADOPT_RANGE
        or math.abs(player:getZ() - z) > 3 then
        return
    end
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return end
    if not Commands.canTouch(player, sq) then return end
    LiveWire.Devices.adoptSquare(player, sq)
end

local function onClientCommand(module, command, player, args)
    if module ~= LiveWire.MODULE then return end
    local R = LiveWire.Registry
    if not R or not R.ready or R.readOnly then return end
    if not player or player:isDead() then return end
    if not allowRate(player) then return end
    local h = handlers[command]
    if not h then return end
    args = args or {}
    local ok, err = pcall(h, player, args)
    if not ok then LiveWire.warn("command " .. tostring(command) .. " failed: " .. tostring(err)) end
end

Events.OnClientCommand.Add(onClientCommand)
