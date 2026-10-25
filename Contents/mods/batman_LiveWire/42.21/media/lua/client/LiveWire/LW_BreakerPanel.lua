-- Live Wire: compact DIN enclosure, native switch handles and authoritative state.
if isServer() then return end
require "ISUI/ISPanel"
require "ISUI/ISButton"
LiveWire = LiveWire or {}
local Panel = ISPanel:derive("LiveWireBreakerPanel")
LiveWire.BreakerPanel = Panel
local W,H=750,454
local C={white={0.87,0.87,0.82},light={0.96,0.95,0.90},edge={0.48,0.51,0.50},
    shadow={0.26,0.29,0.29},ink={0.14,0.19,0.20},rail={0.49,0.54,0.54},
    handle={0.25,0.29,0.31},orange={0.93,0.51,0.13},green={0.29,0.59,0.36},
    red={0.74,0.25,0.20},glass={0.30,0.43,0.46},lcd={0.49,0.61,0.35},
    brandRed={0.94,0.20,0.25},brandBlack={0.03,0.03,0.03},brandWhite={1,1,1}}
local function rect(ui,x,y,w,h,c,a) ui:drawRect(x,y,w,h,a or 1,c[1],c[2],c[3]) end
local function border(ui,x,y,w,h,c) ui:drawRectBorder(x,y,w,h,1,c[1],c[2],c[3]) end
local function text(ui,s,x,y,w,c,font)
    font=font or UIFont.Small
    ui:setStencilRect(x,y,w,getTextManager():getFontHeight(font)+3)
    ui:drawText(s,x,y,c[1],c[2],c[3],1,font)
    ui:clearStencilRect()
end
local function screw(ui,x,y)
    rect(ui,x+2,y,8,12,C.edge);rect(ui,x,y+2,12,8,C.edge)
    rect(ui,x+2,y+5,8,2,C.ink)
end
-- Work only from the detached snapshot, once per received revision. Use the
-- aggregate breakdown, never the consumer list (limited to 200 display rows).
function Panel.readings(snap)
    local r={pending=true}
    local b=snap and snap.breaker
    if not b then return r end
    local mainOff=b.mainOff or b.state=="tripped"
    r.lightsOff=mainOff or b.lightsOff
    r.equipmentOff=mainOff or b.equipmentOff
    local supplied=snap.inverter and snap.inverter.powered and not mainOff
    if r.lightsOff or not supplied then r.lights=0 end
    if r.equipmentOff or not supplied then r.equipment=0 end
    if snap.demandReady==true and supplied then
        local lights,equipment=0,0
        for _,v in ipairs(snap.appliances or {}) do
            if v.cat=="light" then lights=lights+v.w else equipment=equipment+v.w end
        end
        equipment=equipment+(snap.pumps and snap.pumps.w or 0)
        -- In overlapping networks this anchor can supply appliances assigned to
        -- another panel. Preserve its measured watts instead of hiding them.
        r.lights=math.floor(lights+0.5)
        r.equipment=math.floor(equipment+0.5)
    end
    if r.lights~=nil and r.equipment~=nil then
        r.total=r.lights+r.equipment
        r.pending=false
    end
    return r
end
function Panel.open(player,obj)
    local m=LiveWire.Marks.get(obj)
    if not m then return end
    if Panel.instance then Panel.instance:close() end
    local p=Panel:new(getPlayerScreenLeft(player:getPlayerNum())+100,
        getPlayerScreenTop(player:getPlayerNum())+90,W,H)
    p.player,p.obj,p.device,p.inverterId=player,obj,m.id,m.inv
    LiveWire.Client.discardSnapshot(m.inv)
    p.reading=Panel.readings(nil)
    p.moveWithMouse,p.lastSubscribe=true,0
    p.backgroundColor={r=0.11,g=0.15,b=0.17,a=0.99}
    p:initialise();p:addToUIManager();Panel.instance=p
