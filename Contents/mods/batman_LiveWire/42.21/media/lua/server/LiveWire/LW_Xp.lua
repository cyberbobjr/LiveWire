-- Live Wire: Electrical experience, always granted on the authority
-- (addXp does nothing on an MP client: LuaManager.java:9300-9316).
if isClient() then return end

LiveWire = LiveWire or {}

local Xp = {}
LiveWire.Xp = Xp

-- Per-player cooldowns kept in memory (reset on server restart, which is harmless).
Xp.cooldowns = {}
local expires = {}
Xp.MEASURE_MAX = 5           -- base XP, before sandbox/vanilla multipliers
Xp.MEASURE_HOURS = 1         -- rolling game-hour window, all squares combined

local function identity(character)
    local name = character:getUsername()
    if name and name ~= "" then return name end
    return "local:" .. tostring(character:getPlayerNum())
end

local function recent(entries, now)
    local out = {}
    for i = 1, #entries do
        if entries[i] <= now and now - entries[i] < Xp.MEASURE_HOURS then
            out[#out + 1] = entries[i]
        end
    end
    return out
end

local function measurementData()
    local r = LiveWire.Registry
    if not r or not r.ready or r.readOnly then return nil end
    r.data.measureXp = r.data.measureXp or {}
    return r.data.measureXp
end

function Xp.purge()
    local now = getGameTime():getWorldAgeHours()
    local players = {}
    for who in pairs(Xp.cooldowns) do players[#players + 1] = who end
    for i = 1, #players do
        local who = players[i]
        local entries, stale = Xp.cooldowns[who], {}
        for key, last in pairs(entries) do
            local untilHour = expires[who] and expires[who][key] or last + 24
            if now >= untilHour or now < last then stale[#stale + 1] = key end
        end
        for j = 1, #stale do
            entries[stale[j]] = nil
            if expires[who] then expires[who][stale[j]] = nil end
        end
        local any = false
        for _ in pairs(entries) do any = true; break end
        if not any then Xp.cooldowns[who], expires[who] = nil, nil end
    end
    local measurements = measurementData()
    if measurements then
        local names = {}
        for who in pairs(measurements) do names[#names + 1] = who end
        for i = 1, #names do
            local kept = recent(measurements[names[i]], now)
            measurements[names[i]] = #kept > 0 and kept or nil
        end
    end
end

function Xp.award(character, amount)
    if not character or amount <= 0 then return end
    local mult = LiveWire.Config.get("XPMultiplier") or 1
    if mult <= 0 then return end
    addXp(character, Perks.Electricity, amount * mult)
end

-- Award once per `periodHours` of game time for a given (player, key).
function Xp.awardLimited(character, key, amount, periodHours)
    local who = identity(character)
    local now = getGameTime():getWorldAgeHours()
    local byPlayer = Xp.cooldowns[who] or {}
    Xp.cooldowns[who] = byPlayer
    local last = byPlayer[key]
    if last and now - last < periodHours then return false end
    byPlayer[key] = now
    expires[who] = expires[who] or {}
    expires[who][key] = now + math.max(24, periodHours)
    Xp.award(character, amount)
    return true
end

-- Server-owned rolling limit survives reconnects/restarts. A denied gain does not
-- consume the square cooldown; measuring itself still produces its normal result.
function Xp.awardMeasurement(character, key)
    local measurements = measurementData()
    if not measurements or not character then return false end
    local who, now = identity(character), getGameTime():getWorldAgeHours()
    local kept = recent(measurements[who] or {}, now)
    measurements[who] = #kept > 0 and kept or nil
    if #kept >= Xp.MEASURE_MAX then return false end
    if not Xp.awardLimited(character, key, 1, Xp.MEASURE_HOURS) then return false end
    kept[#kept + 1] = now
    measurements[who] = kept
    return true
end

Events.EveryHours.Add(Xp.purge)
