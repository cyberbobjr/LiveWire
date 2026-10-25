-- Live Wire: pure energy formulas (no game API calls).
-- Units: power in W, energy in kWh, time in game hours.
-- Formulas: docs/specifications-fonctionnelles.md sections 3 to 5. Tested offline by tests/test_physics.py.

LiveWire = LiveWire or {}

local Physics = {}
LiveWire.Physics = Physics

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- Production loss from wear: 0.5 at condition 0, 1.0 at condition 100.
function Physics.conditionFactor(cond)
    return 0.5 + 0.5 * clamp(cond, 0, 100) / 100
end

-- Instantaneous solar curve between dawn and dusk (decimal hours).
function Physics.solarCurve(t, dawn, dusk)
    local len = dusk - dawn
    if len <= 0 or t <= dawn or t >= dusk then return 0 end
    return math.sin(math.pi * (t - dawn) / len)
end

-- Mean of the solar curve over [t0, t1] on one day (0 <= t0 <= t1 <= 24).
-- Closed-form integral of the sine, clipped to [dawn, dusk].
function Physics.solarCurveMean(t0, t1, dawn, dusk)
    if t1 <= t0 then return Physics.solarCurve(t0, dawn, dusk) end
    local len = dusk - dawn
    if len <= 0 then return 0 end
    local a = math.max(t0, dawn)
    local b = math.min(t1, dusk)
    if b <= a then return 0 end
    local k = math.pi / len
    local integral = (math.cos(k * (a - dawn)) - math.cos(k * (b - dawn))) / k
    return integral / (t1 - t0)
end

function Physics.solarFactor(curve, clouds, snowCover)
    return curve * (1 - 0.8 * clamp(clouds, 0, 1)) * (1 - clamp(snowCover, 0, 1))
end

-- Wind speed corrected for height: +15% per floor, up to the 3rd floor.
function Physics.windAtHeight(kph, z)
    local floors = clamp(z or 0, 0, 3)
    return kph * (1 + 0.15 * floors)
end

Physics.WIND_CUT_IN = 10
Physics.WIND_RATED = 45
Physics.WIND_CUT_OUT = 85

function Physics.windFactor(v)
    if v < Physics.WIND_CUT_IN or v > Physics.WIND_CUT_OUT then return 0 end
    if v >= Physics.WIND_RATED then return 1 end
    local r = (v - Physics.WIND_CUT_IN) / (Physics.WIND_RATED - Physics.WIND_CUT_IN)
    return r * r * r
end

-- Water wheel: river flow by season, day and night (docs/specifications-fonctionnelles.md 3.4,
-- rule of the mod): spring x1.2, summer x0.8, autumn and winter x1.0. The engine
-- never freezes water. `month` is GameTime:getMonth() (0 = January).
function Physics.hydroFactor(month)
    if month == nil then return 1 end
    if month >= 2 and month <= 4 then return 1.2 end
    if month >= 5 and month <= 7 then return 0.8 end
    return 1
end

-- Built-in micro-inverter smoothing (first-order lag, tau in hours).
function Physics.smooth(prev, raw, dtHours, tau)
    if prev == nil then return raw end
    local a = 1
    if tau > 0 then a = math.min(1, dtHours / tau) end
    return prev + (raw - prev) * a
end

-- Effective capacity of a battery from its condition (0.4 at 0, 1.0 at 100).
function Physics.batteryCapacity(nominalKWh, cond, multiplier)
    if cond <= 0 then return 0 end
    return nominalKWh * (0.4 + 0.6 * clamp(cond, 0, 100) / 100) * (multiplier or 1)
end

-- Outside batteries retain their stored energy; only the accessible window shrinks.
function Physics.coldFactor(temperature, outside, enabled)
    if not enabled or not outside then return 1 end
    if temperature >= 15 then return 1 end
    return clamp(0.8 + temperature * (0.2 / 15), 0.6, 1)
end

-- Facings follow the tile sheet: S, E, N, W. Shift the daylight curve, not the clock.
function Physics.solarFacing(facing, enabled)
    if not enabled then return 1, 0 end
    if facing == 1 then return 0.85, -2 end
    if facing == 2 then return 0.55, 0 end
    if facing == 3 then return 0.85, 2 end
    return 1, 0
end

-- Wear points for a discharge of `drawnKWh` from a battery of `nominalKWh`.
function Physics.batteryWear(drawnKWh, nominalKWh, lifeCycles, deep, multiplier)
    if drawnKWh <= 0 or nominalKWh <= 0 or lifeCycles <= 0 then return 0 end
    local w = (drawnKWh / nominalKWh) * 100 / lifeCycles
    if deep then w = w * 2 end
    return w * (multiplier or 1)
