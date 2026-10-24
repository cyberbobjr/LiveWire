"""C08/C12/C17-C19/C21/C23/C24 scenarios. Stubs do not validate game APIs."""
import pathlib
import unittest

from test_simulation import make, LUA, SETUP


class Remaining(unittest.TestCase):
    def setUp(self):
        self.lua = make()

    def run_lua(self, source):
        self.lua.execute(source)

    def pump_scene(self):
        self.run_lua('''
        local function list(t) return {size=function() return #t end,get=function(_,i) return t[i+1] end} end
        local R,D,P=LiveWire.Registry,LiveWire.Defs,LiveWire.Pump
        IsoFlagType={waterPiped=1}
        instanceof=function() return false end
        local function square(x,y,z,objects)
            return {getX=function() return x end,getY=function() return y end,getZ=function() return z end,
                getRoom=function() return true end,getObjects=function() return list(objects) end,
                transmitRemoveItemFromSquare=function(_,o)
                    for i=#objects,1,-1 do if objects[i]==o then table.remove(objects,i) end end end}
        end
        local function fluid(amount,capacity)
            return {amount=amount,getAmount=function(s) return s.amount end,
                getFreeCapacity=function(s) return capacity-s.amount end,
                getSpecificFluidAmount=function() return 0 end,
                removeFluid=function(s,n) s.amount=s.amount-n end,
                addFluid=function(s,_,n) s.amount=s.amount+n end}
        end
        local inv=R.addDevice({role="inverter",model="Inverter",x=10,y=10,z=0,state="on"})
        G=R.createGrid(inv);G.powered=true
        FAR=R.addDevice({id="far",role="pump",model="WaterPump",x=4,y=0,z=0,cond=100,
            barrels={water={}},relays={}})
        NEAR=R.addDevice({id="near",role="pump",model="WaterPump",x=1,y=0,z=0,cond=100,
            barrels={water={}},relays={}})
        R.link(FAR,G);R.link(NEAR,G)
        RF=fluid(7.25,25);BF=fluid(50,100)
        local rs
        RELAY={getModData=function(s) s.md=s.md or {[D.RELAY_KEY]={pump=FAR.id}};return s.md end,
            getSquare=function() return rs end,getFluidContainer=function() return RF end,sync=function() end,
            getSprite=function() return {getName=function() return D.RELAY_SPRITE end} end}
        rs=square(0,0,1,{RELAY})
        local fixture={getUsesExternalWaterSource=function() return true end,
            getSprite=function() return {getProperties=function() return {has=function() return true end} end} end}
        local fs=square(0,0,0,{fixture})
        local bs=square(1,0,0,{})
        local barrel={getSquare=function() return bs end,getFluidContainer=function() return BF end,sync=function() end}
        P.findBarrel=function() return barrel,true end
        LiveWire.Install.barrelState=function() return "ok" end
        Fluid={Water=1,TaintedWater=2}
        getCell=function() return {getGridSquare=function(_,x,y,z)
            if x==0 and y==0 and z==1 then return rs end
            if x==0 and y==0 and z==0 then return fs end
            if z==0 and (x==1 or x==4) and y==0 then return bs end
        end} end
        IsoObject={FindExternalWaterSource=function() return RELAY end}
        POS={x=0,y=0,z=1};KEY=LiveWire.posKey(0,0,1)
        FAR.relays[KEY]=POS
        P.inventories.far={fixtures={{x=0,y=0,z=0}},builtAt=WORLD.hours}
        P.inventories.near={fixtures={{x=0,y=0,z=0}},builtAt=WORLD.hours}
        ''')

    def test_closest_pump_takes_existing_water_and_old_owner_cannot_drain_it(self):
        self.pump_scene()
        self.run_lua('''
        local P,D=LiveWire.Pump,LiveWire.Defs
        P.maintain(FAR);P.maintain(NEAR);P.maintain(FAR)
        assert(RELAY:getModData()[D.RELAY_KEY].pump==NEAR.id)
        assert(NEAR.relays[KEY] and not FAR.relays[KEY] and RF.amount==7.25)
        FAR.relays[KEY]=POS -- stale saved entry must not pump into another owner's tank
        P.step(FAR)
        assert(RF.amount==7.25 and BF.amount==50)
        P.removeRelay(FAR,KEY)
        assert(P.findRelay(0,0,1)==RELAY)
        NEAR.barrels={}
        P.maintain(NEAR)
        assert(RELAY:getModData()[D.RELAY_KEY].pump==FAR.id and RF.amount==7.25)
        ''')

    def test_idle_pump_does_not_save_up_flow(self):
        self.pump_scene()
        self.run_lua('''
        local P=LiveWire.Pump
        P.maintain(NEAR)
        RF.amount=25;NEAR.budget=10
        for i=1,10 do P.step(NEAR) end
        assert(NEAR.budget==0 and BF.amount==50)
        RF.amount=15
        P.step(NEAR)
        assert(RF.amount==20 and BF.amount==45)
        ''')

    def test_saved_relay_is_preserved_while_first_discovery_is_pending(self):
        self.pump_scene()
        self.run_lua('''
        local P=LiveWire.Pump
        NEAR.barrels={}
        P.inventories={}
        P.maintain(FAR)
        assert(P.findRelay(0,0,1)==RELAY and FAR.relays[KEY] and RF.amount==7.25)
        ''')

    def test_equal_distance_uses_stable_identity(self):
        self.pump_scene()
        self.run_lua('''
        LiveWire.Registry.moveDevice(FAR,-1,0,0)
        LiveWire.Pump.maintain(NEAR)
        assert(RELAY:getModData()[LiveWire.Defs.RELAY_KEY].pump==FAR.id)
        ''')

    def test_registry_repairs_mark_instead_of_adopting_duplicate(self):
        self.run_lua('''
        local R,D,M=LiveWire.Registry,LiveWire.Devices,LiveWire.Marks
        local dev=R.addDevice({role="source",model="SolarPanel",x=0,y=0,z=0,cond=64,eff=0.9,level=4})
        local md={}
        local obj={getModData=function() return md end,
            getSprite=function() return {getName=function() return "batman_livewire_01_0" end} end}
        local sq={getX=function() return 0 end,getY=function() return 0 end,getZ=function() return 0 end,
            getObjects=function() return {size=function() return 1 end,get=function() return obj end} end}
        getCell=function() return {getGridSquare=function() return sq end} end
        assert(D.validate(dev) and M.get(obj).id==dev.id and M.get(obj).cond==64)
        M.get(obj).eff=1;M.get(obj).cond=100
        assert(D.adoptSquare(nil,sq)==0 and #R.devicesAt(0,0,0)==1)
        assert(M.get(obj).eff==0.9 and M.get(obj).cond==64)
        R.removeDevice(dev.id);md.movableData=nil
        assert(D.adoptSquare(nil,sq)==1)
        local adopted=R.device(M.get(obj).id)
        assert(adopted.eff==0.85 and adopted.level==0)
        sq.getObjects=function() return {size=function() return 0 end} end
        assert(not D.validate(adopted) and not R.device(adopted.id))
        ''')

    def test_partial_step_uses_stock_and_conserves_energy(self):
        self.run_lua('''
        local P=LiveWire.Physics
        local r=P.stepGrid({productionW=0,demandW=980,idleW=20,maxW=1500,eff=1,
            dt=1,wasOn=true,state="on",batteries={{charge=0.3,capacity=0.6}}})
        assert(not r.on and math.abs(r.onHours-0.3)<1e-9)
        assert(math.abs(r.drawnKWh-0.3)<1e-9 and r.stockKWh==0)
        assert(math.abs(r.servedW-300)<1e-9 and r.chargedKWh==0)
        local q=P.stepGrid({productionW=200,demandW=1000,idleW=0,maxW=1500,eff=1,
            dt=1,wasOn=true,state="on",batteries={{charge=0.2,capacity=0.6}}})
        assert(not q.on and math.abs(q.onHours-0.25)<1e-9)
        assert(math.abs(q.stockKWh-0.15*LiveWire.Defs.CHARGE_EFFICIENCY)<1e-9)
        assert(math.abs(q.servedW*1/1000-q.drawnKWh-0.2*q.onHours)<1e-9)
        ''')

    def test_exact_exhaustion_and_restart_threshold(self):
        self.run_lua('''
        local function step(charge,wasOn)
            return LiveWire.Physics.stepGrid({productionW=0,demandW=1000,eff=1,
                dt=1,wasOn=wasOn,state="on",batteries={{charge=charge,capacity=1}}})
        end
        local r=step(1,true)
        assert(not r.on and r.onHours==1 and r.stockKWh==0)
        r=step(0.01,false)
        assert(r.onHours==0 and r.stockKWh==0.01)
        r=step(0.01,true)
        assert(math.abs(r.onHours-0.01)<1e-9 and r.stockKWh==0)
        ''')

    def test_simulation_records_actual_exhaustion_time(self):
        self.run_lua('NPANELS=0;NBATS=1;DEMAND=980;BREAKER=false')
        self.run_lua(SETUP)
        self.run_lua('''
        INV.eff=1
        LiveWire.Registry.setAnchor(INV,true)
        local start=WORLD.hours
        WORLD.hours=WORLD.hours+1
        LiveWire.Sim.tick()
        local log=LiveWire.Registry.data.powerHistory[INV.id].log
        assert(#log==2 and log[1].on and not log[2].on)
        assert(math.abs(log[2].t-start-0.3)<1e-8)
        assert(not GRID.powered and GRID.stock<1e-9)
        ''')

    def test_private_history_exceeds_public_log_without_extra_broadcasts(self):
        self.run_lua('''
        local R,H=LiveWire.Registry,LiveWire.PowerHistory
        local inv={id="history",x=0,y=0,z=0}
        local sent=0
        isServer=function() return true end
        ModData.transmit=function() sent=sent+1 end
        for i=1,40 do WORLD.hours=i*12;R.setAnchor(inv,i%2==1) end
        assert(#R.anchors.history.log==16 and #R.data.powerHistory.history.log==40)
        for i=1,100 do assert(not R.setAnchor(inv,false)) end
        assert(sent==40)
        R.init()
        assert(#R.data.powerHistory.history.log==40) -- no reseeding or alias
        R.anchors.history.log[1].on=not R.anchors.history.log[1].on
        assert(R.anchors.history.log[1].on~=R.data.powerHistory.history.log[25].on)
        R.setAnchor(inv,nil)
        assert(not R.anchors.history and R.data.powerHistory.history.retired)
        WORLD.hours=WORLD.hours+H.HOURS+1
        H.prune(R.data,WORLD.hours)
        assert(not R.data.powerHistory.history)
        ''')

    def test_old_log_upgrade_retains_boundary_and_compacts_by_time(self):
        self.run_lua('''
        local R,H=LiveWire.Registry,LiveWire.PowerHistory
        R.anchors.old={x=0,y=0,z=0,on=false,log0=true,
            log={{t=100,on=false},{t=110,on=true},{t=120,on=false}}}
        WORLD.hours=130;R.init()
        local h=R.data.powerHistory.old
        assert(h.since==100 and h.log0 and #h.log==3)
        H.prune(R.data,110+H.HOURS)
        assert(h.since==110 and h.log0 and #h.log==1 and h.log[1].t==120)
        ''')

    def test_fridge_replays_more_than_sixteen_switches(self):
        self.lua.execute(pathlib.Path(LUA, 'server/LiveWire/LW_FridgeCatchup.lua').read_text())
        self.run_lua('''
        local R=LiveWire.Registry
        local inv={id="food",x=0,y=0,z=0}
        for i=0,39 do WORLD.hours=i*12;R.setAnchor(inv,i%2==0) end
        WORLD.hours=480
        local food={age=0,last=0,ft=0,frozen=false}
        function food:getAge() return self.age end
        function food:setAge(v) self.age=v end
        function food:getLastAged() return self.last end
        function food:setLastAged(v) self.last=v end
        function food:getFreezingTime() return self.ft end
        function food:setFreezingTime(v) self.ft=v end
        function food:isFrozen() return self.frozen end
        function food:setFrozen(v) self.frozen=v end
        function food:canBeFrozen() return false end
        function food:updateAge() end
        instanceof=function(o,c) return o==food and c=="Food" end
        local cont={isFridge=function() return true end,isFreezer=function() return false end,
            getItems=function() return {size=function() return 1 end,get=function() return food end} end}
        local obj={getContainerCount=function() return 1 end,getContainerByIndex=function() return cont end}
        local sq={getX=function() return 0 end,getY=function() return 0 end,
            getObjects=function() return {size=function() return 1 end,get=function() return obj end} end}
        local chunk={getMinLevel=function() return 0 end,getMaxLevel=function() return 0 end,
            getGridSquare=function(_,x,y) if x==0 and y==0 then return sq end end}
        assert(LiveWire.FridgeCatchup.onLoadChunk(chunk)==1)
        assert(math.abs(food.age-12)<1e-8 and food.last==480) -- 240 h cold + 240 h warm
        ''')

    def test_backup_thresholds_and_effective_snapshot(self):
        self.run_lua('NPANELS=0;NBATS=1;DEMAND=0;BREAKER=false')
        self.run_lua(SETUP)
        self.run_lua('''
        SandboxVars={LiveWire={BackupStartPercent=80,BackupStopPercent=20}}
        local R,B=LiveWire.Registry,LiveWire.Backup
        local n=0;LiveWire.warn=function() n=n+1 end
        local s,e=B.thresholds();B.thresholds()
        assert(s==0.8 and math.abs(e-0.85)<1e-9 and n==1)
        local dev=R.addDevice({role="backup",model="BackupGenerator",x=200,y=200,z=0,
            state="standby",fuel=10,connected=true,cond=100})
        R.link(dev,GRID)
        assert(B.step(dev,0.79,1/60)>0)
        assert(B.step(dev,0.82,1/60)>0 and dev.state=="running")
        assert(B.step(dev,0.85,1/60)==0 and dev.state=="standby")
        local snap=LiveWire.Sim.snapshot(GRID)
        assert(math.abs(snap.backup.stop-85)<1e-9)
        SandboxVars.LiveWire.BackupStartPercent=20;SandboxVars.LiveWire.BackupStopPercent=90
        s,e=B.thresholds();assert(s==0.2 and e==0.9)
        ''')

    def test_measurement_sliding_limit_is_per_player_and_survives_init(self):
        self.run_lua('''
        local X,R=LiveWire.Xp,LiveWire.Registry
        local count=0;addXp=function() count=count+1 end;Perks={Electricity=1}
        local function player(n) return {getUsername=function() return n end} end
        local a,b=player("a"),player("b")
        for i=1,5 do assert(X.awardMeasurement(a,"measure:"..i)) end
        assert(not X.awardMeasurement(a,"measure:6") and count==5)
        assert(X.awardMeasurement(b,"measure:6") and count==6)
        X.cooldowns={};R.init()
        assert(not X.awardMeasurement(a,"measure:99"))
        WORLD.hours=WORLD.hours+0.99;X.purge()
        assert(not X.awardMeasurement(a,"measure:100"))
        WORLD.hours=WORLD.hours+0.01;X.purge()
        assert(X.awardMeasurement(a,"measure:100") and count==7)
        ''')

    def test_cleanup_visits_negative_and_high_floors(self):
        self.run_lua('''
        local P,D=LiveWire.Pump,LiveWire.Defs
        local removed={}
        local function list(t) return {size=function() return #t end,get=function(_,i) return t[i+1] end} end
        local function square(z)
            local o={getModData=function() return {[D.RELAY_KEY]={pump="gone"}} end,
                getSprite=function() return {getName=function() return D.RELAY_SPRITE end} end}
            return {getX=function() return 0 end,getY=function() return 0 end,getZ=function() return z end,
                getObjects=function() return list({o}) end,
                transmitRemoveItemFromSquare=function() removed[z]=true end}
        end
        local low,high=square(-2),square(9)
        P.onLoadChunk({getMinLevel=function() return -2 end,getMaxLevel=function() return 9 end,
            getGridSquare=function(_,x,y,z) if x==0 and y==0 then
                if z==-2 then return low elseif z==9 then return high end end end})
        assert(removed[-2] and removed[9])
        ''')


if __name__ == '__main__':
    unittest.main()
