-- Live Wire: backup generator (authority only).
-- A vanilla generator, wired to an inverter, that the mod starts when the battery
-- stock falls below BackupStartPercent and stops at BackupStopPercent. While running
-- it charges the batteries and burns its own fuel (never on top of the vanilla burn). It stays a vanilla generator:
-- fuel, noise, toxicity indoors, vanilla menus. setActivated syncs to clients and
-- recomputes the powered area (IsoGenerator.java:462-490).
-- The link is kept in the generator ModData under its own key (not the Live Wire
-- device mark), so the vanilla actions on the generator stay available; the
-- generator ModData is saved with it (knowledge/power-and-lights.md:188-192).
if isClient() then return end

LiveWire = LiveWire or {}

local Backup = {}
LiveWire.Backup = Backup

Backup.KEY = LiveWire.Defs.BACKUP_KEY
Backup.CHARGE_W = 1200       -- electrical power delivered to the network
Backup.KWH_PER_LITRE = 3.0   -- petrol to electricity, about a third of its energy
Backup.NOTIFY_RANGE = 30     -- players told why the generator cannot start
local FAIL = { unplugged = true, nofuel = true, broken = true }
local warnedThresholds = {}

local function playersNear(x, y, z, radius)
    local players
    if isServer() then players = getOnlinePlayers() else players = IsoPlayer.getPlayers() end
    if not players then return false end
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p and not p:isDead() then
            local dx, dy = p:getX() - x, p:getY() - y
            if dx * dx + dy * dy <= radius * radius and math.abs(p:getZ() - z) < 3 then return true end
        end
    end
    return false
end

-- Tell the players nearby, once per failure, why the backup generator cannot start
-- (state unplugged / nofuel / broken). Shown again only after it recovered.
local function reportState(dev)
    if not FAIL[dev.state] then
        dev.failShown = nil
        return
    end
    if dev.failShown == dev.state then return end
    if not playersNear(dev.x, dev.y, dev.z, Backup.NOTIFY_RANGE) then return end
    dev.failShown = dev.state
    LiveWire.notifyNear(dev.x, dev.y, dev.z, Backup.NOTIFY_RANGE, "IGUI_LW_BackupCannotStart",
        { "IGUI_LW_Backup_" .. dev.state }, true)
    LiveWire.log("backup generator " .. tostring(dev.id) .. " cannot start: " .. tostring(dev.state))
end
Backup.reportState = reportState

function Backup.markOf(gen)
    local m = gen and gen:getModData()[Backup.KEY]
    if type(m) == "table" and type(m.id) == "string" then return m end
    return nil
end

-- The linked generator object, or nil; second result true when the square is loaded.
function Backup.find(dev)
    local sq = getCell():getGridSquare(dev.x, dev.y, dev.z)
    if not sq then return nil, false end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if instanceof(o, "IsoGenerator") then
            local m = Backup.markOf(o)
            if m and m.id == dev.id then return o, true end
        end
    end
    return nil, true
end

function Backup.register(gen, grid)
    local sq = gen:getSquare()
    local dev = LiveWire.Registry.addDevice({
        role = "backup", model = "BackupGenerator", x = sq:getX(), y = sq:getY(), z = sq:getZ(),
        state = "standby", fuel = gen:getFuel(), fuelSeen = gen:getFuel(),
        connected = gen:isConnected(), cond = gen:getCondition(),
        lastSet = gen:isActivated(), manual = gen:isActivated(),
    })
    gen:getModData()[Backup.KEY] = { id = dev.id, inverter = grid.inverter, manual = dev.manual }
    if isServer() then gen:transmitModData() end
    LiveWire.Registry.link(dev, grid)
    -- Say right away what would stop it from starting.
    local why = nil
    if not gen:isConnected() then why = "unplugged"
    elseif gen:getFuel() <= 0 then why = "nofuel"
    elseif gen:getCondition() <= 0 then why = "broken" end
    if why then
        dev.failShown = why
        local sq2 = gen:getSquare()
        LiveWire.notifyNear(sq2:getX(), sq2:getY(), sq2:getZ(), 5, "IGUI_LW_BackupCannotStart",
            { "IGUI_LW_Backup_" .. why }, true)
    end
    return dev
end

local function publishMode(dev, gen)
    local m = Backup.markOf(gen)
    if m then
        m.manual = dev.manual == true
        if isServer() then gen:transmitModData() end
    end
end

-- lastSet describes the last observed/written *world object* state, not the
-- simulated unloaded state. This distinguishes an external toggle from catch-up.
local function observeManual(dev, gen)
    if not gen then return end
    local active = gen:isActivated()
    if dev.lastSet ~= nil and active ~= dev.lastSet and gen:isConnected()
        and gen:getFuel() > 0 and gen:getCondition() > 0 then
        dev.manual = true
        publishMode(dev, gen)
    end
    dev.lastSet = active
end

function Backup.resume(dev)
    local gen = Backup.find(dev)
    if not gen then return false end
    dev.manual = false
    dev.lastSet = gen:isActivated()
    dev.state = gen:isActivated() and "running" or "standby"
    publishMode(dev, gen)
    return true
end

