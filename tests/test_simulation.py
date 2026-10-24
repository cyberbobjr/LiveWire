"""Offline scenario tests of the Live Wire simulation (embedded Lua 5.1, pip install lupa).

The game world is replaced by stubs: no square is loaded, which is exactly the
"no player in the area" case (the registry carries the state). This proves the
code paths run and the energy balance behaves; it proves nothing about the engine.
Run: python3 -I tests/test_simulation.py
"""
import math
import os
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUA = os.path.join(ROOT, "Contents", "mods", "batman_LiveWire", "42.21", "media", "lua")

FILES = [
    "shared/LiveWire/LW_Core.lua", "shared/LiveWire/LW_Defs.lua", "shared/LiveWire/LW_Config.lua",
    "shared/LiveWire/LW_Consumption.lua", "shared/LiveWire/LW_Physics.lua", "shared/LiveWire/LW_Marks.lua", "shared/LiveWire/LW_Protocol.lua",
    "shared/LiveWire/LW_SquareScan.lua", "shared/LiveWire/LW_Notify.lua", "shared/LiveWire/LW_Anchor.lua", "shared/LiveWire/LW_Install.lua",
    "server/LiveWire/LW_Migration.lua", "server/LiveWire/LW_Registry.lua", "server/LiveWire/LW_Xp.lua",
    "server/LiveWire/LW_Demand.lua", "server/LiveWire/LW_Batteries.lua", "server/LiveWire/LW_Simulation.lua",
    "server/LiveWire/LW_Backup.lua", "server/LiveWire/LW_Computer.lua", "server/LiveWire/LW_Alarm.lua",
    "server/LiveWire/LW_Commands.lua", "server/LiveWire/LW_Devices.lua",
    "server/LiveWire/LW_Pump.lua",
]

STUBS = r"""
function require() end
WORLD = { hours = 7.0, clouds = 0.0, wind = 20.0, snowing = false, temp = 15 }
function isClient() return false end
function isServer() return false end
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = function() end }
    rawset(t, k, e); return e end })
local MD = {}
ModData = {
    getOrCreate = function(k) MD[k] = MD[k] or {}; return MD[k] end,
    get = function(k) return MD[k] end,
    add = function(k, v) MD[k] = v end,
    transmit = function() end, request = function() end,
}
function getGameTime()
    return {
        getWorldAgeHours = function() return WORLD.hours end,
        getTimeOfDay = function() return (WORLD.hours + 7) % 24 end,
        getMonth = function() return WORLD.month or 6 end,
    }
end
function getClimateManager()
    return {
        getCloudIntensity = function() return WORLD.clouds end,
        getWindspeedKph = function() return WORLD.wind end,
        isSnowing = function() return WORLD.snowing end,
        getSnowIntensity = function() return 0 end,
        getTemperature = function() return WORLD.temp end,
        getIsThunderStorming = function() return false end,
        getSeason = function() return { getDawn = function() return 5.1 end,
                                         getDusk = function() return 19.9 end } end,
    }
end
function getCell()
    return { getGridSquare = function() return nil end,
             getChunkForGridSquare = function() return nil end }
end
function getSandboxOptions() return nil end
SandboxVars = nil
local seed = 12345
function ZombRand(a, b)
    seed = (seed * 1103515245 + 12345) % 2147483648
    if b == nil then return seed % a end
    return a + seed % (b - a)
end
function ZombRandFloat(a, b)
    seed = (seed * 1103515245 + 12345) % 2147483648
    return a + (b - a) * (seed / 2147483648)
end
function addSound() end
function sendServerCommand() end
function getTimestampMs() return 0 end
function getOnlinePlayers() return nil end
IsoPlayer = { getPlayers = function() return nil end }
function print() end
"""

FAILS = []


def check(cond, msg):
    if not cond:
        FAILS.append(msg)
        print("FAIL:", msg)


def make():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUBS)
    for rel in FILES:
        with open(os.path.join(LUA, rel), encoding="ascii") as f:
            lua.execute(f.read())
    lua.execute("LiveWire.Registry.init()")
    return lua


