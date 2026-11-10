-- Live Wire: simulation step of every network (authority only), every 10 game
-- minutes, whether players are near or not (docs/architecture.md section 4).
if isClient() then return end
require "LiveWire/LW_Events"
require "LiveWire/LW_Forecast"
require "LiveWire/LW_Inverters"

LiveWire = LiveWire or {}

local Sim = {}
LiveWire.Sim = Sim

local Defs = LiveWire.Defs
local Physics = LiveWire.Physics
local Inverters = LiveWire.Inverters

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
        rain = cm:getRainIntensity(),
        month = getGameTime():getMonth(),
        dawn = season:getDawn(),
        dusk = season:getDusk(),
    }
end

Sim.weather = weather

-- Mean of the solar curve over the time-of-day interval [t0, t0 + h], with wrap.
local function solarMean(t0, h, w)
    local t1 = t0 + h
    if t1 <= 24 then return Physics.solarCurveMean(t0, t1, w.dawn, w.dusk) end
    local a = Physics.solarCurveMean(t0, 24, w.dawn, w.dusk) * (24 - t0)
    local b = Physics.solarCurveMean(0, t1 - 24, w.dawn, w.dusk) * (t1 - 24)
    return (a + b) / h
end

-- World hour after which the public grid is off (vanilla doesPowerGridExist,
-- SandboxOptions.java:1230: world age in days <= ElecShutModifier).
function Sim.gridShutHour()
    local opts = getSandboxOptions and getSandboxOptions()
    if not opts then return -1 end
    return opts:getElecShutModifier() * 24
end

local function chance(probability)
    return ZombRandFloat(0, 1) < probability
end

-- Behaviour of each source kind (D-50); a new kind is one entry here and one in Defs.SOURCE_FIELDS.
--   raw(src, def, w, t0, h)  production factor before nominal power, condition and efficiency
--   weather(src, def, w, h)  ageing by the weather (snow, dirt), every step
--   storm(src, def, w, h)    storm damage, only with the StormDamage option
--   brakable                 the player can brake it: a braked source produces nothing
Sim.sourceKinds = {
    solar = {
        raw = function(src, _def, w, t0, h)
            local facing, shift = Physics.solarFacing(src.facing, LiveWire.Config.get("SolarOrientation"))
            local sw = { dawn = w.dawn + shift, dusk = w.dusk + shift }
            return Physics.solarFactor(solarMean(t0, h, sw), w.clouds, src.snow or 0)
                * LiveWire.Config.get("SolarMultiplier") * facing
                * (1 - (LiveWire.Config.get("SolarDirt") and (src.dirt or 0) or 0))
        end,
        weather = function(src, _def, w, h)
            local snow = src.snow or 0
            if w.snowing then snow = snow + Defs.SNOW_ACCUMULATION_PER_HOUR * w.snowIntensity * h end
            if w.temperature > 0 then snow = snow - Defs.SNOW_MELT_PER_HOUR * h end
            src.snow = LiveWire.clamp(snow, 0, 1)
            if LiveWire.Config.get("SolarDirt") then
                local autumn = w.month >= Defs.DIRT_AUTUMN_FIRST_MONTH and w.month <= Defs.DIRT_AUTUMN_LAST_MONTH
                src.dirt = LiveWire.clamp((src.dirt or 0)
                    + h * (autumn and Defs.DIRT_PER_HOUR_AUTUMN or Defs.DIRT_PER_HOUR)
                    - (w.rain or 0) * h * Defs.DIRT_RAIN_WASH, 0, Defs.DIRT_MAX)
            end
        end,
        storm = function(src, _def, w, h)
            if w.storm and chance(h / Defs.SOLAR_STORM_HOURS) then
                src.cond = math.max(0, (src.cond or 100) - Defs.SOLAR_STORM_LOSS)
            end
        end,
    },
    wind = {
        brakable = true,
        raw = function(src, _def, w)
            return Physics.windFactor(Physics.windAtHeight(w.windKph, src.z))
                * LiveWire.Config.get("WindMultiplier")
        end,
        storm = function(src, _def, w, h)
            if Physics.windAtHeight(w.windKph, src.z) > Physics.WIND_CUT_OUT
                and not src.brake and chance(h / Defs.WIND_STORM_HOURS) then
                src.cond = math.max(0, (src.cond or 100)
                    - ZombRand(Defs.WIND_STORM_LOSS_MIN, Defs.WIND_STORM_LOSS_MAX))
            end
        end,
    },
    hydro = {
        raw = function(_src, _def, w)
            return Physics.hydroFactor(w.month) * LiveWire.Config.get("HydroMultiplier")
        end,
    },
}