end
-- Two tied pole handles belong to one circuit. Only this UI instance draws them.
local function lever(button)
    local color=button.main and C.orange or C.handle
    local width=button.width
    local thumbY=button.off and 45 or 17
    local poles=button.main and 1 or 2
    local poleWidth=width/poles
    for i=0,poles-1 do
        local x=i*poleWidth
        rect(button,x+15,6,poleWidth-30,70,C.ink)
        border(button,x+15,6,poleWidth-30,70,C.shadow)
    end
    rect(button,5,thumbY+4,width-10,31,C.shadow)
    rect(button,3,thumbY,width-6,29,color)
    rect(button,3,thumbY,width-6,3,button.main and C.orange or C.edge)
    for i=1,3 do rect(button,9,thumbY+17+i*3,width-18,1,C.ink,0.5) end
    text(button,button.off and "O" or "I",width/2-4,thumbY+1,16,C.light,UIFont.Small)
    if not button.enable then rect(button,3,thumbY,width-6,29,C.white,0.25) end
    if button:isMouseOver() and button.enable then border(button,1,thumbY-2,width-2,33,C.orange) end
end
function Panel:createChildren()
    ISPanel.createChildren(self)
    local function control(x,w,action,main)
        local b=ISButton:new(x,201,w,88,"",self,Panel.onButton)
        b.internal,b.main,b.displayBackground=action,main,false
        b:initialise();b:instantiate();b.render=lever
        self:addChild(b)
        return b
    end
    self.lightButton=control(320,108,"lights",false)
    self.lightButton.tooltip=getText("IGUI_LW_CircuitLights")
    self.equipmentButton=control(454,108,"equipment",false)
    self.equipmentButton.tooltip=getText("IGUI_LW_CircuitEquipment")
    self.mainButton=control(603,74,"main",true)
    self.mainButton.tooltip=getText("IGUI_LW_BoardMain")
    local close=ISButton:new(W-36,12,22,22,"x",self,Panel.onButton)
    close.internal="close";close:initialise();close:instantiate();self:addChild(close)
    local links=ISButton:new(49,H-50,W-98,28,getText("IGUI_LW_Connections"),self,Panel.onButton)
    links.internal="links";links:initialise();links:instantiate();self:addChild(links)
end
function Panel:onButton(b)
    if self.closed then return end
    if b.internal=="close" then self:close();return end
    if b.internal=="links" then
        if LiveWire.Equipment.accessible(self.player,self.obj,3.5) then
            LiveWire.ConnectionPanel.open(self.player,self.obj)
        end
        return
    end
    local snap=LiveWire.Client.snapshot(self.inverterId)
    local breaker=snap and snap.breaker
    if not breaker then return end
    if b.internal=="main" then
        if breaker.state=="tripped" then
            LiveWire.Client.send(LiveWire.Protocol.C_RESET_BREAKER,{device=self.device})
        else
            LiveWire.Client.send(LiveWire.Protocol.C_SET_CIRCUIT,
                {device=self.device,circuit="main",off=not breaker.mainOff})
        end
    elseif b.internal=="lights" or b.internal=="equipment" then
        LiveWire.Client.send(LiveWire.Protocol.C_SET_CIRCUIT,
            {device=self.device,circuit=b.internal,
                off=not (b.internal=="lights" and breaker.lightsOff or b.internal=="equipment" and breaker.equipmentOff)})
    end
