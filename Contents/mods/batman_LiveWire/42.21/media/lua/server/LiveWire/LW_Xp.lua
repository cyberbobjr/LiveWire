-- Live Wire: Electrical experience, always granted on the authority
-- (addXp does nothing on an MP client: LuaManager.java:9300-9316).
if isClient() then return end

LiveWire = LiveWire or {}

local Xp = {}
LiveWire.Xp = Xp

-- Per-player cooldowns kept in memory (reset on server restart, which is harmless).
Xp.cooldowns = {}

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
    Xp.award(character, amount)
    return true
end
