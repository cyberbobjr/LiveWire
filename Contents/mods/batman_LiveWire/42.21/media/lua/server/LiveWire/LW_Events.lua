-- Live Wire: bounded, translated network journal; no additional broadcasts.
if isClient() then return end
LiveWire = LiveWire or {}
local Journal = {}
LiveWire.Journal = Journal
function Journal.add(grid, key, args, at)
    if not grid then return end
    grid.events = grid.events or {}
    local a = {}
    for i, v in ipairs(args or {}) do a[i] = v end
    local now = getGameTime():getWorldAgeHours()
    local time = at or now
    grid.events[#grid.events + 1] = { t = time, tod = (getGameTime():getTimeOfDay() + time - now) % 24,
        key = key, args = a }
    while #grid.events > 30 do table.remove(grid.events, 1) end
end
function Journal.capture(grid)
    local R = LiveWire.Registry
    local inv = R.device(grid.inverter)
    if not inv then return end
    local current = { inverter = inv.state,
        alarm = grid.alarmOn == true, shed = grid.shed == true }
    for id in pairs(grid.members or {}) do
        local d = R.device(id)
        if d then current[id] = (d.cond or 100) <= 0 and "broken"
            or (d.role == "pump" and "ok" or d.state or "ok") end
    end
    local prev = grid.eventState
    if prev then
        for id, state in pairs(current) do
            if prev[id] ~= state then
                if id == "power" then
                    Journal.add(grid, state and "IGUI_LW_Event_PowerOn" or "IGUI_LW_Event_PowerOff")
                elseif id == "alarm" and state then Journal.add(grid, "IGUI_LW_Event_LowBattery")
                elseif id == "shed" and state then Journal.add(grid, "IGUI_LW_Shed")
                elseif type(state) == "string" then
                    local dev = id == "inverter" and inv or R.device(id)
                    local stateKey = dev and dev.role == "backup" and "IGUI_LW_Backup_" or "IGUI_LW_State_"
                    Journal.add(grid, "IGUI_LW_Event_State", { dev and "IGUI_LW_Model_" .. dev.model or id,
                        stateKey .. state })
                end
            end
        end
    end
    grid.eventState = current
end
