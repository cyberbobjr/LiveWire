"""Internal event bus (D-52): LiveWire.Events and the calls it replaced (embedded Lua 5.1, pip install lupa).

The bus tests load only LW_EventBus.lua. The wiring tests load the whole mod under the stubs of
test_simulation (the same files, the same order) and prove WHO is told WHAT and in which order;
they prove nothing about the engine.
Run: cd tests && python -m unittest test_event_bus
"""
import os
import unittest
from pathlib import Path

from lupa import lua51

from test_simulation import LUA, make

BUS = "shared/LiveWire/LW_EventBus.lua"


def bare():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("function require() end")
    with open(os.path.join(LUA, BUS), encoding="ascii") as f:
        lua.execute(f.read())
    return lua


class Bus(unittest.TestCase):
    def setUp(self):
        self.lua = bare()

    def test_subscribers_run_in_registration_order_with_the_arguments(self):
        self.lua.execute("""
        LOG = {}
        local E = LiveWire.Events
        E.on(E.TOPOLOGY_CHANGED, function(a, b) LOG[#LOG + 1] = "a" .. tostring(a) .. tostring(b) end)
        E.on(E.TOPOLOGY_CHANGED, function(a, b) LOG[#LOG + 1] = "b" .. tostring(a) .. tostring(b) end)
        E.emit(E.TOPOLOGY_CHANGED, 7, "x")
        """)
        self.assertEqual(self.lua.eval('table.concat(LOG, ",")'), "a7x,b7x")

    def test_the_same_function_registered_twice_runs_once(self):
        self.lua.execute("""
        N = 0
        local E = LiveWire.Events
        local fn = function() N = N + 1 end
        E.on(E.TOPOLOGY_CHANGED, fn)
        E.on(E.TOPOLOGY_CHANGED, fn)
        E.emit(E.TOPOLOGY_CHANGED)
        """)
        self.assertEqual(self.lua.eval("N"), 1)

    def test_the_same_function_may_serve_two_different_events(self):
        self.lua.execute("""
        N = 0
        local E = LiveWire.Events
        local fn = function() N = N + 1 end
        E.on(E.TOPOLOGY_CHANGED, fn)
        E.on(E.REGISTRY_RESET, fn)
        E.emit(E.TOPOLOGY_CHANGED)
        E.emit(E.REGISTRY_RESET)
        """)
        self.assertEqual(self.lua.eval("N"), 2)

    def test_emit_without_a_subscriber_does_nothing(self):
        self.lua.execute("LiveWire.Events.emit(LiveWire.Events.TOPOLOGY_CHANGED, 1, 2, 3)")

    def test_off_removes_only_that_function(self):
        self.lua.execute("""
        LOG = {}
        local E = LiveWire.Events
        local a = function() LOG[#LOG + 1] = "a" end
        local b = function() LOG[#LOG + 1] = "b" end
        E.on(E.TOPOLOGY_CHANGED, a)
        E.on(E.TOPOLOGY_CHANGED, b)
        E.off(E.TOPOLOGY_CHANGED, a)
        E.off(E.TOPOLOGY_CHANGED, a)
        E.emit(E.TOPOLOGY_CHANGED)
        """)
        self.assertEqual(self.lua.eval('table.concat(LOG, ",")'), "b")

    def test_a_subscriber_added_during_an_emit_waits_for_the_next_one(self):
        self.lua.execute("""
        LOG = {}
        local E = LiveWire.Events
        local late = function() LOG[#LOG + 1] = "late" end
        E.on(E.TOPOLOGY_CHANGED, function() LOG[#LOG + 1] = "first"; E.on(E.TOPOLOGY_CHANGED, late) end)
        E.emit(E.TOPOLOGY_CHANGED)
        E.emit(E.TOPOLOGY_CHANGED)
        """)
        self.assertEqual(self.lua.eval('table.concat(LOG, ",")'), "first,first,late")

    def test_an_unknown_name_is_a_programming_error(self):
        self.assertFalse(self.lua.eval("(pcall(function() LiveWire.Events.emit('NOPE') end))"))
        self.assertFalse(self.lua.eval("(pcall(function() LiveWire.Events.on('NOPE', function() end) end))"))
        self.assertFalse(self.lua.eval("(pcall(function() LiveWire.Events.on(LiveWire.Events.TOPOLOGY_CHANGED, 5) end))"))


