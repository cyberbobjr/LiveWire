-- Live Wire: individual equipment LCD, using read-only authoritative telemetry.
if isServer() then return end
require "ISUI/ISPanel"
require "ISUI/ISButton"
LiveWire = LiveWire or {}
local Panel = ISPanel:derive("LiveWireDevicePanel")
LiveWire.DevicePanel = Panel
local W = 500

function Panel.open(player,obj)
    local mark = LiveWire.Marks.get(obj)
    if not mark then return end
    if Panel.instance then Panel.instance:close() end
    local fh = getTextManager():getFontHeight(LiveWire.Client.lcdFont()) + 4
    local p = Panel:new(getPlayerScreenLeft(player:getPlayerNum())+120,
        getPlayerScreenTop(player:getPlayerNum())+90,W,math.max(330,150+8*fh))
    p.player,p.obj,p.device,p.linkedId = player,obj,mark.id,mark.inv
    p.lastRead,p.moveWithMouse = -2000,true
    p.backgroundColor = {r=0.20,g=0.21,b=0.22,a=0.98}
    LiveWire.Client.deviceView = nil
    p:initialise();p:addToUIManager();Panel.instance = p
end

function Panel:createChildren()
    ISPanel.createChildren(self)
    local function button(x,y,w,key,action)
        local b=ISButton:new(x,y,w,28,getText(key),self,Panel.onButton)
        b.internal=action;b:initialise();b:instantiate();self:addChild(b)
    end
    button(18,self.height-48,W-36,"IGUI_LW_Connections","links")
    button(W-36,6,26,"IGUI_LW_CloseShort","close")
end

function Panel:onButton(b)
    if self.closed then return end
    if b.internal=="close" then self:close()
    elseif b.internal=="links" and LiveWire.Equipment.accessible(self.player,self.obj,3.5) then
        LiveWire.ConnectionPanel.open(self.player,self.obj)
    end
end

function Panel:update()
    if self.closed then return end
    ISPanel.update(self)
    if not LiveWire.Equipment.accessible(self.player,self.obj,3.5) then self:close();return end
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
        if s.kind=="solar" then
            rows[#rows+1]=getText("IGUI_LW_DeviceDirt",math.floor(s.dirt*100+0.5))
            rows[#rows+1]=getText("IGUI_LW_DeviceSnow",math.floor(s.snow*100+0.5))
        elseif s.kind=="wind" then
            rows[#rows+1]=getText(s.brake and "IGUI_LW_DeviceBraked" or "IGUI_LW_DeviceReleased")
        end
    end
    return rows
end

function Panel:render()
    if self.closed then return end
    ISPanel.render(self)
    self:drawText("LIVE WIRE",18,10,0.85,0.87,0.9,1,UIFont.Medium)
    local m=LiveWire.Marks.get(self.obj)
    self:setStencilRect(190,10,W-240,28)
    self:drawText(getText("IGUI_LW_Model_"..(m and m.model or "")),190,14,0.85,0.87,0.9,1,UIFont.Small)
    self:clearStencilRect()
    self:drawRect(14,42,W-28,self.height-106,1,0.06,0.07,0.06)
    local pump=m and m.model=="WaterPump"
    if pump then self:drawRect(19,47,W-38,self.height-116,1,0.38,0.64,0.82)
    else self:drawRect(19,47,W-38,self.height-116,1,0.62,0.74,0.40) end
    local font=LiveWire.Client.lcdFont()
    local fh=getTextManager():getFontHeight(font)+4
    local r,g,b=0.08,0.13,0.05
    if pump then r,g,b=0.05,0.11,0.20 end
    self:setStencilRect(27,48,W-54,self.height-118)
    for i,line in ipairs(self:lines()) do
        self:drawText(line,28,56+(i-1)*fh,r,g,b,1,font)
    end
    self:clearStencilRect()
end

function Panel:close()
    if self.closed then return end
    self.closed=true;self:setVisible(false);self:removeFromUIManager()
    self.obj,self.player,self.data=nil,nil,nil
    if Panel.instance==self then Panel.instance=nil;LiveWire.Client.deviceView=nil end
end
