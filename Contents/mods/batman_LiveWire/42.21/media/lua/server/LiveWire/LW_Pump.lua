-- Live Wire: water pump service (authority only, docs/annexes/conception/choix-et-extensions.md section 2).
-- A pump moves water from the water barrels linked to it into invisible relay tanks
-- (IsoThumpable with a FluidContainer) placed on the square ABOVE each plumbed fixture
-- it serves: vanilla plumbing finds the relay as an external water source
-- (IsoObject.FindExternalWaterSource), even empty. Only the relays that feed a plumbed
-- fixture are filled (Pump.feedsPlumbedFixture).
-- Only water is moved; the barrels' own FluidContainer is never replaced. Runs every
-- game minute (tickMinute) and on link changes (maintain).
-- This file is the facade: LiveWire.Pump. LW_PumpRelays.lua (relay life cycle, wanted
-- relays, discovery) and LW_PumpTransfer.lua (barrels, water transfer) attach their
-- functions to the same table; callers keep using Pump.xxx.
if isClient() then return end

LiveWire = LiveWire or {}

local Pump = {}
LiveWire.Pump = Pump

local Defs = LiveWire.Defs

local function R() return LiveWire.Registry end

-- Session memory of the last relay sync (see LW_PumpTransfer.lua). An entry is dropped
-- when its relay is removed.
Pump.relaySynced = {}    -- posKey -> litres at the last sync

-- `next` does not exist in Kahlua 42.21 (knowledge/kahlua-lua.md).
function Pump.hasAny(t)
    if not t then return false end
    for _ in pairs(t) do return true end
    return false
end

function Pump.countOf(t)
    local n = 0
    if t then
        for _ in pairs(t) do n = n + 1 end
    end
    return n
end

local hasAny = Pump.hasAny

-- Pumps disabled by the debug tool "remove every water relay" (before removing the
-- mod): no relay is placed and no water is moved until "enable the pumps again".
function Pump.disabled()
    return R() ~= nil and R().pumpsDisabled()
end

local function setState(dev, state)
    if dev.state ~= state then
        dev.state = state
        LiveWire.Devices.syncMark(dev)
    end
end

-- One game minute of service for one pump.
function Pump.step(dev)
    if Pump.disabled() then return end
    if not getCell():getGridSquare(dev.x, dev.y, dev.z) then return end
    if Pump.checkBarrels(dev) then LiveWire.Devices.syncMark(dev) end

    local grid = dev.grid and R().grid(dev.grid)
    local inv = grid and R().device(grid.inverter)
    local powered = grid ~= nil and grid.powered == true and not grid.equipmentOff and inv ~= nil and inv.state == "on"
        and not LiveWire.CircuitProvider.deviceBlocked(dev)
    if (dev.cond or 0) <= 0 then return setState(dev, "broken") end
    if not hasAny(dev.barrels) then return setState(dev, "nobarrel") end
    if not powered then return setState(dev, "nopower") end

    -- A minute of unused flow is not stored water. Clear legacy credits as well.
    dev.budget = 0
    local needs, total = Pump.needsOf(dev)
    if total < 0.01 then return setState(dev, "idle") end

    local sources = Pump.sourcesOf(dev)
    if #sources == 0 then return setState(dev, "nobarrel") end
    dev.budget = math.min(Defs.PUMP_BUDGET_MAX, Defs.PUMP_LITRES_PER_MINUTE)

    local moved = Pump.moveWater(dev, needs, sources)

    if moved > Defs.PUMP_FLUID_EPSILON then
        setState(dev, "running")
        local radius = Defs.PUMP_NOISE_RADIUS
        if radius > 0 then addSound(nil, dev.x, dev.y, dev.z, radius, 1) end
    else
        setState(dev, "idle")
    end
end

-- Every game minute: each registry pump (loaded squares only, see Pump.step).
function Pump.tickMinute()
    local Rg = R()
    if not Rg or not Rg.ready or Rg.readOnly then return end
    local pumps = Rg.devicesByRole("pump")
    for i = 1, #pumps do
        local dev = Rg.device(pumps[i].id)
        if dev then
            local ok, err = pcall(Pump.step, dev)
            if not ok then LiveWire.warn("pump " .. dev.id .. " failed: " .. tostring(err)) end
        end
    end
