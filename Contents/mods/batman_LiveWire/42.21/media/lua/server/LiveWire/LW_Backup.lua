-- Live Wire: backup generator (authority only).
-- A vanilla generator, wired to an inverter, that the mod starts when the battery
-- stock falls below BackupStartPercent and stops at BackupStopPercent. While running
-- it charges the batteries and burns its own fuel. It stays a vanilla generator:
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
    })
    gen:getModData()[Backup.KEY] = { id = dev.id }
    if isServer() then gen:transmitModData() end
    LiveWire.Registry.link(dev, grid)
    return dev
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

-- One sub-step for the backup generator of a network.
-- stockFrac: battery stock / capacity (nil when there is no battery: nothing to do).
-- Returns the electrical power (W) it adds to the network during the sub-step.
function Backup.step(dev, stockFrac, h)
    local gen, loaded = Backup.find(dev)
    if loaded and not gen then return 0 end  -- gone: Sim drops it after two checks

    local fuel, connected, cond
    if gen then
        fuel, connected, cond = gen:getFuel(), gen:isConnected(), gen:getCondition()
        -- Fuel changed by players while loaded (refuel) becomes the new reference.
        dev.fuel, dev.fuelSeen, dev.connected, dev.cond = fuel, fuel, connected, cond
    else
        fuel, connected, cond = dev.fuel or 0, dev.connected, dev.cond or 0
    end

    local start, stop = percent("BackupStartPercent", 0.2), percent("BackupStopPercent", 0.9)
    local want = dev.state == "running"
    if stockFrac == nil then
        want = false
    elseif stockFrac < start then
        want = true
    elseif stockFrac >= stop then
        want = false
    end

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

    if gen and gen:isActivated() ~= run then gen:setActivated(run) end
    if not run then return 0 end

    local litres = Backup.CHARGE_W * h / 1000 / Backup.KWH_PER_LITRE
    local used = math.min(litres, fuel)
    local power = Backup.CHARGE_W * (used / litres)
    if gen then
        gen:setFuel(fuel - used)
        dev.fuel = gen:getFuel()
        dev.fuelSeen = dev.fuel
        if dev.fuel <= 0 then gen:setActivated(false) end
    else
        dev.fuel = fuel - used
    end
    return power
end

-- Chunk loaded: apply the fuel burnt while the generator was not loaded, and the
-- wanted running state.
function Backup.restore(dev)
    local gen = Backup.find(dev)
    if not gen then return end
    local burnt = (dev.fuelSeen or gen:getFuel()) - (dev.fuel or gen:getFuel())
    if burnt > 0 then gen:setFuel(math.max(0, gen:getFuel() - burnt)) end
    dev.fuel = gen:getFuel()
    dev.fuelSeen = dev.fuel
    local run = dev.state == "running" and gen:isConnected() and gen:getFuel() > 0
    if gen:isActivated() ~= run then gen:setActivated(run) end
end
