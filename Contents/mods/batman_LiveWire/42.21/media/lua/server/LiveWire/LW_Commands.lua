-- Live Wire: client commands, fully re-validated on the authority
-- (docs/architecture.md section 5.3). sendClientCommand also reaches this handler
-- in single player, one tick later (knowledge/multiplayer.md:280-282).
if isClient() then return end

LiveWire = LiveWire or {}

local Commands = {}
LiveWire.Commands = Commands

local P = LiveWire.Protocol
Commands.ACT_RANGE = 3
Commands.RATE_PER_SECOND = 4

local rate = {}  -- username -> { windowStart = ms, count = n, warned = bool }

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

local function refuse(player, cmd, key)
    LiveWire.notify(player, key, {}, true)
end

-- Chebyshev distance <= range on the same floor.
function Commands.isNear(player, x, y, z, range)
    if math.floor(player:getZ()) ~= z then return false end
    return math.abs(player:getX() - (x + 0.5)) <= range + 0.5
        and math.abs(player:getY() - (y + 0.5)) <= range + 0.5
end

-- Common checks for a command that touches a device.
function Commands.checkDevice(player, id, range)
    if not P.isDeviceId(id) then return nil, "Tooltip_LW_Invalid" end
    local dev = LiveWire.Registry.device(id)
    if not dev then return nil, "Tooltip_LW_Invalid" end
    local sq = getCell():getGridSquare(dev.x, dev.y, dev.z)
    if not sq then return nil, "Tooltip_LW_TooFar" end
    if not Commands.isNear(player, dev.x, dev.y, dev.z, range or Commands.ACT_RANGE) then
        return nil, "Tooltip_LW_TooFar"
    end
    if SafeHouse and not SafeHouse.isSafehouseAllowInteract(sq, player) then
        return nil, "Tooltip_LW_Safehouse"
    end
    return dev, nil, sq
end

local handlers = {}

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
    if not Commands.isNear(player, inv.x, inv.y, inv.z, LiveWire.Sim.SUBSCRIBE_RANGE) then return end
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

handlers[P.C_UNLINK] = function(player, args)
    local dev, why = Commands.checkDevice(player, args.device)
    if not dev and why == "Tooltip_LW_TooFar" then
        -- Also allowed from the inverter of its network (inverter menu).
        local d = P.isDeviceId(args.device) and LiveWire.Registry.device(args.device)
        local g = d and d.grid and LiveWire.Registry.grid(d.grid)
        if g and Commands.checkDevice(player, g.inverter) then dev = d end
    end
    if not dev then return refuse(player, P.C_UNLINK, why) end
    if dev.role == "inverter" or not dev.grid then return end
    local grid = LiveWire.Registry.grid(dev.grid)
    -- A linked vanilla generator or computer leaves the registry entirely.
    if not LiveWire.Registry.forgetVanilla(dev) then
        LiveWire.Registry.unlink(dev)
        LiveWire.Devices.syncMark(dev)
    end
    LiveWire.Sim.refresh(grid)
    LiveWire.notify(player, "IGUI_LW_Unlinked", {})
end

handlers[P.C_SET_INVERTER] = function(player, args)
    local dev, why = Commands.checkDevice(player, args.inverter)
    if not dev then return refuse(player, P.C_SET_INVERTER, why) end
    if dev.role ~= "inverter" or not P.isBool(args.on) then return end
    if args.on then
        if dev.state == "off" then dev.state = "on" end
    else
        if dev.state == "on" or dev.state == "tripped" then dev.state = "off" end
    end
    LiveWire.Sim.refresh(LiveWire.Registry.grid(dev.grid))
end

