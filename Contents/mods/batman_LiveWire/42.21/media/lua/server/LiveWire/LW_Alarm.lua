-- Live Wire: low battery alarm (authority only).
-- An optional device of the network. When the battery stock falls below 20 %, it
-- warns the players nearby (translated message) and beeps; it repeats every two
-- game hours while the stock stays low, and re-arms once the stock is back above
-- 25 %. The beep is played locally by each client (LW_Beep.lua): the server only
-- sends the position.
if isClient() then return end

LiveWire = LiveWire or {}

local Alarm = {}
LiveWire.Alarm = Alarm

Alarm.RANGE = 30

-- Ask the clients near (x, y, z) to beep (single player: play it directly).
function Alarm.beepNear(x, y, z)
    if not isServer() then
        if LiveWire.Beep then LiveWire.Beep.play(x, y, z) end
        return
    end
    local players = getOnlinePlayers()
    if not players then return end
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p and not p:isDead() then
            local dx, dy = p:getX() - x, p:getY() - y
            if dx * dx + dy * dy <= Alarm.RANGE * Alarm.RANGE and math.abs(p:getZ() - z) < 3 then
                sendServerCommand(p, LiveWire.MODULE, LiveWire.Protocol.S_BEEP, { x = x, y = y, z = z })
            end
        end
    end
end

-- One check per simulation step. stockFrac: stock / capacity, nil without battery.
-- Returns true when the alarm went off during this call.
function Alarm.check(grid, alarm, stockFrac, now)
    if not alarm or (alarm.cond or 0) <= 0 or not stockFrac then
        grid.alarmOn = nil
        return false
    end
    local Defs = LiveWire.Defs
    if stockFrac >= Defs.ALARM_RESET then
        grid.alarmOn = nil
        return false
    end
    if stockFrac >= Defs.ALARM_BELOW then return false end
    if grid.alarmOn and grid.alarmAt and now - grid.alarmAt < Defs.ALARM_REPEAT_HOURS then
        return false
    end
    grid.alarmOn = true
    grid.alarmAt = now
    local pct = tostring(math.floor(stockFrac * 100 + 0.5))
    LiveWire.notifyNear(alarm.x, alarm.y, alarm.z, Alarm.RANGE, "IGUI_LW_LowBattery", { pct }, true)
    Alarm.beepNear(alarm.x, alarm.y, alarm.z)
    return true
end
