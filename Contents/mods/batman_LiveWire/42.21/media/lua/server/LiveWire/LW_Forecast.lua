-- Live Wire: hourly cached three-day estimate, using the simulation's production rules.
if isClient() then return end
LiveWire = LiveWire or {}
local Forecast = {}
LiveWire.Forecast = Forecast
function Forecast.loadEstimate(grid)
    local mean = 0
    for _, h in ipairs(grid.history or {}) do mean = mean + h.d end
    local count = #(grid.history or {})
    mean = count > 0 and mean / count or (grid.demand or 0)
    -- Historic samples predate the manual cut. Forecast the present service plan.
    if grid.lightsOff or grid.equipmentOff then mean = grid.demand or 0 end
    if grid.equipmentOff then
        -- Pump energy already spent before the cut is still billed by Sim, but
        -- the stopped pump must not be projected as a future service load.
        mean = 0
        for _, group in pairs(grid.appliances or {}) do mean = mean + group.w end
    end
    return mean
end
function Forecast.build(grid, sources, now)
    if grid.forecastAt and now - grid.forecastAt < 1 then return end
    grid.forecastAt = now
    local cm = getClimateManager()
    local forecaster = cm:getClimateForecaster()
    local out = {}
    local mean = Forecast.loadEstimate(grid)
    local inv = LiveWire.Registry.device(grid.inverter)
    local eff = inv and inv.eff or 0.85
    local projected = { { charge = grid.stock or 0, capacity = grid.capacity or 0 } }
    local tod = getGameTime():getTimeOfDay()
    for offset = 0, 2 do
        local day = forecaster and forecaster:getForecast(offset)
        if day then
            local w = { clouds = day:getCloudiness():getDayMean(),
                windKph = day:getWindPower():getTotalMean() * 120,
                dawn = day:getDawn(), dusk = day:getDusk(),
                month = getGameTime():getMonth() }
            local row = { offset = offset, solar = 0, wind = 0, hydro = 0 }
            local hourly = {}
            for hour = 0, 23 do hourly[hour] = 0 end
            for _, src in ipairs(sources) do
                local def = LiveWire.Defs.devices[src.model]
                if def then
                    for hour = 0, 23 do
                        local watts = LiveWire.Sim.sourceRaw(src, def, w, hour, 1)
                        row[def.kind] = row[def.kind] + watts / 1000
                        hourly[hour] = hourly[hour] + watts
                    end
                end
            end
            row.total = row.solar + row.wind + row.hydro
            row.demand = (mean + LiveWire.Sim.idleW(grid)) * 24 / 1000
            row.sufficient = true
            -- Today starts now. Daily production figures remain full-day comparisons.
            -- The sufficiency check observes storage limits, conversion and night deficits.
            for hour = offset == 0 and math.floor(tod) or 0, 23 do
                local duration = offset == 0 and hour == math.floor(tod) and (1 - tod % 1) or 1
                local r = LiveWire.Physics.stepGrid({ productionW = hourly[hour], demandW = mean,
                    idleW = LiveWire.Sim.idleW(grid), maxW = LiveWire.Sim.capacityW(grid),
                    eff = eff, dt = duration, state = "on", wasOn = true, batteries = projected })
                if r.onHours + 1e-8 < duration then row.sufficient = false end
            end
            out[#out + 1] = row
        end
    end
    grid.forecast = out
end
