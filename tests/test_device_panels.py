"""Individual LCDs and focused wiring under Lua doubles, not in-game validation."""
from pathlib import Path
import unittest
import test_interface as interface_harness
from test_simulation import LUA


class DevicePanels(unittest.TestCase):
    def setUp(self):
        self.helper = interface_harness.Interface()
        self.helper.setUp()
        self.lua = self.helper.lua

    def load(self, name):
        # require() is not run here: the enclosure kit that the breaker window needs loads first.
        if name.endswith('LW_BreakerPanel.lua'):
            self.lua.execute(Path(LUA, 'client/LiveWire/LW_Enclosure.lua').read_text(encoding='ascii'))
        self.lua.execute(Path(LUA, name).read_text(encoding='ascii'))

    def world(self):
        self.lua.execute('''
        local R=LiveWire.Registry
        inv=R.addDevice({role='inverter',model='Inverter',x=0,y=0,z=0,state='on',cond=100})
        g=R.createGrid(inv);g.powered=true;g.name='Installation'
        function device(model)
            local def=LiveWire.Defs.devices[model]
            local d=R.addDevice({role=def.role,model=model,x=0,y=0,z=0,cond=73,state='ok'})
            R.link(d,g);return d
        end
        ''')

    def test_source_view_reads_existing_measurement_and_never_advances_physics(self):
        self.world()
        self.lua.execute('''
        LiveWire.Sim.stepGrid=function() error('read advanced physics') end
        LiveWire.Sim.sourceRaw=function() error('read recalculated production') end
        for _,model in ipairs({'SolarPanel','WindTurbine','WaterWheel'}) do
            local d=device(model);d.pOut=123.4;d.raw=210;d.dirt=0.2;d.snow=0.3
            for i=1,1000 do
                local s=LiveWire.DeviceView.snapshot(d)
                assert(s.w==123 and s.cond==73 and s.inverter==inv.id and s.name=='Installation')
                assert(s.nominal==LiveWire.Defs.devices[model].nominalW)
                s.cond=0;s.w=999 -- the detached view cannot mutate the registry
                assert(d.cond==73 and d.pOut==123.4 and d.raw==210)
            end
            d.cond=0;assert(LiveWire.DeviceView.snapshot(d).w==0)
            d.cond=73;d.brake=true;assert(LiveWire.DeviceView.snapshot(d).w==0)
            d.brake=false;LiveWire.Registry.unlink(d)
            local s=LiveWire.DeviceView.snapshot(d)
            assert(s.w==0 and s.inverter==nil and d.pOut==123.4)
        end
        assert(LiveWire.DeviceView.snapshot(inv)==nil)
        ''')

    def test_pump_view_uses_own_measured_flow_without_consuming_water(self):
        self.world()
        self.lua.execute('''
        local d=device('WaterPump');d.flowLph=150;d.pumped=9;d.state='running'
        local other=device('WaterPump');other.flowLph=300;other.pumped=12
        LiveWire.Pump.demandW=function() error('read consumed water counter') end
        LiveWire.Pump.step=function() error('read moved water') end
        for i=1,1000 do
            local s=LiveWire.DeviceView.snapshot(d)
            assert(s.flow==150 and s.w==125 and s.state=='running')
            assert(d.pumped==9 and other.pumped==12 and other.flowLph==300)
        end
        d.state='nobarrel';assert(LiveWire.DeviceView.snapshot(d).flow==0)
        d.state='nopower';assert(LiveWire.DeviceView.snapshot(d).w==0)
        d.state='running'
        for _,field in ipairs({'equipmentOff','mainOff'}) do
            g[field]=true
            local s=LiveWire.DeviceView.snapshot(d)
            assert(s.w==0 and s.flow==0 and s.state=='nopower')
            g[field]=false
        end
        for _,state in ipairs({'off','broken','tripped'}) do
            inv.state=state;assert(LiveWire.DeviceView.snapshot(d).flow==0)
        end
        inv.state='on';LiveWire.Registry.data.pumpsDisabled=true
        assert(LiveWire.DeviceView.snapshot(d).flow==0)
        LiveWire.Registry.data.pumpsDisabled=nil
        d.cond=0;assert(LiveWire.DeviceView.snapshot(d).state=='broken')
        d.cond=73;LiveWire.Registry.unlink(d)
        assert(LiveWire.DeviceView.snapshot(d).w==0)
        ''')

    def test_device_read_command_allows_ordinary_players_and_checks_target_and_rate(self):
        self.world()
        self.lua.execute('''
        NOW=0;getTimestampMs=function() return NOW end
        Events.OnClientCommand.Add=function(f) COMMAND=f end
        ''')

        self.load('server/LiveWire/LW_Commands.lua')
        self.lua.execute('''
        isServer=function() return true end
        local d=device('SolarPanel');d.pOut=100
        PX,SAFE,LOADED,FOUND,DEAD=0,true,true,true,false
        local player={getUsername=function() return 'ordinary' end,isDead=function() return DEAD end,
            getX=function() return PX end,getY=function() return 0 end,getZ=function() return 0 end}
        getCell=function() return {getGridSquare=function() return LOADED and {} end} end
        SafeHouse={isSafehouseAllowInteract=function() return SAFE end}
        LiveWire.Devices.find=function() return FOUND and {} end
        REPLIES={};sendServerCommand=function(who,module,cmd,args)
            assert(who==player and cmd==LiveWire.Protocol.S_DEVICE)
            REPLIES[#REPLIES+1]=args
        end
        local function read(id,seq,advance)
            if advance~=false then NOW=NOW+1001 end
            COMMAND(LiveWire.MODULE,LiveWire.Protocol.C_READ_DEVICE,player,{device=id or d.id,seq=seq or 1})
        end
        read();assert(#REPLIES==1 and REPLIES[1].w==100)
        PX=10;read();PX=0;SAFE=false;read();SAFE=true
        LOADED=false;read();LOADED=true;FOUND=false;read();FOUND=true
        DEAD=true;read();DEAD=false
        read('d999');read(inv.id);read(nil,-1);read(nil,1.5);read(nil,1000000001)
        LiveWire.Registry.readOnly=true;read();LiveWire.Registry.readOnly=false
        assert(#REPLIES==1)
        NOW=NOW+1001
        for i=1,5 do read(nil,i,false) end
        assert(#REPLIES==5) -- normal four-command per-second limiter
        ''')

    def test_alarm_view_follows_authoritative_alarm_flags_without_fictitious_production(self):
        self.world()
        self.lua.execute('''
        local d=device('BatteryAlarm');local V=LiveWire.DeviceView
        assert(V.snapshot(d).state=='ok' and V.snapshot(d).w==nil)
        g.alarmOn=true;assert(V.snapshot(d).state=='ringing')
        g.alarmAck=true;assert(V.snapshot(d).state=='ringing')
        d.cond=0;assert(V.snapshot(d).state=='broken')
        d.cond=73;LiveWire.Registry.unlink(d);assert(V.snapshot(d).state=='off')
        assert(g.alarmOn and g.alarmAck)
        ''')

    def client(self):
        self.helper.lcd_fixture()
        self.lua.execute('''
        isClient=function() return true end
        SENT={};LiveWire.Client.send=function(cmd,args) SENT[#SENT+1]={cmd=cmd,args=args} end
        ''')

    def test_device_replies_reject_old_wrong_closed_and_same_device_reopened_views(self):
        self.client()
        self.lua.execute('''
        local C,P=LiveWire.Client,LiveWire.Protocol
        local function reply(id,seq,w) RECEIVE(LiveWire.MODULE,P.S_DEVICE,{device=id,seq=seq,w=w}) end
        C.readDevice('d1');C.readDevice('d1')
        reply('d1',2,20);reply('d1',1,10);assert(C.deviceView.snapshot.w==20)
        C.readDevice('d2');reply('d1',2,99);assert(C.deviceView.snapshot==nil)
        reply('d2',3,30);assert(C.deviceView.snapshot.w==30)
        C.deviceView=nil;reply('d2',3,999);assert(C.deviceView==nil)
        C.readDevice('d2');reply('d2',3,999);assert(C.deviceView.snapshot==nil)
        reply('d2',4,40);assert(C.deviceView.snapshot.w==40)
        C.clearSession();reply('d2',4,999);assert(C.deviceView==nil)
        ''')

    def test_lcd_requests_only_every_two_seconds_and_stops_on_close_or_relink(self):
        self.client()
        self.load('client/LiveWire/LW_DevicePanel.lua')
        self.lua.execute('''
        ISPanel.update=function() end
        LiveWire.Equipment={accessible=function() return true end}
        getCell=function() error('LCD searched world') end
        local P=LiveWire.DevicePanel
        local p=ui(P,350);p.obj={mark={id='d1',model='SolarPanel',cond=73,inv='d9'}}
        p.player={};p.device='d1';p.linkedId='d9';p.lastRead=-2000;P.instance=p
        for i=1,10000 do NOW=i*10;p:update() end
        assert(#SENT==50)
        local request=SENT[#SENT].args
        RECEIVE(LiveWire.MODULE,LiveWire.Protocol.S_DEVICE,
            {device='d1',inverter='d9',seq=request.seq,cond=73,w=123,nominal=200,kind='hydro',state='on'})
        p:update();assert(p.data.w==123)
        p.obj.mark.inv='d10';p:update();assert(p.data==nil and #SENT==51)
        p:close();local before=#SENT
        for i=1,1000 do p:update();p:render();p:onButton({internal='links'});p:close() end
        assert(#SENT==before and P.instance==nil and p.obj==nil and LiveWire.Client.deviceView==nil)
        ''')

    def test_long_bank_and_device_lines_scroll_inside_the_screen(self):
        self.helper.lcd_fixture()
        self.load('client/LiveWire/LW_DevicePanel.lua')
        self.load('client/LiveWire/LW_BankPanel.lua')
        self.lua.execute('''
        getTextManager=function() return {getFontHeight=function() return 16 end,
            MeasureStringX=function(_,f,s) return #s*8 end} end
        local LONG=string.rep('x',200)
        local function firstX(P,setup)
            local xs={}
            local p=ui(P,350);p.L=LiveWire.UIScale.layout(1,P.BASE);p.L.fh=20
            setup(p)
            p.drawText=function(_,s,x) if s==LONG then xs[#xs+1]=x end end
            NOW=0;p:render();NOW=5000;p:render()
            return xs
        end
        local d=firstX(LiveWire.DevicePanel,function(p)
            p.obj={mark={id='d1',model='SolarPanel',cond=100}}
            p.lines=function() return {LONG} end end)
        assert(#d==2 and d[1]==28 and d[2]<28,'device line does not scroll')
        LiveWire.Marks.get=function(o) return o.mark end
        local b=firstX(LiveWire.BankPanel,function(p)
            p.obj={mark={id='b1',cond=100}};LiveWire.Client.equipmentCondition=function() return LONG end end)
        assert(#b==2 and b[1]==28 and b[2]<28,'bank line does not scroll')
        ''')

    def test_lcd_content_sources_pump_alarm_waiting_and_font_geometry(self):
        self.helper.lcd_fixture()
        self.load('client/LiveWire/LW_DevicePanel.lua')
        self.lua.execute('''
        local P=LiveWire.DevicePanel
        function P:new(x,y,w,h) return ui(self,h,w) end
        local player={getPlayerNum=function() return 0 end}
        for _,h in ipairs({16,26,38}) do
            FONT_H=h
            for _,model in ipairs({'SolarPanel','WindTurbine','WaterWheel','WaterPump','BatteryAlarm'}) do
                local def=LiveWire.Defs.devices[model]
                P.open(player,{mark={id='d1',model=model,cond=0}})
                local p=P.instance;p:render();contains(p,'IGUI_LW_Waiting:')
                contains(p,'IGUI_LW_EquipmentCondition:0')
                p.data={cond=73,kind=def.kind or def.role,w=123,nominal=200,flow=150,
                    dirt=0.2,snow=0.3,brake=true,state=def.role=='pump' and 'running' or 'on'}
                p.words={};p:render();contains(p,'IGUI_LW_EquipmentCondition:73')
                if def.role=='source' then contains(p,'IGUI_LW_DeviceProduction:123') end
                if def.role=='pump' then
                    contains(p,'IGUI_LW_DeviceDemand:123');contains(p,'IGUI_LW_DeviceFlow:150')
                end
                for i,line in ipairs(p:lines()) do
                    assert(56+(i-1)*(h+4)+h<p.height-70,'LCD row clipped')
                end
                p:close();p:render();p:update();assert(P.instance==nil)
            end
        end
        ''')

    def test_source_rows_marks_and_snapshot_fields_per_kind(self):
        self.helper.lcd_fixture()
        self.load('client/LiveWire/LW_DevicePanel.lua')
        self.lua.execute('''
        local P=LiveWire.DevicePanel
        local function rows(kind,extra)
            local s={cond=73,kind=kind,w=1,nominal=2,state='on'}
            for k,v in pairs(extra) do s[k]=v end
            local p={obj={mark={id='d1'}},data=s}
            return table.concat(P.lines(p),'|')
        end
        local solar=rows('solar',{dirt=0.2,snow=0.3})
        assert(string.find(solar,'IGUI_LW_DeviceDirt:20|IGUI_LW_DeviceSnow:30',1,true))
        assert(not string.find(solar,'Brak',1,true) and not string.find(solar,'Released',1,true))
        assert(string.find(rows('wind',{brake=true}),'IGUI_LW_DeviceBraked:',1,true))
        assert(string.find(rows('wind',{brake=false}),'IGUI_LW_DeviceReleased:',1,true))
        local hydro=rows('hydro',{dirt=0.2,snow=0.3,brake=true})
        assert(not string.find(hydro,'Dirt',1,true) and not string.find(hydro,'Snow',1,true)
            and not string.find(hydro,'Brak',1,true))
        ''')

    def test_source_marks_and_grid_snapshot_follow_the_kind(self):
        self.lua.execute('''
        local R,D=LiveWire.Registry,LiveWire.Defs
        local inv=R.addDevice({role='inverter',model='Inverter',x=0,y=0,z=0,state='on',cond=100})
        local g=R.createGrid(inv)
        local obj={}
        LiveWire.Marks.findOnSquare=function() return obj end
        LiveWire.Marks.get=function(o) return o.mark end
        LiveWire.Marks.set=function(o,m) o.mark=m end
        getCell=function() return {getGridSquare=function() return {} end} end
        local function markOf(model,fields)
            local def=D.devices[model]
            local d=R.addDevice({role=def.role,model=model,x=0,y=0,z=0,cond=73,state='ok'})
            R.link(d,g)
            for k,v in pairs(fields) do d[k]=v end
            local real=D.modelOfObject
            D.modelOfObject=function() return model end
            obj.getSprite=function() return {getName=function() return D.SHEET..'_'..tostring(def.tile) end} end
            obj.mark=nil
            LiveWire.Devices.syncMark(d)
            D.modelOfObject=real
            return obj.mark,d
        end
        local m=markOf('SolarPanel',{dirt=0.2,snow=0.3})
        assert(m.dirt==0.2 and m.snow==0.3 and not m.br)
        m=markOf('WindTurbine',{brake=true})
        assert(m.br==true and m.dirt==nil and m.snow==nil)
        m=markOf('WindTurbine',{})
        assert(m.br==false)
        m=markOf('WaterWheel',{})
        assert(not m.br and m.dirt==nil and m.snow==nil)
        local _,solar=markOf('SolarPanel',{dirt=0.2,snow=0.3})
        local snap=LiveWire.Sim.snapshot(g)
        local byModel={}
        for _,s in ipairs(snap.sources) do byModel[s.model]=s end
        assert(byModel.SolarPanel.dirt==0.2 and byModel.SolarPanel.snow==0.3)
        assert(byModel.WindTurbine.facing==0 and byModel.WaterWheel.facing==0)
        ''')

    def wiring(self):
        self.helper.lcd_fixture()
        self.load('client/LiveWire/LW_ConnectionPanel.lua')
        self.lua.execute('''
        local P=LiveWire.ConnectionPanel
        function object(id,model,x)
            local sq={getX=function() return x end,getY=function() return 0 end,getZ=function() return 0 end}
            return {mark={id=id,model=model,cond=73},getSquare=function() return sq end,
                getObjectIndex=function() return 1 end}
        end
        a=object('d1','SolarPanel',1);b=object('d2','WindTurbine',2)
        inv1=object('d9','Inverter',0);inv2=object('d10','Inverter',3)
        SCANS,LINKS,UNLINKS=0,0,0;CAN=true;SAFE=true
        LiveWire.Install.invertersInRange=function() return {{obj=inv1},{obj=inv2}} end
        LiveWire.Install.objectsInRange=function() SCANS=SCANS+1;return {{obj=a,dist=1},{obj=b,dist=2}} end
        LiveWire.Install.checkLink=function() return CAN end
        SafeHouse={isSafehouseAllowInteract=function() return SAFE end}
        LiveWire.Menu={onLink=function(_,target,inv) LINKS=LINKS+1;TARGET=target;INVERTER=inv end,
            onUnlinkAt=function(_,target,id) UNLINKS=UNLINKS+1;TARGET=target;DEVICE=id end}
        function P:new(x,y,w,h)
            local p=ui(self,h)
            p.network={selected=1,clear=function() end,addOption=function() end}
            p.list={items={},selected=1,clear=function(s) s.items={} end,
                addItem=function(s,text,item) s.items[#s.items+1]={text=text,item=item} end}
            p.connect={setEnable=function(s,v) s.enable=v end}
            p.disconnect={setEnable=function(s,v) s.enable=v end}
            return p
        end
        player={getPlayerNum=function() return 0 end}
        ''')

    def test_focused_wiring_selects_inverter_for_only_origin_global_lists_all(self):
        self.wiring()
        self.lua.execute('''
        local P=LiveWire.ConnectionPanel
        P.open(player,a);local p=P.instance
        assert(p.deviceOnly and #p.list.items==1 and p:selection().obj==a and SCANS==0)
        p.network.selected=2;p:onNetwork();p:onButton({internal='connect'})
        assert(LINKS==1 and TARGET==a and INVERTER==inv2)
        a.mark.inv='d10';p:onButton({internal='disconnect'})
        assert(UNLINKS==1 and TARGET==a and DEVICE=='d1')
        p.network.selected=1;p:onNetwork();p:onButton({internal='disconnect'})
        assert(UNLINKS==1) -- cannot disconnect a different network implicitly
        a.mark.inv=nil;CAN=false;p:onButton({internal='connect'});assert(LINKS==1)
        CAN=true;SAFE=false;p:onButton({internal='connect'});assert(LINKS==1);SAFE=true
        P.open(player,inv1);p=P.instance
        assert(not p.deviceOnly and #p.list.items==2 and SCANS==1)
        p.list.selected=2;p:onButton({internal='connect'})
        assert(LINKS==2 and TARGET==b and INVERTER==inv1)
        LiveWire.Install.invertersInRange=function() return {} end
        P.open(player,a);p=P.instance
        assert(p.deviceOnly and #p.list.items==1 and p:selection().obj==a)
        assert(p:selection().dist==nil and SCANS==1)
        p:onButton({internal='connect'});assert(LINKS==2)
        ''')

    def test_all_equipment_buttons_keep_origin_and_inverter_keeps_global_origin(self):
        self.helper.lcd_fixture()
        for name in ('LW_DevicePanel','LW_BankPanel','LW_BreakerPanel','LW_InverterPanel'):
            self.load('client/LiveWire/'+name+'.lua')
        self.lua.execute('''
        LiveWire.Equipment={accessible=function() return true end}
        local object={}
        local count=0
        LiveWire.ConnectionPanel={open=function(player,obj) assert(obj==object);count=count+1 end}
        for _,P in ipairs({LiveWire.DevicePanel,LiveWire.BankPanel,LiveWire.BreakerPanel}) do
            local p={obj=object,player={}};P.onButton(p,{internal='links'})
        end
        LiveWire.InverterPanel.onButton({obj=object,player={}},{internal='LINKS'})
        assert(count==4)
        ''')


    def test_inverter_screen_takes_the_shared_palette_lit_or_off(self):
        self.helper.lcd_fixture()
        self.load('client/LiveWire/LW_InverterPanel.lua')
        self.lua.execute('''
        local P,Pal=LiveWire.InverterPanel,LiveWire.Lcd.PALETTE
        local p=ui(P,300);p.L=LiveWire.UIScale.layout(1,P.BASE);p.page=1
        p.powerBtn={getX=function() return 200 end,getY=function() return 200 end}
        p.brandKey=function() return 'IGUI_LW_LCD_Brand' end
        local snap={name='Home',production=2,demand=150,sources={},inverter={maxW=1500,state='on'}}
        p.snapshot=function() return snap end
        local function colours()
            local c={}
            p.drawRect=function(_,x,y,w,h,a,r,g,b) c[x..','..y]={r,g,b} end
            p:render();return c
        end
        local L=p.L
        local function same(a,b) return a[1]==b[1] and a[2]==b[2] and a[3]==b[3] end
        local c=colours()
        assert(same(c[(L.lcdX-L.bezel)..','..(L.lcdY-L.bezel)],Pal.green.bezel),'bezel')
        assert(same(c[L.lcdX..','..L.lcdY],Pal.green.screen),'lit screen')
        snap.inverter.state='off';c=colours()
        assert(same(c[L.lcdX..','..L.lcdY],Pal.off.screen),'dark screen')
        ''')

    def test_inverter_lcd_shows_public_grid_only_when_usable(self):
        self.helper.lcd_fixture()
        self.load('client/LiveWire/LW_InverterPanel.lua')
        self.lua.execute('''
        local P=LiveWire.InverterPanel
        local function page(n,snap)
            snap.name='';snap.production=2;snap.demand=150;snap.sources={}
            snap.inverter={maxW=1500}
            local lines=P.pageContent({page=n},snap)
            return table.concat(lines,'|')
        end
        local balance=page(1,{gridW=186})
        assert(balance:find('IGUI_LW_LCD_Mains:186',1,true), balance)
        assert(not page(1,{gridW=0}):find('Mains',1,true), 'no mains line without draw')
        assert(page(3,{gridW=0}):find('IGUI_LW_LCD_Grid:0',1,true), 'grid line at 0 W after the shutoff')
        local none=page(3,{})
        assert(not none:find('LCD_Grid',1,true) and not page(1,{}):find('Mains',1,true),
            'no grid line when the inverter cannot use the grid')
        ''')


if __name__ == '__main__':
    unittest.main()