SHAPE = """
local R = LiveWire.Registry
local function inverter()
    local inv = R.addDevice({ role = "inverter", model = "Inverter", x = 1, y = 1, z = 0,
                              cond = 100, eff = 0.95, level = 7, state = "on" })
    return inv, R.createGrid(inv)
end
"""


class Wiring(unittest.TestCase):
    def setUp(self):
        self.lua = make()

    def test_removing_an_inverter_announces_release_topology_then_forget(self):
        self.lua.execute(SHAPE + """
        CALLS = {}
        LiveWire.Circuits.release = function() CALLS[#CALLS + 1] = "release" end
        LiveWire.Circuits.topologyChanged = function() CALLS[#CALLS + 1] = "topology" end
        LiveWire.Demand.forget = function(id) CALLS[#CALLS + 1] = "forget:" .. id end
        local inv = inverter()
        INV_ID = inv.id
        R.removeDevice(inv.id)
        """)
        self.assertEqual(self.lua.eval('table.concat(CALLS, ",")'), "release,topology,forget:" + self.lua.eval("INV_ID"))

    def test_only_a_breaker_releases_the_grid_when_unlinked(self):
        self.lua.execute(SHAPE + """
        REL = 0
        LiveWire.Circuits.release = function() REL = REL + 1 end
        local _, g = inverter()
        local b = R.addDevice({ role = "option", model = "Breaker", x = 2, y = 1, z = 0, cond = 100, state = "ok" })
        local s = R.addDevice({ role = "source", model = "SolarPanel", x = 3, y = 1, z = 0,
                                cond = 100, eff = 0.95, level = 7, state = "ok" })
        R.link(b, g); R.link(s, g)
        R.unlink(s)
        assert(REL == 0)
        R.unlink(b)
        assert(REL == 1)
        """)

    def test_journal_entries_reach_the_journal_through_the_bus(self):
        self.lua.execute(SHAPE + """
        SEEN = {}
        LiveWire.Journal.add = function(g, key, args) SEEN[#SEEN + 1] = key .. ":" .. tostring(args and args[2]) end
        local _, g = inverter()
        local s = R.addDevice({ role = "source", model = "SolarPanel", x = 3, y = 1, z = 0,
                                cond = 100, eff = 0.95, level = 7, state = "ok" })
        R.link(s, g)
        R.unlink(s)
        """)
        self.assertEqual(self.lua.eval('table.concat(SEEN, ",")'),
                         "IGUI_LW_Event_State:IGUI_LW_Event_Connected,IGUI_LW_Event_State:IGUI_LW_Event_Disconnected")

    def test_a_registry_reset_reaches_circuits_and_demand(self):
        self.lua.execute("""
        CALLS = {}
        LiveWire.Circuits.reset = function() CALLS[#CALLS + 1] = "circuits" end
        LiveWire.Demand.reset = function() CALLS[#CALLS + 1] = "demand" end
        LiveWire.Registry.init()
        """)
        # The order between the two subscribers is not part of the contract (file load order).
        self.assertEqual(sorted(self.lua.eval('table.concat(CALLS, ",")').split(",")), ["circuits", "demand"])

    def test_anchor_wrappers_reach_fridges_and_visuals(self):
        self.lua.execute("""
        LiveWire.FridgeAging.age = function(a, id) AGED = id end
        LiveWire.AnchorVisuals.refresh = function(a, id) SHOWN = id end
        LiveWire.Anchor.ageFridges({}, "inv1")
        LiveWire.Anchor.refreshVisuals({}, "inv2")
        """)
        self.assertEqual(self.lua.eval("AGED"), "inv1")
        self.assertEqual(self.lua.eval("SHOWN"), "inv2")

    PLACEMENT = """
    ISMoveableSpriteProps = {
        canPickUpMoveableInternal = function() return true end,
        canRotateMoveableInternal = function() return true end,
        canPlaceMoveableInternal = function() return true end,
        getInfoPanelDescription = function() return {} end,
        placeMoveableInternal = function() return "r" end,
        pickUpMoveableInternal = function() end,
        rotateMoveable = function() end,
    }
    """

    def place(self, sprite, client=False):
        lua = self.lua
        lua.execute(self.PLACEMENT)
        lua.execute(Path(LUA, "shared/LiveWire/LW_Placement.lua").read_text(encoding="ascii"))
        lua.execute("""
        LiveWire.Devices.onPlaced = function() end
        LOG = {}
        local E = LiveWire.Events
        for _, name in ipairs({ "SQUARE_CHANGED", "DEVICE_PLACED", "COVERAGE_CHANGED", "SQUARE_OBJECTS_CHANGED" }) do
            E.on(E[name], function() LOG[#LOG + 1] = name end)
        end
        SQ = { getX = function() return 0 end, getY = function() return 0 end, getZ = function() return 0 end,
               getObjects = function() return { size = function() return 0 end } end }
        """)
        if client:
            lua.execute("isClient = function() return true end")
        lua.execute("assert(ISMoveableSpriteProps:placeMoveableInternal(nil, SQ, nil, '%s') == 'r')" % sprite)
        return lua.eval('table.concat(LOG, ",")')

    def test_placing_one_of_our_tiles_announces_in_a_fixed_order(self):
        self.assertEqual(self.place("batman_livewire_01_16"),
                         "SQUARE_CHANGED,DEVICE_PLACED,COVERAGE_CHANGED,SQUARE_OBJECTS_CHANGED")

    def test_placing_other_furniture_does_not_announce_a_device(self):
        self.assertEqual(self.place("some_other_sprite_0"),
                         "SQUARE_CHANGED,COVERAGE_CHANGED,SQUARE_OBJECTS_CHANGED")

    def test_a_client_only_announces_the_square(self):
        self.assertEqual(self.place("batman_livewire_01_16", client=True), "SQUARE_CHANGED")

    def test_pickup_and_rotation_of_our_tiles_reach_the_devices_through_the_bus(self):
        lua = self.lua
        lua.execute(self.PLACEMENT)
        lua.execute(Path(LUA, "shared/LiveWire/LW_Placement.lua").read_text(encoding="ascii"))
        lua.execute("""
        LOG = {}
        LiveWire.Stack.canMove = function() return true end
        LiveWire.Defs.modelOfObject = function() return "SolarPanel" end
        LiveWire.Devices.beforePickUp = function(o) LOG[#LOG + 1] = "before"; return "d1" end
        LiveWire.Devices.onPickedUp = function(id, ch) LOG[#LOG + 1] = "picked:" .. id .. ":" .. tostring(ch) end
        LiveWire.Devices.beginRotation = function() LOG[#LOG + 1] = "begin" end
        LiveWire.Devices.endRotation = function() LOG[#LOG + 1] = "end" end
        local gone = { getObjectIndex = function() return -1 end }
        ISMoveableSpriteProps:pickUpMoveableInternal("me", {}, gone, nil, "batman_livewire_01_16", true, false)
        ISMoveableSpriteProps:rotateMoveable("me", {}, LiveWire.Defs.SHEET .. "_0")
        """)
        self.assertEqual(lua.eval('table.concat(LOG, ",")'), "before,picked:d1:me,begin,end")


if __name__ == "__main__":
    unittest.main()
