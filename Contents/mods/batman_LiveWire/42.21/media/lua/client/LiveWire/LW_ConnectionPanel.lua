-- Live Wire: one wiring list. World discovery is explicit, never per-frame.
if isServer() then return end
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISComboBox"
require "ISUI/ISScrollingListBox"
require "LiveWire/LW_Stack"
require "LiveWire/LW_UIScale"
require "LiveWire/LW_UIKit"
LiveWire = LiveWire or {}
local Panel=ISPanel:derive("LiveWireConnectionPanel")
LiveWire.ConnectionPanel=Panel
LiveWire.UIKit.singleton("ConnectionPanel",Panel)
-- Sizes at the 1080p reference font, scaled once per window (LW_UIScale.lua).
local BASE={w=700,h=480,side=16,btnY=434,btnH=28,comboY=65,listY=125,listH=245,itemH=38,
    connectW=150,disX=174,refreshX=332,refreshW=126,inspectX=466,inspectW=126,closeX=600,closeW=84,
    titleY=12,originY=41,listTitleY=102,reasonY=380,reasonH=45,rowX=8,rowY=2,statusY=19}
Panel.BASE=BASE
-- Unscaled layout until a window is opened (instances made without open()).
Panel.L=LiveWire.UIScale.layout(1,BASE)
-- The window closes when the player leaves the square of its object: 2 link ranges
-- plus CLOSE_MARGIN horizontally, CLOSE_FLOORS floors vertically.
local CLOSE_MARGIN,CLOSE_FLOORS=4,2
local function mark(obj)
    return LiveWire.Marks.get(obj) or LiveWire.Install.vanillaMark(obj)
end
local function linked(obj)
    local m=mark(obj);return m and (m.inv or m.inverter)
end
local function name(obj)
    local m=LiveWire.Marks.get(obj)
    if m then
        local label=getText("IGUI_LW_Model_"..m.model)
        if m.model=="PowerBank" then
            local index,total=LiveWire.Stack.position(obj)
            if total>1 then label=label.." - "..getText("IGUI_LW_BankPosition",index,total) end
        end
        return label
    end
    return getText(LiveWire.Install.linkKind(obj)=="backup"
        and "IGUI_LW_Model_BackupGenerator" or "IGUI_LW_Model_ManagementComputer")
end
local function live(obj) return obj and obj:getSquare() and obj:getObjectIndex()~=-1 end
local function button(self,x,w,key,action)
    return LiveWire.UIKit.button(self,x,self.L.btnY,w,self.L.btnH,getText(key),Panel.onButton,action)
end
function Panel.open(player,obj)
    Panel.closeInstance()
    local UI=LiveWire.UIScale
    local L=UI.layout(UI.factor(BASE.w,BASE.h),BASE)
    local x,y,w,h=UI.fit(getPlayerScreenLeft(player:getPlayerNum())+90,
        getPlayerScreenTop(player:getPlayerNum())+80,L.w,L.h)
    local p=Panel:new(x,y,w,h)
    p.L=L
    p.player,p.obj,p.moveWithMouse=player,obj,true
    local own=LiveWire.Marks.get(obj)
    local def=own and LiveWire.Defs.devices[own.model]
    p.deviceOnly=def and def.role~="inverter" or false
    p.backgroundColor={r=0.12,g=0.16,b=0.18,a=0.98}
    p:initialise();p:addToUIManager();Panel.instance=p;p:refreshInverters()
end
function Panel:createChildren()
    ISPanel.createChildren(self)
    local L,W=self.L,self.width
    self.network=ISComboBox:new(L.side,L.comboY,W-2*L.side,L.btnH,self,Panel.onNetwork)
    self.network:initialise();self:addChild(self.network)
    self.list=ISScrollingListBox:new(L.side,L.listY,W-2*L.side,L.listH)
    self.list:initialise();self.list:instantiate()
    -- Two text lines per row, at the real font height.
    local fh=getTextManager():getFontHeight(UIFont.Small)
    self.rowStatusY=math.max(L.statusY,fh)
    self.list.itemheight=math.max(L.itemH,self.rowStatusY+fh)
    self.list.owner=self;self.list.doDrawItem=Panel.drawItem
    self:addChild(self.list)
    self.connect=button(self,L.side,L.connectW,"IGUI_LW_Connect","connect")
    self.disconnect=button(self,L.disX,L.connectW,"IGUI_LW_Disconnect","disconnect")
    button(self,L.refreshX,L.refreshW,"IGUI_LW_Refresh","refresh")
    button(self,L.inspectX,L.inspectW,"ContextMenu_LW_Inspect","inspect")
    button(self,L.closeX,L.closeW,"IGUI_LW_Close","close")
