-- Live Wire: appliance consumption profiles (sandbox LiveWire.ConsumptionProfile).
-- The engine tells whether an appliance is on through getGeneratorPowerConsumption() > 0
-- (IsoGenerator.java:283); the profile then gives its draw in W while on. The values are
-- averages over a 10-minute step (a fridge compressor cycles), not start-up peaks.
-- 1 = ultra-realistic 1993, 2 = realistic 1993, 3 = engine values (default), 4 = comfort.
-- Sources and rationale: docs/specifications-fonctionnelles.md, section 5.3.

LiveWire = LiveWire or {}

local Consumption = {}
LiveWire.Consumption = Consumption

Consumption.DEFAULT_PROFILE = 3
Consumption.ENGINE = 3

-- W while on, per appliance kind. `nil` = engine value x 1000 (x `otherFactor`).
Consumption.PROFILES = {
    [1] = { light = 100, radio = 40, tv = 120, fridge = 130, fridgeFreezer = 180,
            stove = 3000, microwave = 1500, washer = 700, dryer = 5000, comboDryer = 3000,
            charger = 250, otherFactor = 1 },
    [2] = { light = 60, radio = 20, tv = 80, fridge = 90, fridgeFreezer = 130,
            stove = 2000, microwave = 1100, washer = 500, dryer = 3000, comboDryer = 2000,
            charger = 150, otherFactor = 1 },
    [3] = { otherFactor = 1 },
    [4] = { light = 1, radio = 5, tv = 15, fridge = 40, fridgeFreezer = 65,
            stove = 45, microwave = 45, washer = 45, dryer = 45, comboDryer = 45,
            charger = 25, otherFactor = 0.5 },
}

function Consumption.profile()
    local p = tonumber(LiveWire.Config.get("ConsumptionProfile")) or Consumption.DEFAULT_PROFILE
    p = math.floor(p)
    if not Consumption.PROFILES[p] then p = Consumption.DEFAULT_PROFILE end
    return p
end

-- Draw in W of one appliance with engine value `p` (> 0) under profile table `t`.
local function profileWatts(o, p, t)
    if o:getPipedFuelAmount() > 0 then
        -- Gas appliance: only its controls use power, kept at the engine value.
        return p * 1000 * t.otherFactor
    end
    local w
    if instanceof(o, "IsoLightSwitch") then
        w = t.light
    elseif instanceof(o, "IsoRadio") then
        w = t.radio
    elseif instanceof(o, "IsoTelevision") then
        w = t.tv
    elseif instanceof(o, "IsoStove") then
        if o:isMicrowave() then w = t.microwave else w = t.stove end
    elseif instanceof(o, "IsoStackedWasherDryer") then
        if t.washer then
            w = 0
            if o:isWasherActivated() then w = w + t.washer end
            if o:isDryerActivated() then w = w + t.dryer end
        end
    elseif instanceof(o, "IsoCombinationWasherDryer") then
        if o:isModeDryer() then w = t.comboDryer else w = t.washer end
    elseif instanceof(o, "IsoClothingDryer") then
        w = t.dryer
    elseif instanceof(o, "IsoClothingWasher") then
        w = t.washer
    elseif instanceof(o, "IsoCarBatteryCharger") then
        w = t.charger
    elseif o:getContainerByType("fridge") and o:getContainerByType("freezer") then
        w = t.fridgeFreezer
    elseif o:getContainerByType("fridge") or o:getContainerByType("freezer") then
        w = t.fridge
    end
    return w or p * 1000 * t.otherFactor
end

-- Draw in W of an appliance, 0 when it is off; includes LiveWire.PowerScale.
-- `profile` is optional (read once by the caller for a whole scan).
function Consumption.watts(o, profile, beforeCircuit)
    -- Fuel pumps have no native activation flag. Their actual dispensing actions
    -- are refused on both peers, including partial transfers and completion.
    if not beforeCircuit and LiveWire.Appliances and LiveWire.Appliances.kind(o) == "fuel"
        and LiveWire.Appliances.blocked(o) then return 0 end
    local p = o:getGeneratorPowerConsumption()
    if not p or p <= 0 then return 0 end
    local scale = LiveWire.Config.get("PowerScale") or 1
    profile = profile or Consumption.profile()
    if profile == Consumption.ENGINE then return p * 1000 * scale end
    return profileWatts(o, p, Consumption.PROFILES[profile]) * scale
end