end
function Panel:update()
    if self.closed then return end
    ISPanel.update(self)
    local sq=self.obj:getSquare()
    if not sq or self.obj:getObjectIndex()==-1 or self.player:isDead()
        or math.abs(self.player:getX()-sq:getX())>4 or math.abs(self.player:getY()-sq:getY())>4
        or math.floor(self.player:getZ())~=sq:getZ() then self:close();return end
    local now=getTimestampMs()
    local mark=LiveWire.Marks.get(self.obj)
    local inv=mark and mark.inv
    if self.inverterId~=inv then
        LiveWire.Client.discardSnapshot(inv)
        self.inverterId,self.lastSubscribe=inv,0
    end
    if self.inverterId and (self.lastSubscribe==0 or now-self.lastSubscribe>60000) then
        self.lastSubscribe=now
        LiveWire.Client.send(LiveWire.Protocol.C_SUBSCRIBE,{inverter=self.inverterId})
    end
    local snap=LiveWire.Client.snapshot(self.inverterId)
    if snap~=self.viewSnapshot then
        self.viewSnapshot,self.reading=snap,Panel.readings(snap)
    end
    local b=snap and snap.breaker
    self.lightButton:setEnable(b~=nil);self.mainButton:setEnable(b~=nil)
    self.lightButton.off=b and b.lightsOff or false
    self.equipmentButton:setEnable(b~=nil)
    self.equipmentButton.off=b and b.equipmentOff or false
    self.mainButton.off=b and (b.mainOff or b.state=="tripped") or false