end
function Panel:refreshInverters()
    if self.closed then return end
    self.originName=name(self.obj)
    local old=self.inverter and LiveWire.Marks.get(self.inverter)
    local own=LiveWire.Marks.get(self.obj)
    local wanted=old and old.id or own and (own.cpl or own.inv or own.id)
    self.inverters={};self.network:clear()
    self.network.selected=1
    local around=LiveWire.Install.invertersInRange(self.obj:getSquare())
    for _,e in ipairs(around) do
        local m=LiveWire.Marks.get(e.obj)
        if m and not m.cpl then
            self.inverters[#self.inverters+1]=e.obj
            local sq=e.obj:getSquare()
            self.network:addOption((m.nm and m.nm~="" and m.nm or name(e.obj))
                .." ["..sq:getX()..", "..sq:getY()..", "..sq:getZ().."]")
            if m.id==wanted then self.network.selected=#self.inverters end
        end
    end
    if #self.inverters==0 then self.network:addOption(getText("IGUI_LW_NoNetwork")) end
    self.network.selected=math.max(1,math.min(self.network.selected,#self.inverters))
    self:onNetwork()
end
function Panel:onNetwork()
    if self.closed then return end
    self.inverter=self.inverters[self.network.selected]
    self.list:clear()
    if self.deviceOnly then
        local dist
        if live(self.inverter) then
            local a,b=self.obj:getSquare(),self.inverter:getSquare()
            dist=LiveWire.Install.distance(a:getX(),a:getY(),a:getZ(),b:getX(),b:getY(),b:getZ())
        end
        self.list:addItem(name(self.obj),{obj=self.obj,dist=dist})
        self.list.selected=1;self.lastCheck=nil
        return
    end
    if not live(self.inverter) then return end
    for _,e in ipairs(LiveWire.Install.objectsInRange(self.inverter:getSquare(),nil,true)) do
        local m=LiveWire.Marks.get(e.obj)
        local d=m and LiveWire.Defs.devices[m.model]
        if not d or d.role~="inverter" then
            local sq=e.obj:getSquare()
            self.list:addItem(name(e.obj).." ["..sq:getX()..", "..sq:getY()..", "..sq:getZ().."]",e)
            if e.obj==self.obj then self.list.selected=#self.list.items end
        end
    end
    self.lastCheck=nil
end
function Panel:selection()
    local row=self.list.items[self.list.selected]
    return row and row.item
end
function Panel:checkSelection()
    local e=self:selection()
    local valid=e and live(e.obj) and live(self.inverter)
    local id=valid and LiveWire.Marks.get(self.inverter).id
    local current=valid and linked(e.obj)
    local ok,why,a,b=false,nil,nil,nil
    if valid and not current then ok,why,a,b=LiveWire.Install.checkLink(self.player,e.obj,self.inverter) end
    if valid and SafeHouse and (not SafeHouse.isSafehouseAllowInteract(e.obj:getSquare(),self.player)
        or not SafeHouse.isSafehouseAllowInteract(self.inverter:getSquare(),self.player)) then
        valid,ok,why=false,false,"Tooltip_LW_Safehouse"
    end
    self.connect:setEnable(valid and not current and ok or false)
    self.disconnect:setEnable(valid and current==id or false)
    self.reason=why and LiveWire.Client.text(why,{a,b}) or getText("IGUI_LW_WiringHint")
    if current and current~=id then self.reason=getText("IGUI_LW_OtherNetwork") end
    self.connect.tooltip=self.reason
end
function Panel:onButton(b)
    if self.closed then return end
    if b.internal=="close" then self:close();return end
    if not live(self.obj) then self:close();return end
    if b.internal=="refresh" then self:refreshInverters();return end
    if b.internal=="inspect" then LiveWire.Menu.onInspect(self.player,self.obj);return end
    self:checkSelection()
    local e=self:selection()
    if not e then return end
    if b.internal=="connect" and self.connect.enable then
        LiveWire.Menu.onLink(self.player,e.obj,self.inverter)
    elseif b.internal=="disconnect" and self.disconnect.enable then
        local m=mark(e.obj);LiveWire.Menu.onUnlinkAt(self.player,e.obj,m.id)
    end
    self.lastCheck=nil
end
function Panel:update()
    if self.closed then return end
    ISPanel.update(self)
    local sq=self.obj and self.obj:getSquare()
    local range=2*LiveWire.Config.get("LinkRange")+CLOSE_MARGIN
    if not live(self.obj) or self.player:isDead()
        or math.abs(self.player:getX()-sq:getX())>range
        or math.abs(self.player:getY()-sq:getY())>range
        or math.abs(math.floor(self.player:getZ())-sq:getZ())>CLOSE_FLOORS then self:close();return end
    local now=getTimestampMs()
    local selected=self.list.selected
    if not self.lastCheck or now-self.lastCheck>=1000 or selected~=self.lastSelected then
        self.lastCheck,self.lastSelected=now,selected;self:checkSelection()
        local own=LiveWire.Marks.get(self.obj)
        self.originCondition=own and LiveWire.Client.equipmentCondition(own.cond) or nil
        for _,row in ipairs(self.list.items) do
            local e=row.item
            local current=live(e.obj) and linked(e.obj)
            local id=live(self.inverter) and LiveWire.Marks.get(self.inverter).id
            row.status=getText(current and (current==id and "IGUI_LW_BankLinked" or "IGUI_LW_OtherNetwork")
                or "IGUI_LW_BankIndependent")
            local m=live(e.obj) and LiveWire.Marks.get(e.obj)
            if m then row.status=row.status.."  -  "..LiveWire.Client.equipmentCondition(m.cond) end
        end
    end
end
function Panel.drawItem(list,y,row,alt)
    local self=list.owner
    local L=self.L
    if list.selected==row.index then list:drawRect(0,y,list.width,row.height,0.85,0.24,0.38,0.42) end
    list:drawText(row.text,L.rowX,y+L.rowY,0.9,0.93,0.93,1,UIFont.Small)
    local e=row.item
    local distance=e.dist and "  -  "..getText("IGUI_LW_WireDistance",
        math.floor(e.dist+0.5),LiveWire.Install.wiresFor(e.dist)) or ""
    list:drawText((row.status or "")..distance,L.rowX,y+(self.rowStatusY or L.statusY),0.65,0.76,0.76,1,UIFont.Small)
    return y+row.height
end
function Panel:render()
    if self.closed then return end
    ISPanel.render(self)
    local L=self.L
    self:drawText(getText("IGUI_LW_Connections"),L.side,L.titleY,0.85,0.92,0.90,1,UIFont.Medium)
    self:drawText((self.originName or "")..(self.originCondition and "  -  "..self.originCondition or ""),
        L.side,L.originY,0.7,0.78,0.8,1,UIFont.Small)
    self:drawText(getText(self.deviceOnly and "IGUI_LW_DeviceWiring" or "IGUI_LW_WiringList"),
        L.side,L.listTitleY,0.7,0.78,0.8,1,UIFont.Small)
    self:setStencilRect(L.side,L.reasonY,self.width-2*L.side,L.reasonH)
    self:drawText(self.reason or getText("IGUI_LW_WiringHint"),L.side,L.reasonY,0.9,0.8,0.52,1,UIFont.Small)
    self:clearStencilRect()
end
function Panel:close()
    if self.closed then return end
    -- UIManager defers removal: stop callbacks and hide before releasing data.
    self.closed=true
    self:setVisible(false)
    self:removeFromUIManager();self.list:clear();self.inverters={}
    self.inverter,self.obj,self.player=nil,nil,nil
    Panel.releaseInstance(self)
end