SETUP = r"""
local R = LiveWire.Registry
local inv = R.addDevice({ role = "inverter", model = "Inverter", x = 100, y = 100, z = 0,
                          cond = 100, eff = 0.95, level = 7, state = "on" })
local g = R.createGrid(inv)
for i = 1, NPANELS do
    local s = R.addDevice({ role = "source", model = "SolarPanel", x = 100 + i, y = 105, z = 1,
                            cond = 100, eff = 0.95, level = 7, state = "ok" })
    R.link(s, g)
end
if NBATS > 0 then
    local slots = {}
    for i = 1, NBATS do
        slots[i] = { id = 1000 + i, model = "Base.CarBattery2", charge = 0.5, cond = 100, cycles = 0 }
    end
    local bank = R.addDevice({ role = "storage", model = "PowerBank", x = 101, y = 101, z = 0,
                               cond = 100, level = 7, state = "ok", wearFactor = 1, slots = slots })
    R.link(bank, g)
end
if BREAKER then
    local o = R.addDevice({ role = "option", model = "Breaker", x = 99, y = 100, z = 0,
                            cond = 100, level = 7, state = "ok" })
    R.link(o, g)
end
g.demand = DEMAND
g.lastTick = WORLD.hours
GRID, INV = g, inv
"""


def run(lua, hours, step=1 / 6, record=None):
    n = int(round(hours / step))
    for _ in range(n):
        lua.execute("WORLD.hours = WORLD.hours + %r; LiveWire.Sim.tick()" % step)
        if record is not None:
            g = lua.globals().GRID
            record.append((lua.globals().WORLD.hours, g.stock or 0, bool(g.powered),
                           g.production or 0, g.capacity or 0))


def scenario_base():
    lua = make()
    lua.execute("NPANELS = 6; NBATS = 4; DEMAND = 150; BREAKER = false")
    lua.execute(SETUP)
    rec = []
    run(lua, 72, record=rec)
    g = lua.globals().GRID
    inv = lua.globals().INV
    stocks = [r[1] for r in rec]
    check(all(s >= -1e-9 for s in stocks), "stock never negative")
    check(all(r[1] <= r[4] + 1e-6 for r in rec), "stock never above capacity")
    # Night: stock goes down; day: production > 0.
    night = [r for r in rec if 0 <= (r[0] + 7) % 24 < 4]
    day = [r for r in rec if 11 <= (r[0] + 7) % 24 < 14]
    check(all(r[3] == 0 or r[3] < 5 for r in night), "no production at night (after smoothing)")
    check(all(r[3] > 300 for r in day), "6 panels produce > 300 W at noon in clear sky")
    # Inverter wear only while running.
    check(inv.cond < 100 and inv.cond > 95, "inverter wears slowly (%.3f)" % inv.cond)
    # Battery state stays in range.
    lua.execute("""
        BAT_OK = true
        for _, d in pairs(LiveWire.Registry.devices()) do
            for _, s in ipairs(d.slots or {}) do
                if s.charge < 0 or s.charge > 1 or s.cond < 0 or s.cond > 100 then BAT_OK = false end
            end
        end
    """)
    check(lua.globals().BAT_OK, "battery charge and condition in range")
    a = lua.globals().LiveWire.Registry.anchors[inv.id]
    check(a is not None, "anchor published")
    snap = lua.eval("LiveWire.Sim.snapshot(GRID)")
    check(snap.coverage.radius == 20 and snap.coverage.floors == 3, "snapshot carries the covered area")
    check(snap.sources[1].kind == "solar" and snap.sources[1].nominal == 100, "sources carry their family")
    check(len(list(snap.batteries.values())) == 4 and snap.banks == 1, "snapshot lists the 4 batteries of the bank")
    return rec


def scenario_no_battery():
    lua = make()
    lua.execute("NPANELS = 3; NBATS = 0; DEMAND = 130; BREAKER = false")
    lua.execute(SETUP)
    rec = []
    run(lua, 48, record=rec)
    noon = [r for r in rec if 12 <= (r[0] + 7) % 24 < 13]
    night = [r for r in rec if 1 <= (r[0] + 7) % 24 < 4]
    check(all(r[2] for r in noon), "source + inverter, no battery: powered at noon")
    check(not any(r[2] for r in night), "no battery: off at night")
    # Smoothing: count on/off flips in a day; a passing cloud should not flicker.
    lua.execute("WORLD.clouds = 0.0")
    flips = sum(1 for a, b in zip(rec, rec[1:]) if a[2] != b[2])
    check(flips <= 6, "few on/off transitions over 2 days (%d)" % flips)


