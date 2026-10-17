-- Live Wire: simulation step of every network (authority only), every 10 game
-- minutes, whether players are near or not (docs/architecture.md section 4).
if isClient() then return end

LiveWire = LiveWire or {}

local Sim = {}
LiveWire.Sim = Sim

local Defs = LiveWire.Defs
local Physics = LiveWire.Physics

Sim.MAX_CATCHUP_HOURS = 720
Sim.SUBSTEP_HOURS = 1.0
Sim.SUBSCRIBE_RANGE = 30
Sim.SUBSCRIBE_MS = 10 * 60 * 1000

-- subscribers[gridId][username] = { player = IsoPlayer, expires = ms }
Sim.subscribers = {}

local function weather()
    local cm = getClimateManager()
    local season = cm:getSeason()
    return {
        clouds = cm:getCloudIntensity(),
        windKph = cm:getWindspeedKph(),
        snowing = cm:isSnowing(),
        snowIntensity = cm:getSnowIntensity(),
        temperature = cm:getTemperature(),
        storm = cm:getIsThunderStorming(),
        dawn = season:getDawn(),
        dusk = season:getDusk(),
    }
end

-- Mean of the solar curve over the time-of-day interval [t0, t0 + h], with wrap.
local function solarMean(t0, h, w)
    local t1 = t0 + h
    if t1 <= 24 then return Physics.solarCurveMean(t0, t1, w.dawn, w.dusk) end
    local a = Physics.solarCurveMean(t0, 24, w.dawn, w.dusk) * (24 - t0)
    local b = Physics.solarCurveMean(0, t1 - 24, w.dawn, w.dusk) * (t1 - 24)
    return (a + b) / h
end

local function chance(probability)
    return ZombRandFloat(0, 1) < probability
end

local function sourceRaw(src, def, w, t0, h)
    if (src.cond or 0) <= 0 then return 0 end
    local factor = 0
    if def.kind == "solar" then
        factor = Physics.solarFactor(solarMean(t0, h, w), w.clouds, src.snow or 0)
            * LiveWire.Config.get("SolarMultiplier")
    elseif def.kind == "wind" then
        factor = Physics.windFactor(Physics.windAtHeight(w.windKph, src.z))
            * LiveWire.Config.get("WindMultiplier")
    end
    return def.nominalW * factor * Physics.conditionFactor(src.cond) * (src.eff or 0.85)
end

local function wearDevice(dev, def, h, extra)
    local mult = LiveWire.Config.get("DeviceWearMultiplier")
    if mult <= 0 or not def.wearDays then return end
    local loss = h / (def.wearDays * 24) * mult * (extra or 1)
        * Defs.deviceWearSkillFactor(dev.level or 0)
    dev.cond = math.max(0, (dev.cond or 100) - loss)
end

local function weatherOnSource(src, def, w, h)
    if def.kind == "solar" then
        local snow = src.snow or 0
        if w.snowing then snow = snow + 0.1 * w.snowIntensity * h end
        if w.temperature > 0 then snow = snow - 0.05 * h end
        src.snow = LiveWire.clamp(snow, 0, 1)
    end
    if not LiveWire.Config.get("StormDamage") then return end
    if def.kind == "solar" and w.storm and chance(h / 20) then
        src.cond = math.max(0, (src.cond or 100) - 5)
    elseif def.kind == "wind" and Physics.windAtHeight(w.windKph, src.z) > Physics.WIND_CUT_OUT
        and not src.brake and chance(h / 6) then
        src.cond = math.max(0, (src.cond or 100) - ZombRand(5, 16))
    end
end

local function batteryWear(entry, drawn, h)
    local dev = entry.dev
    local def = LiveWire.Batteries.def(dev.model)
    if not def then return end
    if drawn > 0 then
        local deep = entry.capacity > 0
            and entry.charge / entry.capacity < Defs.DEEP_DISCHARGE_THRESHOLD
        local wear = Physics.batteryWear(drawn, def.capacityKWh, def.lifeCycles, deep,
            LiveWire.Config.get("BatteryWearMultiplier") * (dev.wearFactor or 1))
        entry.cond = math.max(0, entry.cond - wear)
        dev.cycles = (dev.cycles or 0) + drawn / def.capacityKWh
    end
    entry.charge = entry.charge * (1 - Defs.SELF_DISCHARGE_PER_DAY * h / 24)
    entry.capacity = LiveWire.Batteries.capacity(dev, entry.cond)
    if entry.charge > entry.capacity then entry.charge = entry.capacity end
end

