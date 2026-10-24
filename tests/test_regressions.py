"""Targeted C04-C09/C16/C22/C23 regressions; stubs do not validate Java APIs."""
import pathlib
import unittest

from test_simulation import make, LUA


class Regressions(unittest.TestCase):
    def setUp(self):
        self.lua = make()

    def run_lua(self, code):
        self.lua.execute(code)

    def test_chunk_index_lifecycle_and_existing_save(self):
        self.run_lua('''
        local R = LiveWire.Registry
        local a = R.addDevice({role="source",model="SolarPanel",x=-1,y=8,z=0})
        local b = R.addDevice({role="inverter",model="Inverter",x=16,y=16,z=0})
        assert(#R.devicesInChunk(-1,1)==1)
        R.moveDevice(a, 32, 33, -2)
        assert(#R.devicesInChunk(-1,1)==0 and #R.devicesInChunk(4,4)==1)
        R.init()
        assert(#R.devicesInChunk(4,4)==1 and R.inverters[b.id])
        R.removeDevice(a.id)
        assert(#R.devicesInChunk(4,4)==0)
        ''')

    def test_barrel_position_membership_and_legacy_mark(self):
        self.run_lua('''
        local R, I, D = LiveWire.Registry, LiveWire.Install, LiveWire.Defs
        local pump=R.addDevice({role="pump",model="WaterPump",x=0,y=0,z=0,barrels={}})
        local x=1
        local sq={getX=function() return x end,getY=function() return 0 end,getZ=function() return 0 end}
        local md={[D.BARREL_KEY]={pump=pump.id}}
        local obj={getSquare=function() return sq end,getModData=function() return md end}
        pump.barrels[LiveWire.posKey(1,0,0)]={x=1,y=0,z=0}
        assert(I.barrelMark(obj).x==1) -- legacy mark upgraded
        x=2
        assert(I.barrelMark(obj)==nil and md[D.BARREL_KEY]==nil)
        md[D.BARREL_KEY]={pump=pump.id,x=2,y=0,z=0}
        assert(I.barrelMark(obj)==nil) -- position matches, membership does not
        ''')

    def test_future_schema_read_only_index_is_preserved(self):
        self.run_lua('''
        local R=LiveWire.Registry
        local original={future={"unknown"}}
        R.data.byPos=original
        LiveWire.Migration.run=function() return false end
        R.init()
        assert(R.readOnly and R.data.byPos==original)
        assert(R.data.byPos.future[1]=="unknown")
        ''')

    def test_manual_backup_stop_start_resume_and_restore(self):
        self.run_lua('''
        local B=LiveWire.Backup
        local active, fuel = true, 10
        local md={}
        local gen={isActivated=function() return active end,setActivated=function(_,v) active=v end,
          getFuel=function() return fuel end,setFuel=function(_,v) fuel=v end,
          isConnected=function() return true end,getCondition=function() return 100 end,
          getModData=function() return md end,getTotalPowerUsing=function() return 0 end}
        B.find=function() return gen,true end
        local dev={id="d99",state="running",lastSet=true,fuel=10,fuelSeen=10}
        md[B.KEY]={id=dev.id}
        active=false
        assert(B.step(dev,0.01,1/60)==0 and dev.manual and not active)
        B.restore(dev)
        assert(not active and dev.manual)
        active=true
        assert(B.step(dev,0.95,1/60)>0 and active and dev.state=="manual")
        fuel=10; dev.fuelSeen=10; dev.fuel=9
        B.restore(dev)
        assert(active and fuel==9 and dev.manual) -- unloaded burn still reconciled
        assert(B.resume(dev))
        B.step(dev,0.95,1/60)
        assert(not active and not dev.manual)
        B.step(dev,0.01,1/60)
        assert(active)
        ''')

    def test_scan_budget_and_complete_area(self):
        self.run_lua('''
        local S=LiveWire.SquareScan
        local job=S.new(0,0,0,30,3)
        local count, ticks,done=0,0,false
        while not done do
            local used
            done,used=S.step(job,250,function(x,y,z)
                assert(x*x+y*y<=900 and z>=-3 and z<=3)
                count=count+1
            end)
            assert(used<=250)
            ticks=ticks+1
        end
        assert(count==2821*7 and ticks>100)
        ''')

    def test_pump_discovery_and_visual_jobs_share_bounded_budgets(self):
        self.run_lua('''
        local R,P,A=LiveWire.Registry,LiveWire.Pump,LiveWire.Anchor
        local queries=0
        local sq={getRoom=function() return nil end,
            getObjects=function() return {size=function() return 0 end} end}
        getCell=function() return {getGridSquare=function()
            queries=queries+1; return sq end} end
        local inv=R.addDevice({role="inverter",model="Inverter",x=0,y=0,z=0})
        local g=R.createGrid(inv)
        for i=1,3 do
            local dev=R.addDevice({role="pump",model="WaterPump",x=i,y=0,z=0,
                barrels={test={}},relays={}})
            R.link(dev,g)
            P.maintain(dev)
        end
        assert(queries==3) -- queuing does not scan the disc
        queries=0
        P.tickDiscovery()
        assert(queries<=P.SQUARES_PER_TICK)
        queries=0
        for i=1,3 do A.refreshVisuals({x=i,y=0,z=0}) end
        assert(queries==0)
        A.tickVisuals()
        assert(queries<=A.VISUAL_SQUARES_PER_TICK)
        ''')

    def test_snapshot_cache_revision_grid_and_registry_identity(self):
        self.lua.execute(pathlib.Path(LUA, 'client/LiveWire/LW_ClientState.lua').read_text())
        self.run_lua('''
        local R,C=LiveWire.Registry,LiveWire.Client
        local inv=R.addDevice({role="inverter",model="Inverter",x=0,y=0,z=0})
        local g=R.createGrid(inv)
        local calls=0
        LiveWire.Sim.snapshot=function() calls=calls+1; return {n=calls} end
        local a=C.snapshot(inv.id)
        assert(C.snapshot(inv.id)==a and calls==1)
        g.rev=g.rev+1
        assert(C.snapshot(inv.id)~=a and calls==2)
        local fresh={id=g.id,rev=g.rev,members={},inverter=inv.id}
        R.data.grids[g.id]=fresh
        C.snapshot(inv.id)
        assert(calls==3)
        R.removeDevice(inv.id)
        assert(C.snapshot(inv.id)==nil)
        ''')

    def test_xp_purge_preserves_long_cooldown(self):
        self.run_lua('''
        addXp=function() end; Perks={Electricity=1}
        local ch={getUsername=function() return "test" end,getPlayerNum=function() return 0 end}
        local X=LiveWire.Xp
        assert(X.awardLimited(ch,"daily",1,24))
        assert(X.awardLimited(ch,"long",1,48))
        WORLD.hours=WORLD.hours+25
        X.purge()
        assert(X.cooldowns.test.daily==nil and X.cooldowns.test.long~=nil)
        assert(not X.awardLimited(ch,"long",1,48))
        WORLD.hours=WORLD.hours+24
        X.purge()
        assert(X.cooldowns.test==nil)
        ''')

    def test_fridges_aged_before_anchor_changes_without_disc_scan(self):
        self.run_lua('''
        local A=LiveWire.Anchor
        local aged,power,queries=0,true,0
        local food={updateAge=function() assert(power); aged=aged+1 end}
        instanceof=function(o,c) return o==food and c=="Food" end
        local items={size=function() return 1 end,get=function() return food end}
        local cont={getType=function() return "fridge" end,getItems=function() return items end}
        local obj,sq
        sq={getX=function() return 0 end,getY=function() return 0 end,getZ=function() return 0 end,
          getObjects=function() return {size=function() return 1 end,get=function() return obj end} end}
        obj={getSquare=function() return sq end,getObjectIndex=function() return 0 end,
          getContainerByType=function(_,t) return t=="fridge" and cont or nil end,
          getContainerCount=function() return 1 end,getContainerByIndex=function() return cont end}
        getCell=function() return {getGridSquare=function(_,x,y,z)
            queries=queries+1; if x==0 and y==0 and z==0 then return sq end end} end
        A.rememberSquare(sq)
        A.apply=function(_,on) power=on end
        A.refreshVisuals=function() end
        A.appliedState.test=true
        A.set("test",{x=0,y=0,z=0},false)
        assert(aged==1 and not power and queries<5)
        ''')

    def test_safehouse_and_inspection_has_no_brake_side_effect(self):
        self.lua.execute('''
        ISBaseTimedAction={derive=function(self) return setmetatable({}, {__index=self}) end}
        ''')
        self.lua.execute(pathlib.Path(LUA, 'shared/LiveWire/TimedActions/LW_TimedActions.lua').read_text())
        self.run_lua('''
        local R=LiveWire.Registry
        local dev=R.addDevice({role="source",model="WindTurbine",x=0,y=0,z=0,cond=100})
        local sq={getX=function() return 0 end,getY=function() return 0 end,getZ=function() return 0 end}
        local obj={getSquare=function() return sq end,getObjectIndex=function() return 0 end}
        LiveWire.Marks.get=function() return {id=dev.id} end
        local ch={getX=function() return 0 end,getY=function() return 0 end,getZ=function() return 0 end}
        local action={character=ch,target=obj}
        SafeHouse={isSafehouseAllowInteract=function() return false end}
        assert(LWInspectAction.complete(action)==false)
        dev.snow=1
        assert(LWClearSnowAction.complete(action)==false and dev.snow==1)
        SafeHouse.isSafehouseAllowInteract=function() return true end
        LiveWire.Xp.awardLimited=function() end; LiveWire.notify=function() end
        assert(LWInspectAction.complete(action)==true and dev.brake==nil)
        assert(LWClearSnowAction.complete(action)==true and dev.snow==0)
        ''')


if __name__ == '__main__':
    unittest.main()