def scenario_overload(breaker):
    lua = make()
    lua.execute("NPANELS = 2; NBATS = 2; DEMAND = 1800; BREAKER = %s" % ("true" if breaker else "false"))
    lua.execute(SETUP)
    run(lua, 1)
    inv = lua.globals().INV
    if breaker:
        brk = lua.eval("LiveWire.Registry.hasOption(LiveWire.Registry.grid(INV.grid), 'breaker')")
        check(inv.state == "on" and brk.state == "tripped", "overload trips the breaker, not the inverter")
        check(inv.cond == 100, "breaker protects the inverter condition")
        run(lua, 1)
        check(not lua.eval("LiveWire.Registry.grid(INV.grid).powered"), "tripped breaker keeps the house off")
    else:
        check(inv.state == "tripped", "overload trips the inverter")
        check(inv.cond == 97, "trip without breaker costs 3 condition (%.2f)" % inv.cond)


def scenario_catch_up():
    lua = make()
    lua.execute("NPANELS = 6; NBATS = 4; DEMAND = 150; BREAKER = false")
    lua.execute(SETUP)
    # Ten days without any step (e.g. a server paused or no tick), then one step.
    lua.execute("WORLD.hours = WORLD.hours + 240; LiveWire.Sim.tick()")
    g = lua.globals().GRID
    check(g.stock >= 0 and g.stock <= g.capacity + 1e-6, "catch-up keeps stock in range")
    check(abs(lua.globals().GRID.lastTick - lua.globals().WORLD.hours) < 1e-6, "catch-up consumes the elapsed time")


LOADED_BANK = r"""
-- A loaded power bank at (101, 101, 0) holding five car batteries (4 slots).
STATS_SENT = 0
function sendItemStats() STATS_SENT = STATS_SENT + 1 end
local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
end
local function battery(id, frac)
    local it = { _frac = frac, _cond = 100, _md = {} }
    function it:getFullType() return "Base.CarBattery2" end
    function it:getID() return id end
    function it:getCondition() return self._cond end
    function it:setConditionNoSound(c) self._cond = c end
    function it:getCurrentUsesFloat() return self._frac end
    function it:setCurrentUsesFloat(f) self._frac = f end
    function it:getModData() return self._md end
    return it
end
ITEMS = { battery(1, 0.9), battery(2, 0.9), battery(3, 0.9), battery(4, 0.9), battery(5, 0.9) }
local container = { getItems = function() return list(ITEMS) end }
local bank = LiveWire.Registry.addDevice({ role = "storage", model = "PowerBank", x = 101, y = 101, z = 0,
    cond = 100, level = 7, state = "ok", wearFactor = 1, slots = {} })
local obj = { getContainer = function() return container end,
              getModData = function() return { movableData = { LiveWire = { id = bank.id, model = "PowerBank" } } } end }
local square = { getObjects = function() return list({ obj }) end }
local realGetCell = getCell
function getCell()
    local c = realGetCell()
    c.getGridSquare = function(_, x, y, z)
        if x == 101 and y == 101 and z == 0 then return square end
        return nil
    end
    return c
end
LiveWire.Registry.link(bank, GRID)
BANK = bank
"""


def scenario_loaded_bank():
    lua = make()
    lua.execute("NPANELS = 0; NBATS = 0; DEMAND = 150; BREAKER = false")
    lua.execute(SETUP)
    lua.execute(LOADED_BANK)
    run(lua, 4)
    g = lua.globals()
    bank = g.BANK
    check(bank.extra == 1, "fifth battery is not counted (extra = %s)" % bank.extra)
    check(len(list(bank.slots.values())) == 4, "four slots recorded")
    fracs = [g.ITEMS[i]._frac for i in range(1, 6)]
    check(all(f < 0.9 for f in fracs[:4]) and fracs[4] == 0.9, "night drain written on the 4 counted items only")
    check(g.STATS_SENT > 0, "item stats sent to clients")