-- Public snapshot of a grid (primitive values only).
function Sim.snapshot(grid)
    local R = LiveWire.Registry
    local inv = R.device(grid.inverter)
    if not inv then return nil end
    local def = Defs.devices[inv.model] or {}
    local sources, batteries, options = R.members(grid)
    local snap = {
        grid = grid.id, rev = grid.rev or 0, name = grid.name or "",
        inverter = { id = inv.id, model = inv.model, state = inv.state,
                     cond = math.floor((inv.cond or 0) + 0.5), maxW = def.maxW or 0,
                     eff = inv.eff or 0, powered = grid.powered == true },
        demand = math.floor((grid.demand or 0) + 0.5),
        production = math.floor((grid.production or 0) + 0.5),
        stock = grid.stock or 0, capacity = grid.capacity or 0,
        lost = grid.lost or 0,
        sources = {}, batteries = {}, options = {},
    }
    for i = 1, #sources do
        local s = sources[i]
        snap.sources[i] = { id = s.id, model = s.model, cond = math.floor((s.cond or 0) + 0.5),
                            w = math.floor((s.pOut or 0) + 0.5),
                            raw = math.floor((s.raw or 0) + 0.5), snow = s.snow or 0 }
    end
    for i = 1, #batteries do
        local b = batteries[i]
        local cap = LiveWire.Batteries.capacity(b, b.cond or 0)
        snap.batteries[i] = { id = b.id, model = b.model, charge = b.charge or 0,
                              capacity = cap, cond = math.floor((b.cond or 0) + 0.5),
                              cycles = b.cycles or 0 }
    end
    for i = 1, #options do
        local o = options[i]
        snap.options[i] = { id = o.id, model = o.model, cond = math.floor((o.cond or 0) + 0.5) }
    end
    local need = (grid.demand or 0) + (def.idleW or 0) - (grid.production or 0) * (inv.eff or 0.85)
    if need > 0 and snap.stock > 0 then
        snap.autonomyH = snap.stock * 1000 * (inv.eff or 0.85) / need
    end
    return snap
end

function Sim.subscribe(player, gridId)
    local list = Sim.subscribers[gridId] or {}
    Sim.subscribers[gridId] = list
    list[player:getUsername()] = { player = player, expires = getTimestampMs() + Sim.SUBSCRIBE_MS }
end

function Sim.unsubscribe(player, gridId)
    local list = Sim.subscribers[gridId]
    if list then list[player:getUsername()] = nil end
end

function Sim.publish(grid)
    if not isServer() then return end
    local list = Sim.subscribers[grid.id]
    if not list then return end
    local inv = LiveWire.Registry.device(grid.inverter)
    local snap = nil
    local nowMs = getTimestampMs()
    for name, sub in pairs(list) do
        local p = sub.player
        local ok = p and not p:isDead() and sub.expires > nowMs and inv
        if ok then
            local dx, dy = p:getX() - inv.x, p:getY() - inv.y
            ok = dx * dx + dy * dy <= Sim.SUBSCRIBE_RANGE * Sim.SUBSCRIBE_RANGE
        end
        if ok then
            snap = snap or Sim.snapshot(grid)
            if snap then
                sendServerCommand(p, LiveWire.MODULE, LiveWire.Protocol.S_SNAPSHOT, snap)
            end
        else
            list[name] = nil
        end
    end
end

-- Apply the desired anchor state on this side and publish it to clients.
function Sim.updateAnchor(inv, on)
    local R = LiveWire.Registry
    local changed = R.setAnchor(inv, on)
    local a = R.anchors[inv.id]
    if a and (changed or LiveWire.Anchor.appliedState[inv.id] == nil) then
        LiveWire.Anchor.set(inv.id, a, on)
    end
end