end

-- Power of a pump at a given duty (share of its full flow), 250 W at full duty.
local function wattsAt(dev, duty)
    local def = Defs.devices[dev.model]
    return (def and def.pumpW or 0) * duty
end

-- Called by Sim.stepGrid: flow measured since the last step, duty and power demand
-- of the pumps (250 W at full duty). Resets the litres counter.
function Pump.demandW(pumps, dt)
    local w = 0
    for i = 1, #pumps do
        local dev = pumps[i]
        local pumped = dev.pumped or 0
        if dt > 0 then
            dev.flowLph = pumped / dt
            local duty = math.min(1, pumped / (Defs.PUMP_LITRES_PER_MINUTE * 60 * dt))
            w = w + wattsAt(dev, duty)
        else
            dev.flowLph = 0
        end
        dev.pumped = 0
    end
    return w
end

-- Pumps in service, their flow (L/h) and their power (W), rounded, from the last
-- measured flow (Sim.snapshot, the figures the software shows). Reads only: it never
-- calls demandW, which consumes the litres counter. No scan, water transfer or new state.
function Pump.summary(pumps)
    local n, flow, watts = 0, 0, 0
    for i = 1, #pumps do
        local dev = pumps[i]
        if dev.state == "running" or dev.state == "idle" then n = n + 1 end
        flow = flow + (dev.flowLph or 0)
        local duty = LiveWire.clamp((dev.flowLph or 0) / (Defs.PUMP_LITRES_PER_MINUTE * 60), 0, 1)
        watts = watts + wattsAt(dev, duty)
    end
    return { n = n, flow = math.floor(flow + 0.5), w = math.floor(watts + 0.5) }
end

-- A pump is removed: its relays go, and the barrel marks of loaded barrels are cleared.
function Pump.forget(dev)
    Pump.releaseRelays(dev)
    Pump.releaseBarrels(dev)
end

-- One loaded square of a chunk: remove the relays whose pump or entry is gone and
-- clear the barrel marks whose pump no longer exists.
local function sweepSquare(Rg, sq)
    local objs = sq:getObjects()
    local doomed, clear = {}, {}
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if LiveWire.Install.isRelay(o) then
            local m = o:getModData()[Defs.RELAY_KEY]
            local dev = m and Rg.device(m.pump)
            local key = LiveWire.posKey(sq:getX(), sq:getY(), sq:getZ())
            if not dev or dev.role ~= "pump" or not dev.relays or not dev.relays[key] then
                doomed[#doomed + 1] = o
            end
        elseif o.getModData and o:getModData()[Defs.BARREL_KEY] ~= nil then
            if not LiveWire.Barrels.repairMark(o) then clear[#clear + 1] = o end
        end
    end
    for i = 1, #doomed do sq:transmitRemoveItemFromSquare(doomed[i]) end
    for i = 1, #clear do
        clear[i]:getModData()[Defs.BARREL_KEY] = nil
        if isServer() then clear[i]:transmitModData() end
    end
end

-- Chunk load: remove relays whose pump or entry is gone; clear barrel marks whose
-- pump no longer exists. Only the objects of the chunk are visited. The first loaded
-- square of the chunk marks the nearby pump inventories dirty (margin of 16 tiles).
function Pump.onLoadChunk(chunk)
    local Rg = R()
    if not Rg or not Rg.ready or Rg.readOnly then return end
    local invalidated = false
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for ly = 0, 7 do
            for lx = 0, 7 do
                local sq = chunk:getGridSquare(lx, ly, z)
                if sq then
                    if not invalidated then
                        Pump.invalidateAt(sq, 16)
                        invalidated = true
                    end
                    sweepSquare(Rg, sq)
                end
            end
        end
    end
end

Events.EveryOneMinute.Add(Pump.tickMinute)

Events.OnObjectAboutToBeRemoved.Add(function(obj)
    if obj and obj.getSquare then Pump.invalidateAt(obj:getSquare()) end
end)