def scenario_many_sources_one_inverter():
    """Several sources of different families feed one inverter; the powered area is
    centred on the inverter, never on a source."""
    lua = make()
    lua.execute("NPANELS = 3; NBATS = 0; DEMAND = 100; BREAKER = false")
    lua.execute(SETUP)
    lua.execute("""
        local R = LiveWire.Registry
        for i = 1, 2 do
            local w = R.addDevice({ role = "source", model = "WindTurbine", x = 110 + i, y = 90, z = 2,
                                    cond = 100, eff = 0.95, level = 7, state = "ok" })
            R.link(w, GRID)
        end
        WORLD.wind = 40
    """)
    run(lua, 6)
    g = lua.globals()
    snap = lua.eval("LiveWire.Sim.snapshot(GRID)")
    kinds = [snap.sources[i].kind for i in range(1, len(list(snap.sources.values())) + 1)]
    check(kinds.count("solar") == 3 and kinds.count("wind") == 2, "5 sources of 2 families on one inverter")
    total = sum(snap.sources[i].w for i in range(1, 6))
    check(abs(total - snap.production) <= 5, "inverter production is the sum of all its sources")
    a = g.LiveWire.Registry.anchors[g.INV.id]
    check(a is not None and (a.x, a.y, a.z) == (g.INV.x, g.INV.y, g.INV.z),
          "the powered area is centred on the inverter square")


BACKUP_SETUP = r"""
-- A backup generator, a management computer and a low battery alarm, all in
-- unloaded squares (the registry carries their state).
local R = LiveWire.Registry
GEN = R.addDevice({ role = "backup", model = "BackupGenerator", x = 95, y = 100, z = 0,
                    state = "standby", fuel = 10, fuelSeen = 10, connected = true, cond = 100 })
R.link(GEN, GRID)
PC = R.addDevice({ role = "computer", model = "ManagementComputer", x = 100, y = 98, z = 0,
                   level = 7, state = "ok" })
R.link(PC, GRID)
local alarm = R.addDevice({ role = "option", model = "BatteryAlarm", x = 99, y = 99, z = 0,
                            cond = 100, level = 7, state = "ok" })
R.link(alarm, GRID)
LOW = 0
local notifyNear = LiveWire.notifyNear
function LiveWire.notifyNear(x, y, z, r, key, args, bad)
    if key == "IGUI_LW_LowBattery" then LOW = LOW + 1 end
    return notifyNear(x, y, z, r, key, args, bad)
end
"""


def scenario_backup_computer_alarm():
    """No source, two batteries at 50 %, 300 W of demand: the alarm rings under 20 %,
    the backup generator starts under 20 %, charges, burns fuel and stops at 90 %;
    the computer records one point per hour (48 kept)."""
    lua = make()
    lua.execute("NPANELS = 0; NBATS = 2; DEMAND = 300; BREAKER = false")
    lua.execute(SETUP)
    lua.execute(BACKUP_SETUP)
    g = lua.globals()
    states, fracs = [], []
    for _ in range(int(72 * 6)):
        lua.execute("WORLD.hours = WORLD.hours + 1/6; LiveWire.Sim.tick()")
        grid = g.GRID
        states.append(g.GEN.state)
        fracs.append(grid.stock / grid.capacity if grid.capacity else None)
    check("running" in states, "backup generator starts")
    first = states.index("running")
    check(fracs[first - 1] < 0.2 + 1e-6, "it starts under 20 %% (%.3f)" % fracs[first - 1])
    stops = [i for i in range(first, len(states)) if states[i] == "standby"]
    check(stops and fracs[stops[0] - 1] >= 0.9 - 1e-6, "it stops once 90 %% is reached")
    check(g.GEN.fuel < 10, "it burns fuel (%.2f L left)" % g.GEN.fuel)
    check(min(f for f in fracs if f is not None) > 0.1, "the stock never runs out while there is fuel")
    check(g.LOW >= 1, "low battery alarm rang (%d)" % g.LOW)
    hist = list(g.GRID.history.values())
    check(len(hist) == 48, "computer keeps 48 hourly points (%d)" % len(hist))
    snap = lua.eval("LiveWire.Sim.snapshot(GRID)")
    check(snap.backup is not None and snap.backup.start == 20 and snap.backup.stop == 90,
          "snapshot carries the backup and its thresholds")
    check(snap.computer is not None and snap.computer.powered and snap.computer.shed,
          "snapshot carries the powered computer (load shedding at level 7)")
    check(snap.history is not None and snap.dawnH is not None, "snapshot carries history and forecast")
    check(snap.alarm is not None, "snapshot carries the alarm")


