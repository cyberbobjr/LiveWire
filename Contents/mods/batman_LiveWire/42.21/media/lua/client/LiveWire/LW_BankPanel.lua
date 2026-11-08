-- Live Wire: local bank LCD. Native inventory remains responsible for transfers.
if isServer() then return end
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "LiveWire/LW_Stack"
require "LiveWire/LW_UIScale"
LiveWire = LiveWire or {}
local Panel = ISPanel:derive("LiveWireBankPanel")
LiveWire.BankPanel = Panel
-- Sizes at the 1080p reference font, scaled once per window (LW_UIScale.lua).
local BASE = { w=500, h=350, fixedH=160, btnH=28, btnBottom=48, side=18,
    nextX=96, arrowW=70, stackX=174, stackW=140, linksX=322, linksW=160, closeX=36, closeY=6, closeW=26,
    brandY=10, titleX=190, titleY=14, lcdX=14, lcdY=42, lcdInner=5, lcdBottom=106, lcdInnerBottom=116,
    textX=28, clipX=27, clipY=48, clipRight=54, clipBottom=118, lineY=56, barH=15, barIn=3, barFill=9,
    barW=56, barFillW=62, after=24, gap=32, linePad=4 }
Panel.BASE = BASE
-- Unscaled layout until a window is opened (instances made without open()).
Panel.L = LiveWire.UIScale.layout(1, BASE)
local function button(self,x,y,w,key,action,label)
    local b=ISButton:new(x,y,w,self.L.btnH,label or getText(key),self,Panel.onButton)
    b.internal=action;b:initialise();b:instantiate();self:addChild(b);return b
end
function Panel.open(player,obj)
    if Panel.instance then Panel.instance:close() end
    local UI=LiveWire.UIScale
    local fh=getTextManager():getFontHeight(LiveWire.Client.lcdFont())
    local k=UI.factor(BASE.w,BASE.h)
    local L=UI.layout(k,BASE)
    L.fh=fh+L.linePad
    local x,y,w,h=UI.fit(getPlayerScreenLeft(player:getPlayerNum())+120,
        getPlayerScreenTop(player:getPlayerNum())+90,L.w,math.max(L.h,L.fixedH+8*L.fh))
    local p=Panel:new(x,y,w,h)
    p.L=L
    p.player,p.obj,p.device=player,obj,LiveWire.Marks.get(obj).id
    p.page,p.lastRead,p.moveWithMouse=1,-2000,true
    p.backgroundColor={r=0.20,g=0.21,b=0.22,a=0.98}
    p:initialise();p:addToUIManager();Panel.instance=p
end
function Panel:createChildren()
    ISPanel.createChildren(self)
    local L=self.L
    local y=self.height-L.btnBottom
    local prev=button(self,L.side,y,L.arrowW,"IGUI_LW_BankPrev","prev","<")
    prev.tooltip=getText("IGUI_LW_BankPrev")
    local next=button(self,L.nextX,y,L.arrowW,"IGUI_LW_BankNext","next",">")
    next.tooltip=getText("IGUI_LW_BankNext")
    self.stackBtn=button(self,L.stackX,y,L.stackW,"IGUI_LW_BankPosition","bank",getText("IGUI_LW_BankPosition",1,1))
    button(self,L.linksX,y,L.linksW,"IGUI_LW_Connections","links")
    button(self,self.width-L.closeX,L.closeY,L.closeW,"IGUI_LW_CloseShort","close")
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
    local L,W=self.L,self.width
    self:drawText("LIVE WIRE",L.side,L.brandY,0.85,0.87,0.9,1,UIFont.Medium)
    self:drawText(getText("IGUI_LW_BankTitle"),L.titleX,L.titleY,0.85,0.87,0.9,1,UIFont.Small)
    self:drawRect(L.lcdX,L.lcdY,W-2*L.lcdX,self.height-L.lcdBottom,1,0.06,0.07,0.06)
    self:drawRect(L.lcdX+L.lcdInner,L.lcdY+L.lcdInner,W-2*(L.lcdX+L.lcdInner),self.height-L.lcdInnerBottom,1,0.62,0.74,0.40)
    local function line(s,y)
        self:setStencilRect(L.clipX,L.clipY,W-L.clipRight,self.height-L.clipBottom)
        self:drawText(s,L.textX,y,0.08,0.13,0.05,1,font);self:clearStencilRect()
    end
    local fh=L.fh or getTextManager():getFontHeight(font)+L.linePad
    local top=L.lineY
    local m=LiveWire.Marks.get(self.obj)
    line(getText("IGUI_LW_BankPosition",self.stackPosition or 1,self.stackCount or 1).." - "
        ..getText(m and m.inv and "IGUI_LW_BankLinked" or "IGUI_LW_BankIndependent"),top)
    line(LiveWire.Client.equipmentCondition(m and m.cond),top+fh)
    local s=self.data
    if not s then line(getText("IGUI_LW_Waiting"),top+2*fh);return end
    local pct=s.capacity>0 and math.floor(s.stock/s.capacity*100+0.5) or 0
    line(getText("IGUI_LW_LCD_Stock",pct),top+2*fh)
    line(getText("IGUI_LW_LCD_Kwh",string.format("%.2f",s.stock),string.format("%.2f",s.capacity)),top+3*fh)
    local by=top+4*fh
    self:drawRectBorder(L.textX,by,W-L.barW,L.barH,1,0.08,0.13,0.05)
    self:drawRect(L.textX+L.barIn,by+L.barIn,(W-L.barFillW)*LiveWire.clamp(pct/100,0,1),L.barFill,1,0.08,0.13,0.05)
    line(getText("IGUI_LW_BankSlots",#s.batteries,s.slots,s.extra),by+L.after)
    line(getText("IGUI_LW_BankReserve",string.format("%.2f",s.reserve)),by+L.after+fh)
    local b=s.batteries[self.page]
    if b then
        local charge=b.capacity>0 and math.floor(b.charge/b.capacity*100+0.5) or 0
        line(getText("IGUI_LW_BankBattery",self.page,#s.batteries,
            getItemNameFromFullType(b.model)),by+L.gap+2*fh)
        line(getText("IGUI_LW_BankBatteryState",charge,b.cond),by+L.gap+3*fh)
    else line(getText("IGUI_LW_LCD_NoBattery"),by+L.gap+2*fh) end
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