end

-- Distribute `amount` kWh over `items` proportionally to `weightField`, never
-- exceeding the per-item `limitField`. Returns the amount actually placed.
local function distribute(items, amount, weightField, limitField, sign)
    local placed = 0
    local remaining = amount
    for _ = 1, 3 do
        if remaining <= 1e-9 then break end
        local total = 0
        for i = 1, #items do
            local it = items[i]
            if it[limitField] > 1e-9 then total = total + it[weightField] end
        end
        if total <= 1e-9 then break end
        local pass = 0
        for i = 1, #items do
            local it = items[i]
            if it[limitField] > 1e-9 and it[weightField] > 0 then
                local share = math.min(remaining * it[weightField] / total, it[limitField])
                it.charge = it.charge + sign * share
                it[limitField] = it[limitField] - share
                it[weightField] = math.max(0, it[weightField] - share)
                pass = pass + share
            end
        end
        placed = placed + pass
        remaining = remaining - pass
        if pass <= 1e-9 then break end
    end
    return placed
end

-- One network step.
-- p = {
--   productionW, demandW (appliances), idleW, maxW, eff, dt (hours),
--   wasOn (bool), state ("on"|"off"|"tripped"|"broken"),
--   batteries = { { charge = kWh, capacity = kWh } ... }  (mutated in place)
-- }
-- on is the END state; onHours is the served duration from the start of the step.
-- servedW and usefulW are averages over the entire step, including the off fraction.
function Physics.stepGrid(p)
    local r = { on = false, tripped = false, servedW = 0, drawnKWh = 0,
                chargedKWh = 0, lostKWh = 0, stockKWh = 0, capacityKWh = 0, onHours = 0 }
    local dt = p.dt
    local eff = clamp(p.eff or 0.85, 0.05, 1)
    local batteries = p.batteries or {}

    local stock, capacity = 0, 0
    for i = 1, #batteries do
        local b = batteries[i]
        b.charge = clamp(b.charge, 0, b.capacity)
        stock = stock + b.charge
        capacity = capacity + b.capacity
    end

    local running = (p.state == "on")
    local demand = 0
    if running then demand = (p.demandW or 0) + (p.idleW or 0) end

    -- Overload trips the inverter before anything is served.
    if running and p.maxW and (p.demandW or 0) > p.maxW then
        r.tripped = true
        running = false
        demand = 0
    end

    local production = math.max(0, p.productionW or 0)
    if p.state == "broken" then
        -- A broken inverter regulates nothing: the production is lost.
        r.lostKWh = production * LiveWire.Defs.CHARGE_EFFICIENCY * dt / 1000
        production = 0
    end
    local on = false
    local usefulW = 0
    if running then
        local fromProd = math.min(production * eff, demand)
        local missingW = demand - fromProd
        local needKWh = missingW / eff * dt / 1000
        local canStart = p.wasOn
            or (capacity > 0 and stock > capacity * LiveWire.Defs.RESTART_STOCK_RATIO)
            or (production * eff >= demand)
        if canStart then
            local fraction = 1
            if needKWh > stock then fraction = stock / needKWh end
            fraction = clamp(fraction, 0, 1)
            r.onHours = dt * fraction
            usefulW = fromProd * fraction
            on = fraction >= 1 and (needKWh <= 0 or stock - needKWh > 1e-9)
            if needKWh > 0 and fraction > 0 then
                for i = 1, #batteries do
                    local b = batteries[i]
                    b._w = b.charge
                    b._lim = b.charge
                end
                local drawn = distribute(batteries, math.min(needKWh, stock), "_w", "_lim", -1)
                r.drawnKWh = drawn
            end
            r.servedW = demand * fraction
        end
    end

    -- Surplus DC power charges the batteries (also while the house is off).
    local surplusW = production - usefulW / eff
    if surplusW > 0 then
        local chargeKWh = surplusW * LiveWire.Defs.CHARGE_EFFICIENCY * dt / 1000
        for i = 1, #batteries do
            local b = batteries[i]
            b._lim = math.max(0, b.capacity - b.charge)
            b._w = b._lim
        end
        local placed = distribute(batteries, chargeKWh, "_w", "_lim", 1)
        r.chargedKWh = placed
        r.lostKWh = chargeKWh - placed
    end

    for i = 1, #batteries do
        local b = batteries[i]
        b._w = nil
        b._lim = nil
        r.stockKWh = r.stockKWh + b.charge
        r.capacityKWh = r.capacityKWh + b.capacity
    end
    r.on = on
    return r
end
