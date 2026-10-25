-- Live Wire: read-only, single-device telemetry from already measured values.
if isClient() then return end
LiveWire = LiveWire or {}
local View = {}
LiveWire.DeviceView = View

function View.snapshot(dev)
    local def = dev and LiveWire.Defs.devices[dev.model]
    if not def or def.role ~= dev.role or not (dev.role == "source" or dev.role == "pump"
        or def.kind == "alarm") then return nil end
    local R = LiveWire.Registry
    local grid = dev.grid and R.grid(dev.grid)
    local healthy = (dev.cond or 0) > 0
    local s = { device = dev.id, model = dev.model, kind = def.kind or dev.role,
        cond = math.floor((dev.cond or 0) + 0.5), inverter = grid and grid.inverter,
        name = grid and grid.name or "", state = healthy and (dev.state or "ok") or "broken" }
    if dev.role == "source" then
        s.nominal = def.nominalW or 0
        s.brake = dev.brake == true
        s.w = grid and healthy and not s.brake and math.floor((dev.pOut or 0) + 0.5) or 0
        s.state = not healthy and "broken" or s.w > 0 and "on" or "idle"
        if def.kind == "solar" then
            s.dirt, s.snow = dev.dirt or 0, dev.snow or 0
        end
    elseif dev.role == "pump" then
        local inv = grid and R.device(grid.inverter)
        local supplied = healthy and grid and grid.powered and not grid.equipmentOff
            and not grid.mainOff and inv and inv.state == "on"
            and not (LiveWire.Pump and LiveWire.Pump.disabled())
        if healthy and not supplied then s.state = "nopower" end
        local measured = supplied and (dev.state == "running" or dev.state == "idle")
        s.flow = measured and (dev.flowLph or 0) or 0
        local duty = LiveWire.clamp(s.flow / (LiveWire.Defs.PUMP_LITRES_PER_MINUTE * 60), 0, 1)
        s.w = math.floor((def.pumpW or 0) * duty + 0.5)
        s.flow = math.floor(s.flow + 0.5)
    elseif def.kind == "alarm" then
        s.state = not healthy and "broken" or not grid and "off"
            or grid.alarmOn and "ringing" or "ok"
    end
    return s
end