def scenario_backup_empty():
    """Out of fuel: the generator never runs and reports it."""
    lua = make()
    lua.execute("NPANELS = 0; NBATS = 2; DEMAND = 300; BREAKER = false")
    lua.execute(SETUP)
    lua.execute(BACKUP_SETUP)
    lua.execute("GEN.fuel = 0")
    run(lua, 24)
    g = lua.globals()
    check(g.GEN.state == "nofuel", "empty generator reports nofuel (%s)" % g.GEN.state)
    check((g.GRID.backupW or 0) == 0, "and adds nothing")


def scenario_alarm_repeat():
    """The alarm repeats every 2 h while low and re-arms above 25 %."""
    lua = make()
    lua.execute("NPANELS = 0; NBATS = 2; DEMAND = 0; BREAKER = false")
    lua.execute(SETUP)
    lua.execute(BACKUP_SETUP)
    lua.execute("""
        local G = GRID
        LiveWire.Alarm.check(G, LiveWire.Registry.hasOption(G, "alarm"), 0.15, 10)
        LiveWire.Alarm.check(G, LiveWire.Registry.hasOption(G, "alarm"), 0.15, 11)
        A1 = LOW
        LiveWire.Alarm.check(G, LiveWire.Registry.hasOption(G, "alarm"), 0.15, 12.1)
        A2 = LOW
        LiveWire.Alarm.check(G, LiveWire.Registry.hasOption(G, "alarm"), 0.22, 12.2)
        LiveWire.Alarm.check(G, LiveWire.Registry.hasOption(G, "alarm"), 0.30, 12.3)
        LiveWire.Alarm.check(G, LiveWire.Registry.hasOption(G, "alarm"), 0.19, 12.4)
        A3 = LOW
    """)
    g = lua.globals()
    check(g.A1 == 1 and g.A2 == 2 and g.A3 == 3, "alarm: once, repeat after 2 h, re-armed above 25 %% (%s %s %s)"
          % (g.A1, g.A2, g.A3))


def scenario_debug():
    """Debug commands: refused without -debug, applied with it."""
    lua = make()
    lua.execute("NPANELS = 0; NBATS = 2; DEMAND = 0; BREAKER = false")
    lua.execute(SETUP)
    lua.execute("""
        Capability = nil
        DEBUG = false
        function isDebugEnabled() return DEBUG end
        -- No loaded square in these tests: the range check is stubbed.
        function LiveWire.Commands.checkDevice(p, id) return LiveWire.Registry.device(id) end
        local reg = LiveWire.Commands.register
        function LiveWire.Commands.register(cmd, fn) ON_DEBUG = fn; return reg(cmd, fn) end
        PLAYER = { getUsername = function() return "tester" end, getX = function() return 100 end,
                   getY = function() return 100 end, getZ = function() return 0 end,
                   isDead = function() return false end }
    """)
    for rel in ("shared/LiveWire/LW_Debug.lua", "server/LiveWire/LW_DebugCommands.lua"):
        with open(os.path.join(LUA, rel), encoding="ascii") as f:
            lua.execute(f.read())
    g = lua.globals()
    run(lua, 1 / 6)
    lua.execute("ON_DEBUG(PLAYER, { action = 'battery15', device = INV.id })")
    check(abs(g.GRID.stock / g.GRID.capacity - 0.5) < 0.05, "debug refused without -debug")
    lua.execute("DEBUG = true; ON_DEBUG(PLAYER, { action = 'battery15', device = INV.id })")
    check(abs(g.GRID.stock / g.GRID.capacity - 0.15) < 0.01, "debug battery15 applied (%.3f)"
          % (g.GRID.stock / g.GRID.capacity))
    lua.execute("ON_DEBUG(PLAYER, { action = 'damageInverter', device = INV.id })")
    check(9.9 < g.INV.cond <= 10, "debug damageInverter applied (%.3f)" % g.INV.cond)
    lua.execute("ON_DEBUG(PLAYER, { action = 'nope', device = INV.id })")


