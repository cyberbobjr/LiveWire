-- Live Wire: Electrical experience, always granted on the authority
-- (addXp does nothing on an MP client: LuaManager.java:9300-9316).
if isClient() then return end

LiveWire = LiveWire or {}

local Xp = {}
LiveWire.Xp = Xp

-- Per-player cooldowns kept in memory (reset on server restart, which is harmless).
Xp.cooldowns = {}
local expires = {}

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
end

function Xp.award(character, amount)
    if not character or amount <= 0 then return end
    local mult = LiveWire.Config.get("XPMultiplier") or 1
    if mult <= 0 then return end
    addXp(character, Perks.Electricity, amount * mult)
end

-- Award once per `periodHours` of game time for a given (player, key).
function Xp.awardLimited(character, key, amount, periodHours)
    local who = character:getUsername() or tostring(character:getPlayerNum())
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

Events.EveryHours.Add(Xp.purge)
