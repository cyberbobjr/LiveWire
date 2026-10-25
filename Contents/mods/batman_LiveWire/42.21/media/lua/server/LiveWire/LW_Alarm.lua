-- Live Wire: low battery alarm (authority only).
-- An optional device of the network. When the battery stock falls below 20 %, it
-- warns the players nearby (translated message), lights its beacon and beeps at
-- every simulation step until acknowledged; it re-arms once the stock is back
-- above 25 %. The beep is played locally by each client (LW_Beep.lua): the server only
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
-- While the stock stays under 20 %, the alarm rings (its beacon stays lit, client
-- side) and beeps at every step until a player acknowledges it; the message is
-- repeated every two game hours. It re-arms once the stock is back above 25 %.
-- Returns true when it beeped during this call.
function Alarm.check(grid, alarm, stockFrac, now)
    if not alarm or (alarm.cond or 0) <= 0 or not stockFrac then
        grid.alarmOn, grid.alarmAck = nil, nil
        return false
    end
    local Defs = LiveWire.Defs
    if stockFrac >= Defs.ALARM_RESET then
        grid.alarmOn, grid.alarmAck = nil, nil
        return false
    end
    if not grid.alarmOn and stockFrac >= Defs.ALARM_BELOW then return false end
    local first = not grid.alarmOn
    grid.alarmOn = true
    if first or not grid.alarmAt or now - grid.alarmAt >= Defs.ALARM_REPEAT_HOURS then
        grid.alarmAt = now
        local pct = tostring(math.floor(stockFrac * 100 + 0.5))
        LiveWire.notifyNear(alarm.x, alarm.y, alarm.z, Alarm.RANGE, "IGUI_LW_LowBatteryNamed",
            { pct, grid.name ~= "" and grid.name or "IGUI_LW_Network" }, true)
    end
    if grid.alarmAck then return false end
    Alarm.beepNear(alarm.x, alarm.y, alarm.z)
    return true
end
