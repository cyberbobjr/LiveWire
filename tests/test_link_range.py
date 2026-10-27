"""Cable floor limits under Lua 5.1 doubles; no engine or multiplayer claims."""
from pathlib import Path
import unittest

from test_simulation import make, LUA


class LinkRange(unittest.TestCase):
    def setUp(self):
        self.lua = make()
        self.lua.execute('''
        function list(t) return {size=function() return #t end,get=function(_,i) return t[i+1] end} end
        function instanceof(o,c) return o.class==c end
        LiveWire.Marks.get=function(o) return o.mark end
        LiveWire.Marks.isOurs=function(o) return o.mark~=nil end
        Perks={Electricity=1}
        PLAYER={getPerkLevel=function() return 10 end,getUsername=function() return 'test' end,
            getInventory=function() return {getCountTypeRecurse=function() return 100 end} end}
        SQUARES={}
        function object(x,y,z,model,id,class)
            local sq={getX=function() return x end,getY=function() return y end,getZ=function() return z end}
            local o={class=class,mark=model and {model=model,id=id},
                getSquare=function() return sq end,getObjectIndex=function() return 0 end,
                getModData=function() return {} end}
            sq.getObjects=function() return list({o}) end
            SQUARES[x..','..y..','..z]=sq
            return o
        end
        getCell=function() return {getGridSquare=function(_,x,y,z)
            assert(z>=-32 and z<=31,'scan outside world floors')
            return SQUARES[x..','..y..','..z]
        end} end
        INVERTER=object(0,0,0,'Inverter','d1')
        SOLAR=object(0,0,2,'SolarPanel','d2')
        GENERATOR=object(0,0,2,nil,nil,'IsoGenerator')
        ''')

    def test_default_accepts_rooftop_sources_and_backup_in_both_directions(self):
        self.lua.execute('''
        local I=LiveWire.Install
        assert(LiveWire.Config.get('LinkVerticalRange')==3)
        for _,dz in ipairs({-3,-2,-1,0,1,2,3}) do
            local solar=object(0,0,dz,'SolarPanel','d2')
            local backup=object(0,0,dz,nil,nil,'IsoGenerator')
            for _,target in ipairs({solar,backup}) do
                local ok,why,wires=I.checkLink(PLAYER,target,INVERTER)
                assert(ok and why==nil and wires==1,'expected reachable floor '..dz)
            end
        end
        for _,dz in ipairs({-4,4}) do
            local ok,why,actual,limit=I.checkLink(PLAYER,object(0,0,dz,'SolarPanel','d2'),INVERTER)
            assert(not ok and why=='Tooltip_LW_TooManyFloors' and actual=='4' and limit=='3')
        end
        ''')

    def test_live_setting_controls_links_and_coupling_including_zero(self):
        self.lua.execute('''
        local floors=3
        SandboxVars={LiveWire={LinkVerticalRange=1}}
        getSandboxOptions=function() return {getOptionByName=function(_,name)
            if name=='LiveWire.LinkVerticalRange' then return {getValue=function() return floors end} end
        end} end
        for _,limit in ipairs({0,1,3,10}) do
            floors=limit
            for _,dz in ipairs({-limit,limit}) do
                assert(LiveWire.Install.checkLink(PLAYER,object(0,0,dz,'SolarPanel','d2'),INVERTER))
                assert(LiveWire.Install.checkCouple(PLAYER,object(0,0,dz,'Inverter','d3'),INVERTER))
            end
            for _,dz in ipairs({-limit-1,limit+1}) do
                local target=object(0,0,dz,'SolarPanel','d2')
                local slave=object(0,0,dz,'Inverter','d3')
                for _,check in ipairs({
                    function() return LiveWire.Install.checkLink(PLAYER,target,INVERTER) end,
                    function() return LiveWire.Install.checkCouple(PLAYER,slave,INVERTER) end}) do
                    local ok,why,actual,max=check()
                    assert(not ok and why=='Tooltip_LW_TooManyFloors')
                    assert(tonumber(actual)==limit+1 and tonumber(max)==limit)
                end
            end
        end
        ''')

    def test_horizontal_limit_and_wire_cost_still_apply(self):
        self.lua.execute('''
        local I=LiveWire.Install
        local ok,_,wires=I.checkLink(PLAYER,object(12,0,3,'SolarPanel','d2'),INVERTER)
        assert(ok and wires==3)
        local allowed,why=I.checkLink(PLAYER,object(13,0,2,'SolarPanel','d2'),INVERTER)
        assert(not allowed and why=='Tooltip_LW_TooFarForCable')
        SandboxVars={LiveWire={WirePerTiles=0}}
        local free,_,cost=I.checkLink(PLAYER,SOLAR,INVERTER)
        assert(free and cost==0)
        ''')

    def test_discovery_uses_current_floor_limit_and_keeps_world_bounds(self):
        self.lua.execute('''
        SQUARES={}
        local center=object(0,0,0,'Inverter','d1')
        object(12,0,3,'SolarPanel','d2')
        object(0,0,-3,'PowerBank','d3')
        object(0,0,4,'SolarPanel','d4')
        object(13,0,2,'SolarPanel','d5')
        object(0,0,2,nil,nil,'IsoGenerator')
        local I=LiveWire.Install
        assert(#I.objectsInRange(center:getSquare(),nil,true)==4)
        assert(#I.objectsInRange(center:getSquare(),'source',false)==1)
        assert(#I.invertersInRange(SOLAR:getSquare())==1)
        SandboxVars={LiveWire={LinkVerticalRange=1}}
        assert(#I.objectsInRange(center:getSquare(),nil,true)==1)
        assert(#I.invertersInRange(SOLAR:getSquare())==0)
        SandboxVars.LiveWire.LinkVerticalRange=10
        I.objectsInRange(object(0,0,31,'Inverter','high'):getSquare())
        I.objectsInRange(object(0,0,-32,'Inverter','low'):getSquare())
        ''')

    def test_action_rechecks_current_server_setting_before_consuming_wire(self):
        self.lua.execute('''
        ISBaseTimedAction={derive=function() return {} end}
        SafeHouse={isSafehouseAllowInteract=function() return true end}
        PLAYER.getX=function() return 0 end;PLAYER.getY=function() return 0 end
        PLAYER.getZ=function() return 2 end
        local R=LiveWire.Registry
        local inv=R.addDevice({id='d1',model='Inverter',role='inverter',x=0,y=0,z=0,state='off'})
        GRID=R.createGrid(inv)
        DEVICE=R.addDevice({id='d2',model='SolarPanel',role='source',x=0,y=0,z=2})
        INVERTER.mark.id=inv.id;SOLAR.mark.id=DEVICE.id
        CONSUMED=0
        LiveWire.Install.consume=function(_,_,n) CONSUMED=CONSUMED+n;return true end
        LiveWire.Maintenance.liveWork=function() return false end
        LiveWire.Devices.syncMark=function() end;LiveWire.Sim.refresh=function() end
        LiveWire.Xp.award=function() end;LiveWire.notify=function() end
        ''')
        self.lua.execute(Path(LUA, 'shared/LiveWire/TimedActions/LW_TimedActions.lua').read_text(encoding='ascii'))
        self.lua.execute('''
        local action={character=PLAYER,target=SOLAR,inverter=INVERTER}
        assert(LiveWire.Install.checkLink(PLAYER,SOLAR,INVERTER))
        SandboxVars={LiveWire={LinkVerticalRange=1}}
        assert(not LWLinkAction.complete(action) and CONSUMED==0 and DEVICE.grid==nil)
        SandboxVars.LiveWire.LinkVerticalRange=3
        assert(LWLinkAction.complete(action) and CONSUMED==1 and DEVICE.grid==GRID.id)
        ''')


if __name__ == '__main__':
    unittest.main()
