-- Live Wire: individual equipment LCD, using read-only authoritative telemetry.
if isServer() then return end
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "LiveWire/LW_UIScale"
require "LiveWire/LW_UIKit"
require "LiveWire/LW_Lcd"
LiveWire = LiveWire or {}
local Panel = ISPanel:derive("LiveWireDevicePanel")
LiveWire.DevicePanel = Panel
LiveWire.UIKit.singleton("DevicePanel", Panel)
-- Sizes at the 1080p reference font, scaled once per window (LW_UIScale.lua).
-- Screen sizes: LiveWire.Lcd.DEVICE_BASE.
local BASE = LiveWire.Lcd.withDeviceScreen({ w=500, h=330, fixedH=150, btnH=28, btnBottom=48, side=18,
    closeX=36, closeY=6, closeW=26,
    brandY=10, titleX=190, titleClipY=10, titleRight=240, titleClipH=28, titleY=14 })
Panel.BASE = BASE
-- Unscaled layout until a window is opened (instances made without open()).
Panel.L = LiveWire.UIScale.layout(1, BASE)
local ACCESS_RANGE = 3.5 -- the window closes when the device is farther than this

function Panel.open(player,obj)
    local mark = LiveWire.Marks.get(obj)
    if not mark then return end
    Panel.closeInstance()
    local UI = LiveWire.UIScale
    local L = UI.layout(UI.factor(BASE.w, BASE.h), BASE)
    L.fh = getTextManager():getFontHeight(LiveWire.Client.lcdFont()) + L.linePad
    local x,y,w,h = UI.fit(getPlayerScreenLeft(player:getPlayerNum())+120,
        getPlayerScreenTop(player:getPlayerNum())+90,L.w,math.max(L.h,L.fixedH+8*L.fh))
    local p = Panel:new(x,y,w,h)
    p.L = L
    p.player,p.obj,p.device,p.linkedId = player,obj,mark.id,mark.inv
    p.lastRead,p.moveWithMouse = -2000,true
    p.backgroundColor = {r=0.20,g=0.21,b=0.22,a=0.98}
    LiveWire.Client.deviceView = nil
    p:initialise();p:addToUIManager();Panel.instance = p
end

function Panel:createChildren()
    ISPanel.createChildren(self)
    local L,W=self.L,self.width
    local function button(x,y,w,key,action)
        LiveWire.UIKit.button(self,x,y,w,L.btnH,getText(key),Panel.onButton,action)
    end
    button(L.side,self.height-L.btnBottom,W-2*L.side,"IGUI_LW_Connections","links")
    button(W-L.closeX,L.closeY,L.closeW,"IGUI_LW_CloseShort","close")
end

function Panel:onButton(b)
    if self.closed then return end
    if b.internal=="close" then self:close()
    elseif b.internal=="links" and LiveWire.Equipment.accessible(self.player,self.obj,ACCESS_RANGE) then
        LiveWire.ConnectionPanel.open(self.player,self.obj)
    end
end

function Panel:update()
    if self.closed then return end
    ISPanel.update(self)
    if not LiveWire.Equipment.accessible(self.player,self.obj,ACCESS_RANGE) then self:close();return end
    local m=LiveWire.Marks.get(self.obj)
    if not m or m.id~=self.device then self:close();return end
    if m.inv~=self.linkedId then
        self.linkedId,self.lastRead,self.data=m.inv,-2000,nil
        LiveWire.Client.deviceView=nil
    end
    local now=getTimestampMs()
    if now-self.lastRead>=2000 then
        self.lastRead=now
        local data=LiveWire.Client.readDevice(self.device)
        if not isClient() then self.data=data end
    end
    if isClient() then
        local v=LiveWire.Client.deviceView
        local s=v and v.device==self.device and v.snapshot
        self.data=s and s.inverter==m.inv and s or nil
    end
end

function Panel:lines()
    local m=LiveWire.Marks.get(self.obj)
    local s=self.data
    local rows={getText(m and m.inv and "IGUI_LW_BankLinked" or "IGUI_LW_BankIndependent")}
    if s and s.name and s.name~="" then rows[1]=rows[1].." - "..s.name end
    rows[#rows+1]=LiveWire.Client.equipmentCondition(s and s.cond or m and m.cond)
    if not s then rows[#rows+1]=getText("IGUI_LW_Waiting");return rows end
    if s.kind=="pump" then
        rows[#rows+1]=getText("IGUI_LW_DeviceDemand",s.w)
        rows[#rows+1]=getText("IGUI_LW_DeviceFlow",s.flow)
        rows[#rows+1]=getText("ContextMenu_LW_PumpState_"..s.state)
    elseif s.kind=="alarm" then
        rows[#rows+1]=getText(s.state=="broken" and "IGUI_LW_State_broken"
            or s.state=="off" and "IGUI_LW_State_off"
            or s.state=="ringing" and "IGUI_LW_Alarm_On" or "IGUI_LW_Alarm_Armed")
    else
        rows[#rows+1]=getText("IGUI_LW_DeviceProduction",s.w)
        rows[#rows+1]=getText("IGUI_LW_DeviceNominal",s.nominal)
        rows[#rows+1]=getText("IGUI_LW_State_"..s.state)
        for _,f in ipairs(LiveWire.Defs.SOURCE_FIELDS[s.kind] or {}) do
            if f.flag then
                rows[#rows+1]=getText(s[f.field] and f.rowOn or f.rowOff)
            elseif f.row then
                rows[#rows+1]=getText(f.row,math.floor(s[f.field]*100+0.5))
            end
        end
    end
    return rows
end

function Panel:render()
    if self.closed then return end
    ISPanel.render(self)
    local L,W=self.L,self.width
    self:drawText("LIVE WIRE",L.side,L.brandY,0.85,0.87,0.9,1,UIFont.Medium)
    local m=LiveWire.Marks.get(self.obj)
    self:setStencilRect(L.titleX,L.titleClipY,W-L.titleRight,L.titleClipH)
    self:drawText(getText("IGUI_LW_Model_"..(m and m.model or "")),L.titleX,L.titleY,0.85,0.87,0.9,1,UIFont.Small)
    self:clearStencilRect()
    local Lcd=LiveWire.Lcd
    local font=Lcd.font()
    local fh=L.fh or getTextManager():getFontHeight(font)+L.linePad
    local variant=m and m.model=="WaterPump" and "pump" or "green"
    local line=Lcd.deviceScreen(self,L,W,self.height,variant,font,getTimestampMs())
    for i,s in ipairs(self:lines()) do line(s,L.lineY+(i-1)*fh) end
end

function Panel:close()
    if self.closed then return end
    self.closed=true;self:setVisible(false);self:removeFromUIManager()
    self.obj,self.player,self.data=nil,nil,nil
    if Panel.releaseInstance(self) then LiveWire.Client.deviceView=nil end
end