-- True when `src` is a brakable source whose brake is set.
local function braked(src, def)
    local kind = Sim.sourceKinds[def.kind]
    return kind ~= nil and kind.brakable == true and src.brake == true
end

local function sourceRaw(src, def, w, t0, h)
    if (src.cond or 0) <= 0 then return 0 end
    if braked(src, def) then return 0 end
    local kind = Sim.sourceKinds[def.kind]
    local factor = kind and kind.raw(src, def, w, t0, h) or 0
    return def.nominalW * factor * Physics.conditionFactor(src.cond) * (src.eff or 0.85)
end
Sim.sourceRaw = sourceRaw

local function wearDevice(dev, def, h, extra)
    local mult = LiveWire.Config.get("DeviceWearMultiplier")
    if mult <= 0 or not def.wearDays then return end
    local loss = h / (def.wearDays * 24) * mult * (extra or 1)
        * Defs.deviceWearSkillFactor(dev.level or 0)
    dev.cond = math.max(0, (dev.cond or 100) - loss)
end

local function weatherOnSource(src, def, w, h)
    local kind = Sim.sourceKinds[def.kind]
    if not kind then return end
    if kind.weather then kind.weather(src, def, w, h) end
    if kind.storm and LiveWire.Config.get("StormDamage") then kind.storm(src, def, w, h) end
end

local function batteryWear(entry, drawn, h, exhausted)
    local def = LiveWire.Batteries.def(entry.model)
    if not def then return end
    if drawn > 0 then
        local deep = exhausted or (entry.capacity > 0
            and entry.charge / entry.capacity < Defs.DEEP_DISCHARGE_THRESHOLD)
        local wear = Physics.batteryWear(drawn, def.capacityKWh, def.lifeCycles, deep,
            LiveWire.Config.get("BatteryWearMultiplier") * (entry.wearFactor or 1))
        entry.cond = math.max(0, entry.cond - wear)
        entry.cycles = (entry.cycles or 0) + drawn / def.capacityKWh
    end
    local decay = 1 - Defs.SELF_DISCHARGE_PER_DAY * h / 24
    entry.charge = entry.charge * decay
    entry.reserve = (entry.reserve or 0) * decay
    entry.warmCapacity = LiveWire.Batteries.capacity(entry.model, entry.cond)
    entry.capacity = entry.warmCapacity * (entry.coldFactor or 1)
    entry.reserve = math.min(entry.reserve, math.max(0, entry.warmCapacity - entry.capacity))
    if entry.charge > entry.capacity then entry.charge = entry.capacity end
end

-- Stock and capacity summed over battery entries.
local function sumStock(entries)
    local stock, capacity = 0, 0
    for e = 1, #entries do
        stock = stock + entries[e].charge
        capacity = capacity + entries[e].capacity
    end
    return stock, capacity
end

-- Battery stock as a fraction of the capacity, nil without any capacity.
local function stockFraction(entries)
    local stock, capacity = sumStock(entries)
    if capacity <= 0 then return nil end
    return stock / capacity
end

-- The inverter fleet rules (capacity, idle use) live in LW_Inverters.lua (D-48).