def scenario_pump_demand():
    # Two pumps: one moved 150 L over 1 h (duty 0.5 of 300 L/h -> 125 W), one moved nothing.
    lua = make()
    lua.execute("""
        local P = LiveWire.Pump
        local a = { model = "WaterPump", pumped = 150 }
        local b = { model = "WaterPump", pumped = 0 }
        PUMP_W = P.demandW({ a, b }, 1)
        PUMP_FLOW_A = a.flowLph
        PUMP_FLOW_B = b.flowLph
        PUMP_RESET = (a.pumped == 0 and b.pumped == 0)
    """)
    g = lua.globals()
    check(abs(g.PUMP_W - 125) < 1e-6, "pump demand 125 W for 150 L in 1 h (%s)" % g.PUMP_W)
    check(abs(g.PUMP_FLOW_A - 150) < 1e-6, "pump flow 150 L/h (%s)" % g.PUMP_FLOW_A)
    check(abs(g.PUMP_FLOW_B - 0) < 1e-9, "idle pump flow 0 L/h")
    check(bool(g.PUMP_RESET), "pumped litres reset after the demand step")


SLAVE_SETUP = r"""
-- A slave inverter (own empty grid first, then coupled to the master's grid).
local R = LiveWire.Registry
SLAVE = R.addDevice({ role = "inverter", model = "Inverter", x = 102, y = 100, z = 0,
                      cond = 100, eff = 0.95, level = 7, state = "on" })
R.createGrid(SLAVE)
R.couple(SLAVE, GRID)
"""


def scenario_slave_capacity():
    """Capacity and idle use follow the inverters in service."""
    lua = make()
    lua.execute("NPANELS = 0; NBATS = 0; DEMAND = 0; BREAKER = false")
    lua.execute(SETUP)
    lua.execute(SLAVE_SETUP)
    check(lua.eval("LiveWire.Sim.capacityW(GRID)") == 3000, "master + slave on: capacity 3000 W")
    check(lua.eval("LiveWire.Sim.idleW(GRID)") == 40, "master + slave on: idle 40 W")
    lua.execute("SLAVE.state = 'off'")
    check(lua.eval("LiveWire.Sim.capacityW(GRID)") == 1500, "slave off: capacity 1500 W")
    check(lua.eval("LiveWire.Sim.idleW(GRID)") == 20, "slave off: idle 20 W")


def scenario_slave_breaks():
    """A slave with no condition left breaks in the step and leaves the capacity."""
    lua = make()
    lua.execute("NPANELS = 0; NBATS = 0; DEMAND = 0; BREAKER = false")
    lua.execute(SETUP)
    lua.execute(SLAVE_SETUP)
    lua.execute("SLAVE.cond = 0")
    lua.execute("LiveWire.Sim.stepGrid(GRID, WORLD.hours + 1 / 6, LiveWire.Sim.weather())")
    check(lua.globals().SLAVE.state == "broken", "slave with cond 0 is broken after one step (%s)"
          % lua.globals().SLAVE.state)
    check(lua.eval("LiveWire.Sim.capacityW(GRID)") == 1500, "broken slave: capacity 1500 W")


def scenario_slave_trip():
    """2000 W fits master + slave (3000 W); without the slave (1500 W) it trips."""
    lua = make()
    lua.execute("NPANELS = 0; NBATS = 0; DEMAND = 2000; BREAKER = false")
    lua.execute(SETUP)
    lua.execute(SLAVE_SETUP)
    run(lua, 1 / 6)
    g = lua.globals()
    check(g.INV.state == "on", "2000 W with master + slave on: not tripped (%s)" % g.INV.state)
    lua.execute("SLAVE.state = 'off'")
    run(lua, 1 / 6)
    check(g.INV.state == "tripped", "2000 W with the slave off: master trips (%s)" % g.INV.state)


def scenario_slave_removal():
    """Removing the master uncouples its slave; removing a slave leaves the master's grid."""
    lua = make()
    lua.execute("NPANELS = 0; NBATS = 0; DEMAND = 0; BREAKER = false")
    lua.execute(SETUP)
    lua.execute(SLAVE_SETUP)
    lua.execute("""
        local R = LiveWire.Registry
        local old = GRID.id
        R.removeDevice(INV.id)
        CHK_MASTER = SLAVE.coupled == nil and SLAVE.grid ~= nil and SLAVE.grid ~= old
            and R.grid(SLAVE.grid) ~= nil
    """)
    check(lua.globals().CHK_MASTER, "removing the master: the slave is independent with a new grid")

    lua = make()
    lua.execute("NPANELS = 0; NBATS = 0; DEMAND = 0; BREAKER = false")
    lua.execute(SETUP)
    lua.execute(SLAVE_SETUP)
    lua.execute("""
        local R = LiveWire.Registry
        R.removeDevice(SLAVE.id)
        CHK_SLAVE = R.grid(INV.grid) == GRID and GRID.slaves[SLAVE.id] == nil
            and R.device(SLAVE.id) == nil and R.device(INV.id) == INV
    """)
    check(lua.globals().CHK_SLAVE, "removing a slave: the master's grid stays intact")


