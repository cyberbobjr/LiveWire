-- Live Wire: inverter fleet rules of a network (authority only, D-48).
-- A network has one master inverter and up to MAX_SLAVES coupled slaves. Which of
-- them are in service, the capacity they give and the idle power they draw are
-- decided here, so that the simulation, the demand and the computer share one
-- definition. Every function reads the registry when called, never when loaded.
if isClient() then return end

LiveWire = LiveWire or {}

local Inverters = {}
LiveWire.Inverters = Inverters

-- Script definition of an inverter device (an empty table without one).
function Inverters.def(dev)
    return dev and LiveWire.Defs.devices[dev.model] or {}
end

-- A master is in service when switched on or tripped (it is the one that trips).
function Inverters.masterInService(inv)
    return inv ~= nil and (inv.state == "on" or inv.state == "tripped")
end

-- A coupled slave is in service when switched on and not broken.
function Inverters.slaveInService(sl)
    return sl.state == "on" and (sl.cond or 0) > 0
end

-- Inverters of a grid that are in service: the master when its state is "on" or
-- "tripped", plus every slave in service. Returns count, list of slave devices in
-- service.
function Inverters.inService(grid)
    local R = LiveWire.Registry
    local n, list = 0, {}
    if Inverters.masterInService(R.device(grid.inverter)) then n = 1 end
    local slaves = R.slaves(grid)
    for i = 1, #slaves do
        local sl = slaves[i]
        if Inverters.slaveInService(sl) then
            n = n + 1
            list[#list + 1] = sl
        end
    end
    return n, list
end

-- Capacity of a grid in W: sum of the maxW of each inverter in service, by its own
-- model (an inverter and an inverter cabinet can be coupled). At least the master's
-- maxW, so that a lone inverter behaves exactly as before.
function Inverters.capacityW(grid)
    local R = LiveWire.Registry
    local inv = R.device(grid.inverter)
    local n, list = Inverters.inService(grid)
    local cap = 0
    if n > #list then cap = Inverters.def(inv).maxW or 0 end   -- the master is in service
    for i = 1, #list do
        cap = cap + (Inverters.def(list[i]).maxW or 0)
    end
    if cap <= 0 then cap = Inverters.def(inv).maxW or 0 end
    return cap
end

-- Idle consumption: sum of the idleW of each switched-on inverter, by its own model
-- (master counts when on).
function Inverters.idleW(grid)
    local R = LiveWire.Registry
    local inv = R.device(grid.inverter)
    local w = 0
    if inv and inv.state == "on" then w = Inverters.def(inv).idleW or 0 end
    local slaves = R.slaves(grid)
    for i = 1, #slaves do
        if slaves[i].state == "on" then w = w + (Inverters.def(slaves[i]).idleW or 0) end
    end
    return w
end
