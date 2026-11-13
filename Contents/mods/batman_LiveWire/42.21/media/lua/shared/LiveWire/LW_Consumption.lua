-- Live Wire: appliance consumption profiles (sandbox LiveWire.ConsumptionProfile).
-- The engine tells whether an appliance is on through getGeneratorPowerConsumption() > 0
-- (IsoGenerator.java:283); the profile then gives its draw in W while on. The values are
-- averages over a 10-minute step (a fridge compressor cycles), not start-up peaks.
-- 1 = ultra-realistic 1993, 2 = realistic 1993, 3 = engine values (default), 4 = comfort.
-- Sources and rationale: docs/specifications-fonctionnelles.md, section 5.3.

require "LiveWire/LW_ApplianceFamilies"
require "LiveWire/LW_Consumers"
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
    local family = LiveWire.ApplianceFamilies.of(o, "profile")
    local profile = family and family.profile
    if type(profile) == "function" then
        w = profile(o, t)
    elseif profile then
        w = t[profile]
    end
    return w or p * 1000 * t.otherFactor
end

-- D-31: a piece of furniture of several squares (sprite grid) can report a consumption
-- on each of its objects. It is counted once, on the first consuming object in grid
-- order: the origin of the grid whenever it consumes. Its other objects draw 0 W.
local pieces -- reused ArrayList, created on first use
local function gridOrder(g, o)
    local s = o:getSprite()
    return (g:getSpriteGridPosZ(s) * g:getHeight() + g:getSpriteGridPosY(s)) * g:getWidth()
        + g:getSpriteGridPosX(s)
end
function Consumption.countedPiece(o)
    local g = o:getSpriteGrid()
    if not g or g:getSpriteCount() <= 1 then return true end
    pieces = pieces or ArrayList.new()
    o:getSpriteGridObjectsIncludingSelf(pieces)
    local mine = gridOrder(g, o)
    for i = 0, pieces:size() - 1 do
        local other = pieces:get(i)
        if other ~= o and gridOrder(g, other) < mine and other:getGeneratorPowerConsumption() > 0 then
            return false
        end
    end
    return true
end

-- Draw in W of an appliance, 0 when it is off; includes LiveWire.PowerScale.
-- `profile` is optional (read once by the caller for a whole scan).
function Consumption.watts(o, profile, beforeCircuit)
    -- Appliance of another mod (ADR-002): its declared draw replaces the engine value. Live
    -- Wire never switches it off, so a cut one bills 0 W here.
    local consumer = LiveWire.Consumers.of(o)
    if consumer then
        if not beforeCircuit and LiveWire.Appliances and LiveWire.Appliances.blockedAs(o, "consumer") then
            return 0
        end
        local w = LiveWire.Consumers.rawWatts(consumer, o)
        return w > 0 and Consumption.estimate(w) or 0
    end
    -- Fuel pumps have no native activation flag. Their actual dispensing actions
    -- are refused on both peers, including partial transfers and completion.
    if not beforeCircuit and LiveWire.Appliances and LiveWire.Appliances.kind(o) == "fuel"
        and LiveWire.Appliances.blocked(o) then return 0 end
    local p = o:getGeneratorPowerConsumption()
    if not p or p <= 0 then return 0 end
    if not Consumption.countedPiece(o) then return 0 end
    local scale = LiveWire.Config.get("PowerScale") or 1
    profile = profile or Consumption.profile()
    if profile == Consumption.ENGINE then return p * 1000 * scale end
    return profileWatts(o, p, Consumption.PROFILES[profile]) * scale
end

-- Draw in W of a load the engine reports as 0 and that a sub-mod estimates (`w` W at the
-- engine value): follows the sandbox like every appliance, PowerScale and the factor
-- of the consumption profile.
function Consumption.estimate(w)
    local t = Consumption.PROFILES[Consumption.profile()]
    return w * (LiveWire.Config.get("PowerScale") or 1) * (t and t.otherFactor or 1)
end
