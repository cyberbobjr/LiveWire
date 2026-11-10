"""Offline tests of the circuit extension point LW_CircuitProvider (D-35, D-37), Lua 5.1 (pip install lupa).

Without a provider an appliance is cut only by its panel's circuits (I21). A registered
provider may cut more appliances (a sub-mod's breakers, D-37 for unconnected points), never
fewer: the base panel stays the main breaker. Demand exposes each measured appliance's watts.
Run: python tests/test_circuit_provider.py
"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import test_review_fixes as review  # noqa: E402
import test_simulation as ts  # noqa: E402


class CircuitProvider(unittest.TestCase):
    def setUp(self):
        fixtures = review.ReviewFixes()          # reuse the I21 appliance doubles, not its tests
        fixtures.setUp()
        fixtures.appliances()
        self.lua = fixtures.lua
        self.run_lua('''
        GRID.equipmentOff=false
        LiveWire.Circuits.owner=function() return GRID end
        CALLS={}
        function provider(verdict)
            return {blocked=function(o,kind,grid) CALLS[#CALLS+1]={o=o,kind=kind,grid=grid}; return verdict(o) end}
        end
        ''')

    def run_lua(self, code):
        return self.lua.execute(code)

    def test_without_provider_only_the_panel_circuits_cut(self):
        self.run_lua('''
        local CP=LiveWire.CircuitProvider
        local f=fridge()
        assert(LiveWire.Circuits.blocked(f)==false)
        GRID.equipmentOff=true
        assert(LiveWire.Circuits.blocked(f)==true)
        ''')

    def test_blocked_as_takes_the_known_family_without_recomputing_it(self):
        self.run_lua('''
        local f=fridge()
        local kinds=0
        local real=LiveWire.Appliances.kind
        LiveWire.Appliances.kind=function(o) kinds=kinds+1;return real(o) end
        assert(LiveWire.Circuits.blockedAs(f,'fridge')==false and kinds==0)
        GRID.equipmentOff=true
        assert(LiveWire.Circuits.blockedAs(f,'fridge')==true and kinds==0)
        assert(LiveWire.Circuits.blockedAs(f,nil)==false)
        assert(LiveWire.Circuits.blocked(f)==true and kinds==1)
        ''')

    def test_provider_cuts_an_appliance_the_panel_leaves_on(self):
        self.run_lua('''
        local CP=LiveWire.CircuitProvider
        local f=fridge()
        assert(CP.register(provider(function(o) return o==f end)))
        assert(LiveWire.Circuits.blocked(f)==true)
        assert(CALLS[1].kind=='fridge' and CALLS[1].grid==GRID)
        LiveWire.Circuits.applyObject(f)
        assert(f.container.kind=='none' and LiveWire.Appliances.saved(f).cut==true)
        ''')

    def test_provider_never_reopens_a_circuit_the_panel_opened(self):
        self.run_lua('''
        local f=fridge()
        assert(LiveWire.CircuitProvider.register(provider(function() return false end)))
        GRID.equipmentOff=true
        assert(LiveWire.Circuits.blocked(f)==true)
        ''')

    def test_provider_release_restores_the_appliance(self):
        self.run_lua('''
        local f=fridge();CUT=true
        assert(LiveWire.CircuitProvider.register(provider(function() return CUT end)))
        LiveWire.Circuits.applyObject(f);assert(f.container.kind=='none')
        CUT=false;LiveWire.Circuits.applyObject(f)
        assert(f.container.kind=='fridge' and not LiveWire.Appliances.saved(f))
        ''')

    def test_provider_cuts_an_appliance_outside_every_grid(self):
        # a point wired to an open breaker before any inverter serves it (twilight switch by day)
        self.run_lua('''
        local f=fridge();CUT=true
        LiveWire.Circuits.owner=function() return nil end
        assert(LiveWire.CircuitProvider.register(provider(function() return CUT end)))
        LiveWire.Circuits.applyObject(f)
        local s=LiveWire.Appliances.saved(f)
        assert(f.container.kind=='none' and s.cut==true and s.owner==nil)
        CUT=false;LiveWire.Circuits.applyObject(f)
        assert(f.container.kind=='fridge' and not LiveWire.Appliances.saved(f))
        ''')

    def test_registration_rules(self):
        self.run_lua('''
        local CP=LiveWire.CircuitProvider
        local ok,why=CP.register({})
        assert(not ok and why=='invalid_provider')
        assert(CP.register(provider(function() return nil end)))
        ok,why=CP.register(provider(function() return nil end))
        assert(not ok and why=='already_registered')
        ''')

    def test_registration_closes_with_global_moddata(self):
        # The stub Events table drops handlers: replay OnInitGlobalModData by hand.
        lua = ts.lua51.LuaRuntime(unpack_returned_tuples=True)
        lua.execute(ts.STUBS)
        lua.execute("""INIT = {}
            Events = setmetatable({}, { __index = function(t, k)
                local e = { Add = function(fn) if k == 'OnInitGlobalModData' then INIT[#INIT + 1] = fn end end }
                rawset(t, k, e); return e end })""")
        for rel in ("shared/LiveWire/LW_Extension.lua", "shared/LiveWire/LW_CircuitProvider.lua"):
            with open(os.path.join(ts.LUA, rel), encoding="ascii") as f:
                lua.execute(f.read())
        lua.execute("for _, fn in ipairs(INIT) do fn() end")
        self.assertEqual(tuple(lua.eval(
            "{LiveWire.CircuitProvider.register({blocked=function() end})}").values()), (False, "registration_closed"))

    def test_live_wire_devices_cut_by_the_provider(self):
        self.run_lua('''
        local CP=LiveWire.CircuitProvider
        local pump={id='p1',role='pump'}
        assert(CP.deviceBlocked(pump)==false)
        assert(CP.register({blocked=function() return false end,deviceBlocked=function(d) return d==pump end}))
        assert(CP.deviceBlocked(pump)==true)
        assert(CP.deviceBlocked({id='c1',role='computer'})==false)
        ''')

    def test_provider_without_device_function(self):
        self.run_lua('''
        local CP=LiveWire.CircuitProvider
        assert(CP.register(provider(function() return true end)))
        assert(CP.deviceBlocked({id='p1'})==false)
        ''')

    def test_demand_exposes_each_measured_appliance(self):
        self.run_lua('''
        local f1,f2=fridge(),fridge()
        local e={objects={f1,f2},readings={130,0},owners={true,false},measured=true}
        LiveWire.Demand.inventories[INV.id]=e
        SEEN={}
        LiveWire.Demand.each(INV,function(o,w) SEEN[#SEEN+1]={o=o,w=w} end)
        assert(#SEEN==1 and SEEN[1].o==f1 and SEEN[1].w==130)
        LiveWire.Demand.inventories[INV.id]=nil
        SEEN={};LiveWire.Demand.each(INV,function(o,w) SEEN[#SEEN+1]=o end)
        assert(#SEEN==0)
        ''')


if __name__ == "__main__":
    unittest.main()