handlers[P.C_RESET] = function(player, args)
    local dev, why = Commands.checkDevice(player, args.inverter)
    if not dev then return refuse(player, P.C_RESET, why) end
    if dev.role ~= "inverter" or dev.state ~= "tripped" then return end
    local grid = LiveWire.Registry.grid(dev.grid)
    local def = LiveWire.Defs.devices[dev.model]
    local demand = LiveWire.Demand.measure(dev) or (grid and grid.demand) or 0
    if grid then grid.demand = demand end
    if def and demand > def.maxW then
        return LiveWire.notify(player, "IGUI_LW_StillOverloaded",
            { tostring(math.floor(demand + 0.5)), tostring(def.maxW) }, true)
    end
    dev.state = "on"
    LiveWire.Xp.awardLimited(player, "reset:" .. dev.id, 5, 1)
    LiveWire.Sim.refresh(grid)
end

-- Reset a tripped wall breaker (from the breaker itself).
handlers[P.C_RESET_BREAKER] = function(player, args)
    local dev, why = Commands.checkDevice(player, args.device)
    if not dev then return refuse(player, P.C_RESET_BREAKER, why) end
    local bdef = LiveWire.Defs.devices[dev.model]
    if not bdef or bdef.kind ~= "breaker" or dev.state ~= "tripped" then return end
    local grid = dev.grid and LiveWire.Registry.grid(dev.grid)
    local inv = grid and LiveWire.Registry.device(grid.inverter)
    if inv then
        local def = LiveWire.Defs.devices[inv.model]
        local demand = LiveWire.Demand.measure(inv) or grid.demand or 0
        grid.demand = demand
        if def and demand > def.maxW then
            return LiveWire.notify(player, "IGUI_LW_StillOverloaded",
                { tostring(math.floor(demand + 0.5)), tostring(def.maxW) }, true)
        end
    end
    dev.state = "ok"
    LiveWire.Xp.awardLimited(player, "reset:" .. dev.id, 5, 1)
    if grid then LiveWire.Sim.refresh(grid) else LiveWire.Devices.syncMark(dev) end
    LiveWire.notify(player, "IGUI_LW_BreakerReset", {})
end

-- Silence a ringing low battery alarm (its beacon stays lit until the stock recovers).
handlers[P.C_ACK_ALARM] = function(player, args)
    local dev, why = Commands.checkDevice(player, args.device)
    if not dev then return refuse(player, P.C_ACK_ALARM, why) end
    local adef = LiveWire.Defs.devices[dev.model]
    local grid = dev.grid and LiveWire.Registry.grid(dev.grid)
    if not adef or adef.kind ~= "alarm" or not grid or not grid.alarmOn then return end
    grid.alarmAck = true
    LiveWire.notify(player, "IGUI_LW_AlarmSilenced", {})
end

handlers[P.C_RENAME] = function(player, args)
    local grid = gridOfInverter(args.inverter)
    if not grid then return end
    local dev, why = Commands.checkDevice(player, grid.inverter)
    if not dev then return refuse(player, P.C_RENAME, why) end
    local name = P.cleanName(args.name)
    if name then
        grid.name = name
        grid.rev = (grid.rev or 0) + 1
        LiveWire.Sim.publish(grid)
    end
end

handlers[P.C_REQUEST_ANCHORS] = function(player, args)
    if isServer() then ModData.transmit(LiveWire.ANCHOR_KEY) end
end

-- A client sees a Live Wire tile without a valid mark for some seconds (placed by a
-- path that skipped our placement wrapper): register it if it really is unbound.
Commands.ADOPT_RANGE = 40
handlers[P.C_ADOPT] = function(player, args)
    local x, y, z = tonumber(args.x), tonumber(args.y), tonumber(args.z)
    if not x or not y or not z then return end
    x, y, z = math.floor(x), math.floor(y), math.floor(z)
    if math.abs(player:getX() - x) > Commands.ADOPT_RANGE or math.abs(player:getY() - y) > Commands.ADOPT_RANGE
        or math.abs(player:getZ() - z) > 3 then
        return
    end
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return end
    if SafeHouse and not SafeHouse.isSafehouseAllowInteract(sq, player) then return end
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