function Sim.stepGrid(grid, now, w)
    local R = LiveWire.Registry
    local inv = R.device(grid.inverter)
    if not inv then
        R.grids()[grid.id] = nil
        return
    end
    local def = Defs.devices[inv.model]
    if not def then return end

    local dt = now - (grid.lastTick or now)
    grid.lastTick = now
    if dt <= 0 then return end
    if dt > Sim.MAX_CATCHUP_HOURS then dt = Sim.MAX_CATCHUP_HOURS end

    local invSq = getCell():getGridSquare(inv.x, inv.y, inv.z)
    local invObj = invSq and LiveWire.Marks.findOnSquare(invSq, inv.id)
    if invSq and not invObj then
        inv.missing = (inv.missing or 0) + 1
        if inv.missing >= 2 then
            LiveWire.log("inverter " .. inv.id .. " is gone from its square, removing it")
            Sim.updateAnchor(inv, false)
            R.removeDevice(inv.id)
        end
        return
    end
    inv.missing = nil
    local loaded = invObj ~= nil
    if not loaded and not LiveWire.Config.get("SimulateUnloaded") then return end

    if loaded then
        local d = LiveWire.Demand.measure(inv)
        if d then grid.demand = d end
    end
    local demandW = grid.demand or 0

    -- Sources and equipment removed by another path (admin, other mod): drop them after
    -- two consecutive checks of a loaded square.
    do
        local s0, _, o0 = R.members(grid)
        local all = {}
        for i = 1, #s0 do all[#all + 1] = s0[i] end
        for i = 1, #o0 do all[#all + 1] = o0[i] end
        for i = 1, #all do
            local dev = all[i]
            local sq = getCell():getGridSquare(dev.x, dev.y, dev.z)
            if sq and not LiveWire.Marks.findOnSquare(sq, dev.id) then
                dev.missing = (dev.missing or 0) + 1
                if dev.missing >= 2 then
                    LiveWire.log("device " .. dev.id .. " is gone from its square, removing it")
                    R.removeDevice(dev.id)
                end
            elseif sq then
                dev.missing = nil
            end
        end
    end

    local sources, batteryDevs = R.members(grid)
    local entries = {}
    for i = 1, #batteryDevs do
        local entry, wasRead = LiveWire.Batteries.read(batteryDevs[i])
        if entry then
            entries[#entries + 1] = entry
        elseif wasRead then
            LiveWire.Batteries.forget(batteryDevs[i], nil)
        end
    end

    local breaker = R.hasOption(grid, "breaker")
    local _, _, options = R.members(grid)
    local tod = getGameTime():getTimeOfDay()
    local n = math.max(1, math.ceil(dt / Sim.SUBSTEP_HOURS - 1e-9))
    local h = dt / n
    local totalLost = 0
    local prodW = 0

    for i = 1, n do
        local t0 = (tod - dt + (i - 1) * h) % 24
        if t0 < 0 then t0 = t0 + 24 end
        prodW = 0
        for s = 1, #sources do
            local src = sources[s]
            local sdef = Defs.devices[src.model]
            if sdef then
                weatherOnSource(src, sdef, w, h)
                src.raw = sourceRaw(src, sdef, w, t0, h)
                src.pOut = Physics.smooth(src.pOut, src.raw, h, Defs.SMOOTHING_TAU_HOURS)
                prodW = prodW + src.pOut
                wearDevice(src, sdef, h)
            end
        end

        local before = {}
        for e = 1, #entries do before[e] = entries[e].charge end

        if inv.state == "on" and (inv.cond or 0) <= 0 then inv.state = "broken" end
        local r = Physics.stepGrid({
            productionW = prodW, demandW = demandW, idleW = def.idleW, maxW = def.maxW,
            eff = inv.eff, dt = h, wasOn = grid.powered == true, state = inv.state,
            batteries = entries,
        })
        totalLost = totalLost + r.lostKWh

        if r.tripped then
            inv.state = "tripped"
            if not breaker then
                inv.cond = math.max(0, (inv.cond or 100) - Defs.TRIP_CONDITION_LOSS)
            end
            LiveWire.notifyNear(inv.x, inv.y, inv.z, Sim.SUBSCRIBE_RANGE, "IGUI_LW_Tripped", {}, true)
        end
        grid.powered = r.on

        for e = 1, #entries do
            local drawn = before[e] - entries[e].charge
            batteryWear(entries[e], drawn, h)
        end

        if r.on then
            local heavy = 1
            if demandW > def.maxW * Defs.HEAVY_LOAD_RATIO then heavy = 2 end
            wearDevice(inv, def, h, heavy)
            if (inv.cond or 0) <= 0 then
                inv.state = "broken"
                grid.powered = false
                LiveWire.notifyNear(inv.x, inv.y, inv.z, Sim.SUBSCRIBE_RANGE, "IGUI_LW_Broken", {}, true)
            end
        end
        for o = 1, #options do
            local odef = Defs.devices[options[o].model]
            if odef then wearDevice(options[o], odef, h) end
        end
    end

    local stock, capacity = 0, 0
    for e = 1, #entries do
        LiveWire.Batteries.write(entries[e])
        stock = stock + entries[e].charge
        capacity = capacity + entries[e].capacity
    end
    grid.production = prodW
    grid.stock = stock
    grid.capacity = capacity
    grid.lost = totalLost
    grid.rev = (grid.rev or 0) + 1

    local on = grid.powered == true and inv.state == "on"
    Sim.updateAnchor(inv, on)

    local radius = LiveWire.Config.get("InverterNoiseRadius")
    if on and loaded and radius > 0 then
        addSound(nil, inv.x, inv.y, inv.z, radius, 1)
    end
    Sim.publish(grid)
end

function Sim.tick()
    local R = LiveWire.Registry
    if not R or not R.ready or R.readOnly then return end
    local now = getGameTime():getWorldAgeHours()
    local w = weather()
    local ids = {}
    for id in pairs(R.grids()) do ids[#ids + 1] = id end
    table.sort(ids)
    for i = 1, #ids do
        local grid = R.grid(ids[i])
        if grid then
            local ok, err = pcall(Sim.stepGrid, grid, now, w)
            if not ok then LiveWire.warn("step failed for " .. ids[i] .. ": " .. tostring(err)) end
        end
    end
end

-- Run one step right now for one grid (after an action changed it).
function Sim.refresh(grid)
    if not grid then return end
    local now = getGameTime():getWorldAgeHours()
    -- A one-minute step re-evaluates the state without skipping the next tick.
    if not grid.lastTick or grid.lastTick > now - 1 / 60 then grid.lastTick = now - 1 / 60 end
    local ok, err = pcall(Sim.stepGrid, grid, now, weather())
    if not ok then LiveWire.warn("refresh failed for " .. grid.id .. ": " .. tostring(err)) end
end

Events.EveryTenMinutes.Add(Sim.tick)
