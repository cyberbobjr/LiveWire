-- Live Wire: direct world click, restricted to our marked, reachable devices.
if isServer() then return end
require "LiveWire/LW_BankPanel"
require "LiveWire/LW_ConnectionPanel"
require "LiveWire/LW_DevicePanel"
LiveWire=LiveWire or {}
local Equipment={}
LiveWire.Equipment=Equipment
function Equipment.accessible(player,obj,range)
    local sq=obj and obj:getSquare()
    return player and not player:isDead() and sq and obj:getObjectIndex()~=-1
        and math.floor(player:getZ())==sq:getZ()
        and math.abs(player:getX()-(sq:getX()+0.5))<=range
        and math.abs(player:getY()-(sq:getY()+0.5))<=range
        and (not SafeHouse or SafeHouse.isSafehouseAllowInteract(sq,player))
end
function Equipment.open(player,obj)
    local m=LiveWire.Marks.get(obj)
    local d=m and LiveWire.Defs.devices[m.model]
    if not d then return false end
    if d.role=="inverter" then LiveWire.InverterPanel.open(player,m.cpl or m.id,obj)
    elseif d.role=="storage" then LiveWire.BankPanel.open(player,obj)
    elseif d.kind=="breaker" then LiveWire.BreakerPanel.open(player,obj)
    else LiveWire.DevicePanel.open(player,obj) end
    return true
end
function Equipment.onClick(obj)
    local m=LiveWire.Marks.get(obj)
    if not m then return end
    local player=getSpecificPlayer(0) -- native mouse picker targets player 0
    local speed=UIManager.getSpeedControls()
    if not Equipment.accessible(player,obj,3) or player:isAiming() or player:isAsleep()
        or player:getVehicle() or player:isIgnoreContextKey()
        or getCell():getDrag(0) or (speed and speed:getCurrentGameSpeed()==0) then return end
    local sq=obj:getSquare()
    local ps=player:getCurrentSquare()
    if not sq:isSeen(0) or not ps or ps:isSomethingTo(sq)
        or player:DistToSquared(sq:getX()+0.5,sq:getY()+0.5)>=6 then return end
    Equipment.open(player,obj)
end
Events.OnObjectLeftMouseButtonDown.Add(Equipment.onClick)