-- Public snapshot of a grid (primitive values only).
function Sim.snapshot(grid)
    local R = LiveWire.Registry
    local inv = R.device(grid.inverter)
    if not inv then return nil end
    local members = R.members(grid)
    local sources, batteries, options = members.source, members.storage, members.option
    local backups, computers, pumps = members.backup, members.computer, members.pump
    local snap = {
        grid = grid.id, rev = grid.rev or 0, name = grid.name or "",
        inverter = { id = inv.id, model = inv.model, state = inv.state,
                     cond = math.floor((inv.cond or 0) + 0.5), maxW = Inverters.capacityW(grid),
                     eff = inv.eff or 0, powered = grid.powered == true, muffled = inv.muffled == true },
        demand = math.floor((grid.demand or 0) + 0.5),
        demandReady = LiveWire.Demand.ready(inv),
        production = math.floor((grid.production or 0) + 0.5),
        stock = grid.stock or 0, capacity = grid.capacity or 0,
        lost = grid.lost or 0,
        gridW = grid.gridW and math.floor(grid.gridW + 0.5) or nil,
        sources = {}, batteries = {}, options = {}, appliances = {},
        coverage = { radius = LiveWire.Config.tileRange(), floors = LiveWire.Config.verticalRange() },
    }
    snap.events = {}
    for _, e in ipairs(grid.events or {}) do
        local args = {}
        for i, v in ipairs(e.args) do args[i] = v end
        snap.events[#snap.events + 1] = { t = e.t, tod = e.tod, key = e.key, args = args }
    end
    snap.consumers = LiveWire.Demand.consumers and LiveWire.Demand.consumers(inv) or {}
    snap.links = {}
    for id in pairs(grid.members) do
        local d = R.device(id)
        if d then snap.links[#snap.links + 1] = { id = id, model = d.model, role = d.role, x = d.x, y = d.y, z = d.z } end
    end
    snap.origin = { x = inv.x, y = inv.y, z = inv.z }
    for cat, b in pairs(grid.appliances or {}) do
        snap.appliances[#snap.appliances + 1] = { cat = cat, n = b.n, w = math.floor(b.w + 0.5) }
    end
    table.sort(snap.appliances, function(a, b) return a.w > b.w end)
    for i = 1, #sources do
        local s = sources[i]
        local sdef = Defs.devices[s.model] or {}
        local row = { id = s.id, model = s.model, kind = sdef.kind or "other",
                      nominal = sdef.nominalW or 0, cond = math.floor((s.cond or 0) + 0.5),
                      w = math.floor((s.pOut or 0) + 0.5),
                      raw = math.floor((s.raw or 0) + 0.5), facing = s.facing or 0 }
        for _, f in ipairs(Defs.SOURCE_FIELDS[sdef.kind] or {}) do
            if not f.flag then row[f.field] = s[f.field] or f.default end
        end
        snap.sources[i] = row
    end
    snap.extra = 0
    for i = 1, #batteries do
        local bank = batteries[i]
        snap.extra = snap.extra + (bank.extra or 0)
        for _, sl in ipairs(bank.slots or {}) do
            local e = LiveWire.Batteries.entry(bank, sl.model, sl.id, sl.cond or 0, sl.charge or 0, sl.cycles)
            snap.batteries[#snap.batteries + 1] = { model = sl.model,
                charge = e.capacity > 0 and e.charge / e.capacity or 0,
                capacity = e.capacity, reserve = e.reserve,
                cond = math.floor((sl.cond or 0) + 0.5), cycles = sl.cycles or 0 }
        end
    end
    snap.banks = #batteries
    for i = 1, #options do
        local o = options[i]
        snap.options[i] = { id = o.id, model = o.model, cond = math.floor((o.cond or 0) + 0.5),
                            state = o.state or "ok" }
    end
    local slaves = R.slaves(grid)
    -- Positions of the network's inverters (master first): the inverter screen stays open
    -- near any of them, and LiveWire.API.networkInverters reads them on a client.
    snap.network = { { id = inv.id, x = inv.x, y = inv.y, z = inv.z, master = true } }
    for i = 1, #slaves do
        local sl = slaves[i]
        snap.network[i + 1] = { id = sl.id, x = sl.x, y = sl.y, z = sl.z, master = false }
    end
    if #slaves > 0 then
        local inService = Inverters.inService(grid)
        snap.coupled = { n = inService, total = 1 + #slaves }
    end
    local need = (grid.demand or 0) + Inverters.idleW(grid) - (grid.production or 0) * (inv.eff or 0.85)
    if need > 0 and snap.stock > 0 then
        snap.autonomyH = snap.stock * 1000 * (inv.eff or 0.85) / need
    end
    local b = backups[1]
    if b then
        local start, stop = LiveWire.Backup.thresholds()
        snap.backup = { id = b.id, state = b.state or "standby", fuel = b.fuel or 0, maxFuel = Defs.BACKUP_MAX_FUEL,
                        w = math.floor((grid.backupW or 0) + 0.5),
                        start = start * 100, stop = stop * 100 }
    end
    local c = computers[1]
    if c then
        local on = grid.computerOn == true
        snap.computer = { id = c.id, powered = on }
        if on then
            snap.history = {}
            for i, hs in ipairs(grid.history or {}) do snap.history[i] = { p = hs.p, d = hs.d, s = hs.s } end
            snap.dawnH = LiveWire.Computer.hoursToDawn()
            snap.forecast = {}
            for i, row in ipairs(grid.forecast or {}) do
                local r = {}
                for key, value in pairs(row) do r[key] = value end
                snap.forecast[i] = r
            end
        end
    end
    if R.hasOption(grid, "alarm") then
        snap.alarm = { on = grid.alarmOn == true, ack = grid.alarmAck == true }
    end
    local brk = R.hasOption(grid, "breaker")
    if brk then snap.breaker = { id = brk.id, state = brk.state or "ok",
        lightsOff = grid.lightsOff == true, equipmentOff = grid.equipmentOff == true,
        mainOff = grid.mainOff == true, equipmentControl = true } end
    if #pumps > 0 then
        -- Pumps in service and their flow (the only pump figures the software shows),
        -- from the last measured flow; never demandW (it consumes the litres counter).
        snap.pumps = LiveWire.Pump.summary(pumps)
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
    if list then
        list[player:getUsername()] = nil
        for _ in pairs(list) do return end
        Sim.subscribers[gridId] = nil
    end
end

function Sim.purgeSubscribers()
    local R = LiveWire.Registry
    if not R or not R.ready then return end
    local now, online = getTimestampMs(), nil
    local players = isServer() and getOnlinePlayers()
    if players then
        online = {}
        for i = 0, players:size() - 1 do
            local p = players:get(i)
            online[p:getUsername()] = p
        end
    end
    for id, list in pairs(Sim.subscribers) do
        if not R.grid(id) then Sim.subscribers[id] = nil
        else
            local any = false
            for name, sub in pairs(list) do
                if sub.expires <= now or not sub.player or sub.player:isDead()
                    or (online and online[name] ~= sub.player) then list[name] = nil
                else any = true end
            end
            if not any then Sim.subscribers[id] = nil end
        end
    end
end

function Sim.publish(grid)
    if not isServer() then return end
    local list = Sim.subscribers[grid.id]
    if not list then return end
    local inv = LiveWire.Registry.device(grid.inverter)
    local snap = nil
    local nowMs = getTimestampMs()
    local r2 = Sim.SUBSCRIBE_RANGE * Sim.SUBSCRIBE_RANGE
    -- With a coupling add-on, a coupled inverter opens its master's screen and may
    -- stand past the cable range (D-45): standing near it counts as near the master.
    local near = LiveWire.Coupling.active() and LiveWire.Registry.slaves(grid) or {}
    near[#near + 1] = inv
    for name, sub in pairs(list) do
        local p = sub.player
        local ok = p and not p:isDead() and sub.expires > nowMs and inv
        if ok then
            ok = false
            for i = 1, #near do
                local dx, dy = p:getX() - near[i].x, p:getY() - near[i].y
                if dx * dx + dy * dy <= r2 then ok = true break end
            end
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

-- A slave with no condition left breaks like the master (see the step below).
local function breakSlave(sl)
    sl.state = "broken"
    LiveWire.notifyNear(sl.x, sl.y, sl.z, Sim.SUBSCRIBE_RANGE, "IGUI_LW_Broken", {}, true)
end

-- Wear multiplier of an inverter (master or slave) under the current load: doubled
-- above the heavy-load ratio of the capacity, raised again by its own muffler.
local function loadWearFactor(unit, demandW, capW)
    local factor = 1
    if demandW > capW * Defs.HEAVY_LOAD_RATIO then factor = 2 end
    if unit.muffled then factor = factor * Defs.MUFFLED_WEAR end
    return factor
end

-- Step context: one table per Sim.stepGrid call. Fields set by the steps below:
-- R, grid, now, w, inv, def, dt, loaded, gridShutH (resolveInverter); demandW (measureDemand,
-- addPumpDemand); sources, banks, options, backups, computers, pumps (collectMembers);
-- slaves, entries, bankEntries (readBatteries); breaker, tod, n, h (planSubsteps);
-- prodW, backupW, totalLost, gridKWh (sub-steps); on (updateAnchors).

-- A grid whose inverter record is gone is dropped with its members.
local function dropLostGrid(R, grid)
    LiveWire.warn("grid " .. tostring(grid.id) .. " lost its inverter, dropping it")
    local left = {}
    for id in pairs(grid.members) do left[#left + 1] = id end
    for _, sl in ipairs(R.slaves(grid)) do left[#left + 1] = sl.id end
    R.dropGrid(grid)
    for i = 1, #left do LiveWire.Devices.syncMark(R.device(left[i])) end
end

-- The inverter, the time to simulate and the public grid state. Returns the step
-- context, or nil when this step must not run.
local function resolveInverter(grid, now, w, evaluate)
    local R = LiveWire.Registry
    local inv = R.device(grid.inverter)
    if not inv then
        dropLostGrid(R, grid)
        return nil
    end
    local def = Defs.devices[inv.model]
    if not def then return nil end

    local dt = now - (grid.lastTick or now)
    grid.lastTick = now
    if dt <= 0 then
        if not evaluate then return nil end
        dt = 0
    end
    if dt > Sim.MAX_CATCHUP_HOURS then dt = Sim.MAX_CATCHUP_HOURS end

    -- A missing inverter is counted and removed by Devices.validate (Sim.tick).
    local invSq = getCell():getGridSquare(inv.x, inv.y, inv.z)
    local invObj = invSq and LiveWire.Devices.find(inv)
    if invSq and not invObj then return nil end
    local loaded = invObj ~= nil
    if not loaded and not LiveWire.Config.get("SimulateUnloaded") then return nil end

    -- Public grid charging: the inverter must stand in a building the grid serves,
    -- as vanilla appliances (IsoObject.java:5716). The site is remembered for the
    -- steps run while its square is unloaded.
    if invSq then inv.gridSite = (invSq:getRoom() ~= nil and not invSq:isNoPower()) or nil end
    local gridShutH = -math.huge
    if inv.gridSite and LiveWire.Config.get("GridCharging") then gridShutH = Sim.gridShutHour() end

    return { R = R, grid = grid, now = now, w = w, inv = inv, def = def, dt = dt, loaded = loaded,
             gridShutH = gridShutH, demandW = 0, prodW = 0, backupW = 0, totalLost = 0, gridKWh = 0 }
end

local function measureDemand(ctx)
    if ctx.loaded then
        local d, breakdown = LiveWire.Demand.measureGrid(ctx.grid, ctx.inv)
        if d then
            ctx.grid.demand = d
            ctx.grid.appliances = breakdown
        end
    end
    ctx.demandW = ctx.grid.demand or 0
end

-- Live Wire devices removed by another path (admin, other mod) are dropped by
-- Devices.validate (Sim.tick). Linked vanilla objects (generator, computer) are
-- found by their own ModData: drop them after two consecutive checks.
local function syncLinkedVanilla(ctx)
    local R = ctx.R
    local vanillaMembers = R.members(ctx.grid)
    local bk0, pc0 = vanillaMembers.backup, vanillaMembers.computer
    local vanilla = {}
    for i = 1, #bk0 do vanilla[#vanilla + 1] = { dev = bk0[i], mod = LiveWire.Backup } end
    for i = 1, #pc0 do vanilla[#vanilla + 1] = { dev = pc0[i], mod = LiveWire.Computer } end
    for i = 1, #vanilla do
        local dev = vanilla[i].dev
        local obj, here = vanilla[i].mod.find(dev)
        if here and not obj then
            dev.missing = (dev.missing or 0) + 1
            if dev.missing >= 2 then
                LiveWire.log("linked object " .. dev.id .. " is gone from its square, removing it")
                R.forgetVanilla(dev)
            end
        elseif here then
            dev.missing = nil
        end
    end
end

-- Members of the grid by role, read again after syncLinkedVanilla (it can drop some).
local function collectMembers(ctx)
    local members = ctx.R.members(ctx.grid)
    ctx.sources, ctx.banks, ctx.options = members.source, members.storage, members.option
    ctx.backups, ctx.computers, ctx.pumps = members.backup, members.computer, members.pump
end

-- Once per storm: warn the players near a grid that has a wind turbine still unbraked.
local function warnStorm(ctx)
    local grid, inv, w = ctx.grid, ctx.inv, ctx.w
    if w.storm and not grid.stormWarned then
        for _, src in ipairs(ctx.sources) do
            local sd = Defs.devices[src.model]
            local brakable = sd and Sim.sourceKinds[sd.kind] and Sim.sourceKinds[sd.kind].brakable
            if brakable and not src.brake and (src.cond or 0) > 0 then
                grid.stormWarned = true
                LiveWire.notifyNear(inv.x, inv.y, inv.z, Sim.SUBSCRIBE_RANGE, "IGUI_LW_StormBrake",
                    { grid.name ~= "" and grid.name or "IGUI_LW_Network" }, true)
                LiveWire.Journal.add(grid, "IGUI_LW_Event_Storm")
                break
            end
        end
    elseif not w.storm then grid.stormWarned = nil end
end

-- The slave inverters and every battery entry of the banks (written back by settleGrid).
local function readBatteries(ctx)
    ctx.slaves = ctx.R.slaves(ctx.grid)
    local entries, bankEntries = {}, {}
    for i = 1, #ctx.banks do
        local list = LiveWire.Batteries.read(ctx.banks[i])
        bankEntries[i] = list
        for j = 1, #list do entries[#entries + 1] = list[j] end
    end
    ctx.entries, ctx.bankEntries = entries, bankEntries
end

-- Water pumps draw power while they move water (LW_Pump.lua); the breaker and
-- the heavy-load test count them with the house demand.
-- A zero-length step keeps the last measured pump power: demandW consumes the
-- litres counter and divides by the elapsed time.
local function addPumpDemand(ctx)
    local grid = ctx.grid
    local pumpW = grid.pumpW or 0
    if ctx.dt > 0 then
        pumpW = LiveWire.Pump and LiveWire.Pump.demandW(ctx.pumps, ctx.dt) or 0
        grid.pumpW = pumpW
    end
    ctx.demandW = ctx.demandW + pumpW
end

-- Number and length of the sub-steps.
local function planSubsteps(ctx)
    ctx.breaker = ctx.R.hasOption(ctx.grid, "breaker")
    ctx.tod = getGameTime():getTimeOfDay()
    ctx.n = math.max(1, math.ceil(ctx.dt / Sim.SUBSTEP_HOURS - 1e-9))
    ctx.h = ctx.dt / ctx.n
end

-- Weather, raw and smoothed output and wear of every source for one sub-step.
local function produce(ctx, t0)
    local w, h = ctx.w, ctx.h
    local prodW = 0
    for s = 1, #ctx.sources do
        local src = ctx.sources[s]
        local sdef = Defs.devices[src.model]
        if sdef then
            weatherOnSource(src, sdef, w, h)
            src.raw = sourceRaw(src, sdef, w, t0, h)
            src.pOut = Physics.smooth(src.pOut, src.raw, h, Defs.SMOOTHING_TAU_HOURS)
            if braked(src, sdef) then src.pOut = 0 end
            prodW = prodW + src.pOut
            wearDevice(src, sdef, h)
        end
    end
    ctx.prodW = prodW
end

-- Backup generator: started under BackupStartPercent, stopped at
-- BackupStopPercent; only through a working inverter.
local function runBackup(ctx)
    local backupW = 0
    local frac = nil
    if ctx.inv.state == "on" and (ctx.inv.cond or 0) > 0 then frac = stockFraction(ctx.entries) end
    for b = 1, #ctx.backups do backupW = backupW + LiveWire.Backup.step(ctx.backups[b], frac, ctx.h) end
    ctx.backupW = backupW
end

-- Charge of every battery entry before the physics step, and the total.
local function chargesOf(entries)
    local before = {}
    local beforeStock = 0
    for e = 1, #entries do
        before[e] = entries[e].charge
        beforeStock = beforeStock + before[e]
    end
    return before, beforeStock
end

-- Inverter state, capacity and idle use, then the physics step of one sub-step.
-- Returns the physics result and the capacity used.
local function runPhysics(ctx, i)
    local grid, inv, breaker, h = ctx.grid, ctx.inv, ctx.breaker, ctx.h
    if inv.state == "on" and (inv.cond or 0) <= 0 then inv.state = "broken" end
    -- Capacity and idle use are taken again at each sub-step: slaves can break.
    for s = 1, #ctx.slaves do
        if ctx.slaves[s].state == "on" and (ctx.slaves[s].cond or 0) <= 0 then breakSlave(ctx.slaves[s]) end
    end
    local capW, idleNow = Inverters.capacityW(grid), Inverters.idleW(grid)
    local gridW = 0
    if ctx.now - ctx.dt + (i - 0.5) * h <= ctx.gridShutH then gridW = capW * Defs.GRID_CHARGE_RATIO end
    -- A tripped breaker cuts the house: the inverter stays on (it still charges).
    local physState = inv.state
    -- Isolating a failed unit changes its switch, never repairs its converter.
    if (inv.cond or 0) <= 0 then physState = "broken" end
    if physState == "on" and (grid.mainOff or (breaker and breaker.state == "tripped")) then physState = "tripped" end
    local r = Physics.stepGrid({
        productionW = ctx.prodW + ctx.backupW, demandW = ctx.demandW, idleW = idleNow, maxW = capW,
        eff = inv.eff, dt = h, wasOn = grid.powered == true, state = physState,
        batteries = ctx.entries, gridW = gridW,
    })
    ctx.totalLost = ctx.totalLost + r.lostKWh
    ctx.gridKWh = ctx.gridKWh + r.gridKWh
    return r, capW
end

-- An overload trips the breaker when there is one (the inverter is not damaged),
-- otherwise the inverter.
local function tripOverload(ctx, r, capW)
    if not r.tripped then return end
    local inv, breaker = ctx.inv, ctx.breaker
    local args = { tostring(math.floor(ctx.demandW + 0.5)), tostring(capW) }
    if breaker then
        -- The breaker trips before the inverter, which is not damaged.
        breaker.state = "tripped"
        LiveWire.notifyNear(inv.x, inv.y, inv.z, Sim.SUBSCRIBE_RANGE, "IGUI_LW_BreakerTripped", args, true)
    else
        inv.state = "tripped"
        inv.cond = math.max(0, (inv.cond or 100) - Defs.TRIP_CONDITION_LOSS)
        LiveWire.notifyNear(inv.x, inv.y, inv.z, Sim.SUBSCRIBE_RANGE, "IGUI_LW_Tripped", args, true)
    end
end

-- Power state, journal and power history of one sub-step. Returns the start hour.
local function recordPower(ctx, r, i)
    local grid, inv, R, h = ctx.grid, ctx.inv, ctx.R, ctx.h
    local wasPowered = grid.powered == true
    grid.powered = r.on
    -- Intermediate catch-up transitions are private. Publish only the final
    -- state below, avoiding a burst of global anchor packets after an absence.
    local startHour = ctx.now - ctx.dt + (i - 1) * h
    -- A zero-length step serves no hours: its end state is the served state.
    local served = r.onHours > 0 or (h <= 0 and r.on)
    if served and not wasPowered then
        LiveWire.Journal.add(grid, "IGUI_LW_Event_PowerOn", {}, startHour)
    end
    if not r.on and (wasPowered or r.onHours > 0) then
        LiveWire.Journal.add(grid, "IGUI_LW_Event_PowerOff", {}, startHour + r.onHours)
    end
    LiveWire.PowerHistory.record(R.data, inv, served, startHour)
    if not r.on then
        LiveWire.PowerHistory.record(R.data, inv, false, startHour + r.onHours)
    end
    return startHour
end

local function wearBatteries(ctx, r, before, beforeStock)
    local entries = ctx.entries
    for e = 1, #entries do
        -- A partial step may discharge, then recharge from the unused
        -- production. Wear counts the actual proportional discharge, not net
        -- stock loss after that recharge.
        local drawn = beforeStock > 0 and r.drawnKWh * before[e] / beforeStock or 0
        batteryWear(entries[e], drawn, ctx.h, not r.on and r.onHours > 0)
    end
end

-- Wear of the inverters, the options and the running pumps for one sub-step.
local function wearInService(ctx, r, capW, startHour)
    local grid, inv, h, demandW = ctx.grid, ctx.inv, ctx.h, ctx.demandW
    if r.onHours > 0 then
        wearDevice(inv, ctx.def, r.onHours, loadWearFactor(inv, demandW, capW))
        -- Slaves in service wear with the same load, their own muffler included.
        for s = 1, #ctx.slaves do
            local sl = ctx.slaves[s]
            if Inverters.slaveInService(sl) then
                -- Each slave wears by its own model (inverter and cabinet can be coupled).
                wearDevice(sl, Inverters.def(sl), r.onHours, loadWearFactor(sl, demandW, capW))
                if (sl.cond or 0) <= 0 then breakSlave(sl) end
            end
        end
        if (inv.cond or 0) <= 0 then
            inv.state = "broken"
            grid.powered = false
            LiveWire.notifyNear(inv.x, inv.y, inv.z, Sim.SUBSCRIBE_RANGE, "IGUI_LW_Broken", {}, true)
        end
    end
    if inv.state ~= "on" then
        LiveWire.PowerHistory.record(ctx.R.data, inv, false, startHour + h)
    end
    for o = 1, #ctx.options do
        local odef = Defs.devices[ctx.options[o].model]
        if odef then wearDevice(ctx.options[o], odef, h) end
    end
    -- Pump wear is applied per step to the running pumps only (approximation:
    -- the duty of this step is not known here).
    for p = 1, #ctx.pumps do
        local pdef = Defs.devices[ctx.pumps[p].model]
        if pdef and ctx.pumps[p].state == "running" then wearDevice(ctx.pumps[p], pdef, h) end
    end
end

-- One sub-step (i-th of ctx.n): production, backup, physics, journal, wear.
local function stepSubstep(ctx, i)
    local t0 = (ctx.tod - ctx.dt + (i - 1) * ctx.h) % 24
    if t0 < 0 then t0 = t0 + 24 end
    produce(ctx, t0)
    runBackup(ctx)
    local before, beforeStock = chargesOf(ctx.entries)
    local r, capW = runPhysics(ctx, i)
    tripOverload(ctx, r, capW)
    local startHour = recordPower(ctx, r, i)
    wearBatteries(ctx, r, before, beforeStock)
    wearInService(ctx, r, capW, startHour)
end

-- Write the batteries back and store the totals of the step on the grid.
local function settleGrid(ctx)
    local grid = ctx.grid
    for i = 1, #ctx.banks do LiveWire.Batteries.write(ctx.banks[i], ctx.bankEntries[i]) end
    local stock, capacity = sumStock(ctx.entries)
    grid.production = ctx.prodW + ctx.backupW
    grid.backupW = ctx.backupW
    grid.stock = stock
    grid.capacity = capacity
    grid.lost = ctx.totalLost
    -- Mean public grid draw of the step (a zero-length step keeps the last value);
    -- nil when this inverter cannot use the grid (option off, outside a building).
    if ctx.gridShutH == -math.huge then
        grid.gridW = nil
    elseif ctx.dt > 0 then
        grid.gridW = ctx.gridKWh * 1000 / ctx.dt
    end
    grid.rev = (grid.rev or 0) + 1
end

-- Anchor (powered zone) of the inverter and of the slaves that keep their own zone.
local function updateAnchors(ctx)
    local inv = ctx.inv
    local on = ctx.grid.powered == true and inv.state == "on"
    ctx.on = on
    Sim.updateAnchor(inv, on)
    -- Coupled inverters that keep their own zone (D-45) follow the master's power.
    if LiveWire.Coupling.slaveKeepsZone() then
        for i = 1, #ctx.slaves do
            local sl = ctx.slaves[i]
            Sim.updateAnchor(sl, on and Inverters.slaveInService(sl))
        end
    end
end

-- Management computer (history, forecast, load shedding) and low battery alarm.
local function runManagement(ctx)
    local grid, inv = ctx.grid, ctx.inv
    local frac = stockFraction(ctx.entries)
    local pc = nil
    for c = 1, #ctx.computers do
        if LiveWire.Computer.powered(ctx.computers[c], grid) then pc = ctx.computers[c] break end
    end
    grid.computerOn = pc ~= nil
    if pc then
        LiveWire.Computer.record(grid, ctx.now, grid.production, ctx.demandW, frac)
        LiveWire.Forecast.build(grid, ctx.sources, ctx.now)
        if ctx.loaded then LiveWire.Computer.shed(grid, inv, pc, frac) end
    end
    LiveWire.Alarm.check(grid, ctx.R.hasOption(grid, "alarm"), frac, ctx.now)
end

-- The running inverter, and each slave in service, are heard by zombies.
local function makeNoise(ctx)
    local inv = ctx.inv
    local radius = LiveWire.Config.get("InverterNoiseRadius")
    if ctx.on and ctx.loaded and radius > 0 and not inv.muffled then
        addSound(nil, inv.x, inv.y, inv.z, radius, 1)
    end
    -- Each slave in service hums at its own position (loaded squares only).
    if ctx.on and radius > 0 then
        for s = 1, #ctx.slaves do
            local sl = ctx.slaves[s]
            if Inverters.slaveInService(sl) and not sl.muffled
                and getCell():getGridSquare(sl.x, sl.y, sl.z) then
                addSound(nil, sl.x, sl.y, sl.z, radius, 1)
            end
        end
    end
end

-- Relays of the pumps follow the linked barrels and fixtures (loaded squares only).
local function maintainPumps(ctx)
    if not LiveWire.Pump then return end
    for p = 1, #ctx.pumps do
        local ok, err = pcall(LiveWire.Pump.maintain, ctx.pumps[p])
        if not ok then
            LiveWire.warn("pump maintenance failed for " .. tostring(ctx.pumps[p].id) .. ": " .. tostring(err))
        end
    end
end

-- Everything the step shows to the world: anchors, computer, noise, pump relays, marks,
-- journal and the snapshot sent to the subscribers.
local function emitSideEffects(ctx)
    updateAnchors(ctx)
    runManagement(ctx)
    makeNoise(ctx)
    maintainPumps(ctx)
    -- State shown by the client (lights, menus): rewrite the marks that changed.
    LiveWire.Devices.refreshStates(ctx.grid)
    LiveWire.Journal.capture(ctx.grid)
    Sim.publish(ctx.grid)
end

-- evaluate: when no game time passed since the last step, still re-evaluate the
-- state (trip, power, marks, publication) with a zero-length step. Time is never
-- moved back: a command can no longer advance production, wear or fuel.
function Sim.stepGrid(grid, now, w, evaluate)
    local ctx = resolveInverter(grid, now, w, evaluate)
    if not ctx then return end
    measureDemand(ctx)
    syncLinkedVanilla(ctx)
    collectMembers(ctx)
    warnStorm(ctx)
    readBatteries(ctx)
    addPumpDemand(ctx)
    planSubsteps(ctx)
    for i = 1, ctx.n do stepSubstep(ctx, i) end
    settleGrid(ctx)
    emitSideEffects(ctx)
end

function Sim.tick()
    local R = LiveWire.Registry
    if not R or not R.ready or R.readOnly then return end
    local now = getGameTime():getWorldAgeHours()
    local w = weather()
    -- Devices destroyed without being picked up (zombies, sledgehammer).
    local devIds = {}
    for id, dev in pairs(R.devices()) do
        if LiveWire.Defs.devices[dev.model] then devIds[#devIds + 1] = id end
    end
    for i = 1, #devIds do
        local dev = R.device(devIds[i])
        if dev then
            local ok, err = pcall(LiveWire.Devices.validate, dev)
            if not ok then LiveWire.warn("validation failed for " .. devIds[i] .. ": " .. tostring(err)) end
        end
    end
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
    -- Simulates only the game time elapsed since the last step (zero right after
    -- one), then re-evaluates the state.
    local ok, err = pcall(Sim.stepGrid, grid, now, weather(), true)
    if not ok then LiveWire.warn("refresh failed for " .. grid.id .. ": " .. tostring(err)) end
end

Events.EveryTenMinutes.Add(Sim.tick)
Events.EveryOneMinute.Add(Sim.purgeSubscribers)