-- Unlink: the generator is stopped if the mod had started it, then left alone.
function Backup.forget(dev)
    local gen = Backup.find(dev)
    if gen then
        if dev.state == "running" and gen:isActivated() then gen:setActivated(false) end
        gen:getModData()[Backup.KEY] = nil
        if isServer() then gen:transmitModData() end
    end
    LiveWire.Registry.removeDevice(dev.id)
end

local function percent(name, default)
    local v = LiveWire.Config.get(name)
    if type(v) ~= "number" then return default end
    return v / 100
end

-- The stop threshold must leave a real hysteresis even with inverted sandbox
-- settings. Share the effective values with snapshots so the UI tells the truth.
function Backup.thresholds()
    local start = math.max(0, math.min(0.90, percent("BackupStartPercent", 0.2)))
    local configured = math.max(0, math.min(1, percent("BackupStopPercent", 0.9)))
    local stop = math.max(configured, (start * 100 + 5) / 100)
    if stop > configured then
        local key = tostring(start) .. ":" .. tostring(configured)
        if not warnedThresholds[key] then
            warnedThresholds[key] = true
            LiveWire.warn("backup stop threshold raised to " .. tostring(stop * 100)
                .. "% to keep a five-point gap above the start threshold")
        end
    end
    return start, stop
end

-- One sub-step for the backup generator of a network.
-- stockFrac: battery stock / capacity (nil when there is no battery: nothing to do).
-- Returns the electrical power (W) it adds to the network during the sub-step.
function Backup.step(dev, stockFrac, h)
    local gen, loaded = Backup.find(dev)
    if loaded and not gen then return 0 end  -- gone: Sim drops it after two checks
    observeManual(dev, gen)

    local fuel, connected, cond
    if gen then
        fuel, connected, cond = gen:getFuel(), gen:isConnected(), gen:getCondition()
        -- Fuel changed by players while loaded (refuel) becomes the new reference.
        dev.fuel, dev.fuelSeen, dev.connected, dev.cond = fuel, fuel, connected, cond
    else
        fuel, connected, cond = dev.fuel or 0, dev.connected, dev.cond or 0
    end

    local start, stop = Backup.thresholds()
    local want = dev.state == "running"
    if stockFrac == nil then
        want = false
    elseif stockFrac < start then
        want = true
    elseif stockFrac >= stop then
        want = false
    end

    if dev.manual then want = (gen and gen:isActivated() or (not gen and dev.lastSet == true))
        and stockFrac ~= nil end
    local canRun = connected and fuel > 0 and cond > 0
    local run = want and canRun
    if want and not canRun then
        if not connected then dev.state = "unplugged"
        elseif fuel <= 0 then dev.state = "nofuel"
        else dev.state = "broken" end
    elseif run then
        dev.state = "running"
    else
        dev.state = "standby"
    end
    if dev.manual then dev.state = "manual" end
    reportState(dev)

    if gen and not dev.manual then
        if gen:isActivated() ~= run then gen:setActivated(run) end
        dev.lastSet = gen:isActivated()
    end
    if not run then return 0 end

    local litres = Backup.CHARGE_W * h / 1000 / Backup.KWH_PER_LITRE
    local used = math.min(litres, fuel)
    local power = Backup.CHARGE_W * (used / litres)
    if gen then
        -- A loaded running generator already burns getTotalPowerUsing() per hour by
        -- itself (IsoGenerator.java:182-206, 655-657): only burn the part of our
        -- charging budget it does not, so the fuel is never paid twice.
        local vanilla = 0
        if gen:isActivated() then vanilla = gen:getTotalPowerUsing() * h end
        local extra = math.max(0, used - vanilla)
        if extra > 1e-4 then gen:setFuel(fuel - extra) end
        dev.fuel = gen:getFuel()
        dev.fuelSeen = dev.fuel
        if dev.fuel <= 0 then gen:setActivated(false); dev.lastSet = false end
    else
        dev.fuel = fuel - used
    end
    return power
end

-- Chunk loaded: apply the fuel burnt while the generator was not loaded, and the
-- wanted running state. A generator saved while running would also burn, at its
-- first update, every whole hour since its saved lastHour (IsoGenerator.java:182-197,
-- 377, 389): time already counted here. Stopping it first, and starting it again
-- below when it must run, resets lastHour (:470) and cancels that second count.
function Backup.restore(dev)
    local gen = Backup.find(dev)
    if not gen then return end
    observeManual(dev, gen)
    local manualActive = dev.manual and gen:isActivated()
    if gen:isActivated() then gen:setActivated(false) end
    local burnt = (dev.fuelSeen or gen:getFuel()) - (dev.fuel or gen:getFuel())
    if burnt > 0 then gen:setFuel(math.max(0, gen:getFuel() - burnt)) end
    dev.fuel = gen:getFuel()
    dev.fuelSeen = dev.fuel
    local want = dev.state == "running"
    if dev.manual then want = manualActive end
    local run = want and gen:isConnected() and gen:getFuel() > 0
        and gen:getCondition() > 0
    if gen:isActivated() ~= run then gen:setActivated(run) end
    dev.lastSet = gen:isActivated()
    if dev.manual then publishMode(dev, gen) end
end
