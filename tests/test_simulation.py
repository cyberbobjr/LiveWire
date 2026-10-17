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
    "shared/LiveWire/LW_Physics.lua", "shared/LiveWire/LW_Marks.lua", "shared/LiveWire/LW_Protocol.lua",
    "shared/LiveWire/LW_Notify.lua", "shared/LiveWire/LW_Anchor.lua", "shared/LiveWire/LW_Install.lua",
    "server/LiveWire/LW_Migration.lua", "server/LiveWire/LW_Registry.lua", "server/LiveWire/LW_Xp.lua",
    "server/LiveWire/LW_Demand.lua", "server/LiveWire/LW_Batteries.lua", "server/LiveWire/LW_Simulation.lua",
]

STUBS = r"""
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
    check(inv.state == "tripped", "overload trips the inverter")
    if breaker:
        check(inv.cond == 100, "breaker protects the inverter condition")
    else:
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
              getModData = function() return { LiveWire = { id = bank.id, model = "PowerBank" } } end }
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


def main():
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