end
function Panel:prerender()
    if self.closed then return end
    ISPanel.prerender(self)
    border(self,1,1,W-2,H-2,C.edge)
    text(self,"LIVE WIRE",19,11,150,C.white,UIFont.Medium)
    text(self,getText("IGUI_LW_BoardTitle"),181,16,W-230,C.white)
    -- Moulded enclosure with an open smoke-tinted lid, hinges and a latch.
    rect(self,10,46,W-20,H-56,C.shadow)
    rect(self,14,42,W-28,H-60,C.white)
    border(self,14,42,W-28,H-60,C.edge)
    rect(self,25,53,W-50,65,C.glass,0.82)
    border(self,25,53,W-50,65,C.ink)
    rect(self,31,57,W-62,7,C.light,0.25)
    rect(self,36,66,W-72,2,C.light,0.15)
    rect(self,W/2-34,48,68,13,C.edge)
    rect(self,W/2-29,49,58,6,C.white)
    for _,x in ipairs({31,W-43}) do
        rect(self,x,94,12,36,C.ink);rect(self,x+3,96,6,29,C.edge)
    end
    -- Printed manufacturer plate: red lettering and black detail on white.
    rect(self,W-204,76,166,30,C.brandWhite)
    border(self,W-204,76,166,30,C.brandBlack)
    rect(self,W-196,83,4,16,C.brandBlack)
    text(self,getText("IGUI_LW_BoardBrand"),W-182,77,136,C.brandRed,UIFont.Medium)
    -- Recess and galvanized rail; the components sit in front of it.
    rect(self,37,135,W-74,202,C.shadow)
    rect(self,42,140,W-84,191,C.edge)
    rect(self,43,225,W-86,26,C.rail)
    border(self,43,225,W-86,26,C.light)
    local snap=self.viewSnapshot
    local b=snap and snap.breaker
    -- A three-line wattmeter LCD, not a mechanical cumulative kWh counter.
    rect(self,51,151,246,176,C.ink)
    rect(self,55,155,238,168,C.white)
    border(self,58,158,232,162,C.edge)
    text(self,getText("IGUI_LW_BoardPowerTitle"),68,167,210,C.ink)
    rect(self,64,189,222,86,C.ink)
    rect(self,67,192,216,80,C.lcd)
    rect(self,69,194,212,2,C.light,0.16)
    local r=self.reading
    local fh=getTextManager():getFontHeight(UIFont.Small)
    local lineH=math.floor(76/3)
    local function row(key,value,off,index)
        local y=194+(index-1)*lineH+math.max(0,math.floor((lineH-fh)/2))
        local s=value==nil and "-- W" or off and value==0 and getText("IGUI_LW_BoardCutWatts")
            or tostring(value).." W"
        text(self,getText(key),73,y,109,C.ink)
        self:setStencilRect(183,y,95,fh+3)
        self:drawTextRight(s,278,y,C.ink[1],C.ink[2],C.ink[3],1,UIFont.Small)
        self:clearStencilRect()
        if index==2 then rect(self,73,y+lineH-1,204,1,C.ink,0.25) end
    end
    row("IGUI_LW_CircuitLightsLabel",r.lights,r.lightsOff,1)
    row("IGUI_LW_CircuitEquipment",r.equipment,r.equipmentOff,2)
    row("IGUI_LW_BoardPowerTotal",r.total,false,3)
    rect(self,72,286,9,5,snap and snap.inverter.powered and C.green or C.red)
    text(self,snap and snap.name~="" and snap.name or getText("IGUI_LW_Network"),89,280,188,C.ink)
    local status=b and getText("IGUI_LW_State_"..b.state)
        or getText(self.inverterId and "IGUI_LW_Waiting" or "IGUI_LW_BankIndependent")
    if b and b.mainOff then status=getText("IGUI_LW_CircuitOff")
    elseif b and b.state=="ok" and snap and not snap.inverter.powered then
        status=getText("IGUI_LW_State_"..(snap.inverter.state=="off" and "off" or "idle"))
    elseif b and r.pending then status=getText("IGUI_LW_BoardPowerUpdating")
    end
    text(self,status,72,301,206,C.ink)
    -- Own physical mark remains available when unlinked or broken.
    local own=LiveWire.Marks.get(self.obj)
    rect(self,55,338,238,29,C.ink)
    rect(self,58,341,232,23,C.lcd)
    text(self,LiveWire.Client.equipmentCondition(own and own.cond),64,342,220,C.ink)
    -- Standard narrow modular bodies, paired poles and exposed terminal screw heads.
    local function module(x,width,number,main)
        rect(self,x+2,154,width,163,C.shadow)
        rect(self,x,150,width,163,C.light)
        border(self,x,150,width,163,C.edge)
        local count=main and 1 or 2
        local unit=width/count
        for pole=0,count-1 do
            local px=x+pole*unit
            if pole>0 then rect(self,px,151,1,161,C.edge) end
            rect(self,px+9,157,unit-18,4,main and C.orange or C.glass)
            text(self,number,px+8,170,unit-12,C.ink)
            screw(self,px+unit/2-6,185)
            screw(self,px+unit/2-6,295)
            text(self,"I",px+7,207,16,C.ink)
            text(self,"O",px+7,274,16,C.ink)
        end
    end
    module(318,112,"01",false)
    module(452,112,"02",false)
    module(597,86,"03",true)
    -- Printed circuit strips under the rail, as on a domestic enclosure.
    local function strip(x,w,key)
        rect(self,x,338,w,23,C.light);border(self,x,338,w,23,C.edge)
        text(self,getText(key),x+5,340,w-10,C.ink)
    end
    strip(318,112,"IGUI_LW_CircuitLightsLabel")
    strip(452,112,"IGUI_LW_CircuitEquipment")
    strip(590,100,"IGUI_LW_BoardMain")
    text(self,getText(b and b.equipmentOff and "IGUI_LW_CircuitOff" or "IGUI_LW_CircuitOn"),452,365,124,C.shadow)
    local hint=b and b.state=="tripped" and "IGUI_LW_BoardResetHint" or "IGUI_LW_BoardHint"
    text(self,getText(hint),49,381,W-98,C.ink)
    screw(self,24,350);screw(self,W-36,350)
    rect(self,W/2-30,371,60,8,C.edge)
end
function Panel:close()
    if self.closed then return end
    -- UIManager defers removal: stop callbacks and hide before releasing data.
    self.closed=true
    self:setVisible(false)
    self:removeFromUIManager()
    self.obj,self.player,self.viewSnapshot,self.reading=nil,nil,nil,nil
    if Panel.instance==self then Panel.instance=nil end
end