CONSUMPTION = r"""
-- Appliance stubs: class name, engine value and state.
local function obj(cls, p, extra)
    local o = { cls = cls, p = p, piped = 0, fridge = false, freezer = false }
    for k, v in pairs(extra or {}) do o[k] = v end
    function o:getGeneratorPowerConsumption() return self.p end
    function o:getPipedFuelAmount() return self.piped end
    function o:getContainerByType(t)
        if t == "fridge" and self.fridge then return {} end
        if t == "freezer" and self.freezer then return {} end
        return nil
    end
    function o:isMicrowave() return self.micro == true end
    function o:isWasherActivated() return self.washerOn == true end
    function o:isDryerActivated() return self.dryerOn == true end
    function o:isModeDryer() return self.dryerMode == true end
    return o
end
function instanceof(o, cls) return o.cls == cls end
APPS = {
    light = obj("IsoLightSwitch", 0.002),
    lightOff = obj("IsoLightSwitch", 0),
    ff = obj("IsoObject", 0.13, { fridge = true, freezer = true }),
    freezer = obj("IsoObject", 0.08, { freezer = true }),
    micro = obj("IsoStove", 0.09, { micro = true }),
    stove = obj("IsoStove", 0.09),
    stacked = obj("IsoStackedWasherDryer", 1.8, { washerOn = true, dryerOn = true }),
    combo = obj("IsoCombinationWasherDryer", 0.09, { dryerMode = true }),
    piped = obj("IsoObject", 0.03, { piped = 5, fridge = true }),
    modded = obj("IsoModdedThing", 0.2),
}
function W(name, profile) return LiveWire.Consumption.watts(APPS[name], profile) end
"""


def scenario_consumption_profiles():
    lua = make()
    lua.execute(CONSUMPTION)
    W = lua.globals().W
    near = lambda a, b: abs(a - b) < 1e-6
    # Default profile = engine values x 1000 (no change for existing saves).
    check(lua.eval("LiveWire.Consumption.profile()") == 3, "default profile is the game values")
    check(near(W("light"), 2) and near(W("ff"), 130) and near(W("stacked"), 1800), "game values unchanged")
    check(W("lightOff") == 0 and W("lightOff", 2) == 0, "an appliance switched off draws nothing")
    check(near(W("light", 2), 60) and near(W("ff", 2), 130) and near(W("freezer", 2), 90), "realistic 1993")
    check(near(W("stove", 2), 2000) and near(W("micro", 2), 1100), "realistic cooker and microwave")
    check(near(W("stacked", 2), 3500) and near(W("combo", 2), 2000), "realistic laundry by function")
    check(near(W("light", 1), 100) and near(W("stacked", 1), 5700), "ultra-realistic 1993")
    check(near(W("stacked", 4), 90) and near(W("ff", 4), 65), "comfort halves and fixes the stacked laundry")
    check(near(W("piped", 2), 30) and near(W("modded", 2), 200) and near(W("modded", 4), 100),
          "gas and unknown appliances keep the engine value")
    lua.execute('SandboxVars = { LiveWire = { ConsumptionProfile = 2, PowerScale = 2 } }')
    check(near(W("light"), 120), "sandbox profile and PowerScale both apply")
    lua.execute('SandboxVars = { LiveWire = { ConsumptionProfile = 9 } }')
    check(near(W("light"), 2), "an unknown profile falls back to the game values")


def main():
    scenario_consumption_profiles()
    scenario_slave_capacity()
    scenario_slave_breaks()
    scenario_slave_trip()
    scenario_slave_removal()
    scenario_pump_demand()
    scenario_debug()
    scenario_backup_computer_alarm()
    scenario_backup_empty()
    scenario_alarm_repeat()
    scenario_many_sources_one_inverter()
    scenario_loaded_bank()
    scenario_base()
    scenario_no_battery()
    scenario_overload(False)
    scenario_overload(True)
    scenario_catch_up()
    print("OK" if not FAILS else "%d failure(s)" % len(FAILS))
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
