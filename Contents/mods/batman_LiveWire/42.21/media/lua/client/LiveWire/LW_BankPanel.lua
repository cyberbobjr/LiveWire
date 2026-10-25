-- Live Wire: local bank LCD. Native inventory remains responsible for transfers.
if isServer() then return end
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "LiveWire/LW_Stack"
LiveWire = LiveWire or {}
local Panel = ISPanel:derive("LiveWireBankPanel")
LiveWire.BankPanel = Panel
local W, H = 500, 350
local function button(self,x,y,w,key,action,label)
    local b=ISButton:new(x,y,w,28,label or getText(key),self,Panel.onButton)
    b.internal=action;b:initialise();b:instantiate();self:addChild(b);return b
end
function Panel.open(player,obj)
    if Panel.instance then Panel.instance:close() end
    local fh=getTextManager():getFontHeight(LiveWire.Client.lcdFont())+4
    local p=Panel:new(getPlayerScreenLeft(player:getPlayerNum())+120,
        getPlayerScreenTop(player:getPlayerNum())+90,W,math.max(H,160+8*fh))
    p.player,p.obj,p.device=player,obj,LiveWire.Marks.get(obj).id
    p.page,p.lastRead,p.moveWithMouse=1,-2000,true
    p.backgroundColor={r=0.20,g=0.21,b=0.22,a=0.98}
    p:initialise();p:addToUIManager();Panel.instance=p
end
function Panel:createChildren()
    ISPanel.createChildren(self)
    local y=self.height-48
    local prev=button(self,18,y,70,"IGUI_LW_BankPrev","prev","<")
    prev.tooltip=getText("IGUI_LW_BankPrev")
    local next=button(self,96,y,70,"IGUI_LW_BankNext","next",">")
    next.tooltip=getText("IGUI_LW_BankNext")
    self.stackBtn=button(self,174,y,140,"IGUI_LW_BankPosition","bank",getText("IGUI_LW_BankPosition",1,1))
    button(self,322,y,160,"IGUI_LW_Connections","links")
    button(self,W-36,6,26,"IGUI_LW_CloseShort","close")
end
function Panel:onButton(b)
    if self.closed then return end
    if b.internal=="close" then self:close()
    elseif b.internal=="links" then LiveWire.ConnectionPanel.open(self.player,self.obj)
    elseif b.internal=="bank" then
        local banks=LiveWire.Stack.banks(self.obj:getSquare())
        for i,obj in ipairs(banks) do
            if obj==self.obj and #banks>1 then
                local player,target=self.player,banks[i%#banks+1]
                Panel.open(player,target)
                local loot=getPlayerLoot(player:getPlayerNum())
                if loot then loot:setForceSelectedContainer(target:getContainer()) end
                break
            end
        end
    elseif self.data then
        local n=math.max(1,#self.data.batteries)
        self.page=(self.page+(b.internal=="next" and 0 or -2))%n+1
    end
end
function Panel:update()
    if self.closed then return end
    ISPanel.update(self)
    if not LiveWire.Equipment.accessible(self.player,self.obj,3.5) then self:close();return end
    local now=getTimestampMs()
    if now-self.lastRead>=2000 then
        self.lastRead=now
        self.stackPosition,self.stackCount=LiveWire.Stack.position(self.obj)
        self.stackBtn:setTitle(getText("IGUI_LW_BankPosition",self.stackPosition,self.stackCount))
        self.stackBtn:setEnable(self.stackCount>1)
        if not isClient() then self.data=LiveWire.Client.readBank(self.device)
        else LiveWire.Client.readBank(self.device) end
    end
    if isClient() then
        local v=LiveWire.Client.bankView
        self.data=v and v.device==self.device and v.snapshot or nil
    end
    if self.data then self.page=math.min(self.page,math.max(1,#self.data.batteries)) end
end
function Panel:render()
    if self.closed then return end
    ISPanel.render(self)
    local font=LiveWire.Client.lcdFont()
    self:drawText("LIVE WIRE",18,10,0.85,0.87,0.9,1,UIFont.Medium)
    self:drawText(getText("IGUI_LW_BankTitle"),190,14,0.85,0.87,0.9,1,UIFont.Small)
    self:drawRect(14,42,W-28,self.height-106,1,0.06,0.07,0.06)
    self:drawRect(19,47,W-38,self.height-116,1,0.62,0.74,0.40)
    local function line(s,y)
        self:setStencilRect(27,48,W-54,self.height-118)
        self:drawText(s,28,y,0.08,0.13,0.05,1,font);self:clearStencilRect()
    end
    local fh=getTextManager():getFontHeight(font)+4
    local m=LiveWire.Marks.get(self.obj)
    line(getText("IGUI_LW_BankPosition",self.stackPosition or 1,self.stackCount or 1).." - "
        ..getText(m and m.inv and "IGUI_LW_BankLinked" or "IGUI_LW_BankIndependent"),56)
    line(LiveWire.Client.equipmentCondition(m and m.cond),56+fh)
    local s=self.data
    if not s then line(getText("IGUI_LW_Waiting"),56+2*fh);return end
    local pct=s.capacity>0 and math.floor(s.stock/s.capacity*100+0.5) or 0
    line(getText("IGUI_LW_LCD_Stock",pct),56+2*fh)
    line(getText("IGUI_LW_LCD_Kwh",string.format("%.2f",s.stock),string.format("%.2f",s.capacity)),56+3*fh)
    local by=56+4*fh
    self:drawRectBorder(28,by,W-56,15,1,0.08,0.13,0.05)
    self:drawRect(31,by+3,(W-62)*LiveWire.clamp(pct/100,0,1),9,1,0.08,0.13,0.05)
    line(getText("IGUI_LW_BankSlots",#s.batteries,s.slots,s.extra),by+24)
    line(getText("IGUI_LW_BankReserve",string.format("%.2f",s.reserve)),by+24+fh)
    local b=s.batteries[self.page]
    if b then
        local charge=b.capacity>0 and math.floor(b.charge/b.capacity*100+0.5) or 0
        line(getText("IGUI_LW_BankBattery",self.page,#s.batteries,
            getItemNameFromFullType(b.model)),by+32+2*fh)
        line(getText("IGUI_LW_BankBatteryState",charge,b.cond),by+32+3*fh)
    else line(getText("IGUI_LW_LCD_NoBattery"),by+32+2*fh) end
end
function Panel:close()
    if self.closed then return end
    -- UIManager defers removal: stop callbacks and hide before releasing data.
    self.closed=true
    self:setVisible(false)
    self:removeFromUIManager()
    self.obj,self.player,self.data=nil,nil,nil
    LiveWire.Client.bankView=nil
    if Panel.instance==self then Panel.instance=nil end
end
