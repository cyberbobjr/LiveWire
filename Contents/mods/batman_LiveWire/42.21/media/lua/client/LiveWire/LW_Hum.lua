-- Live Wire: soft electrical hum of switched-on inverters, played locally on each
-- client (no network packet). playSoundImpl(name, false, nil) is local; playSound /
-- playSoundLooped on a free emitter would be relayed and never stopped for other
-- players (knowledge/sounds-and-noise.md:13-17, FMODSoundEmitter.java:380-461).
-- Sound of the mod (media/sound/LiveWireInverterHum.ogg, looped), heard while the
-- inverter is switched on, powered or not. The vanilla fridge hum (FridgeHumA)
-- chosen first (D-8) could not be heard in game.
if isServer() then return end

LiveWire = LiveWire or {}

local Hum = {}
LiveWire.Hum = Hum

Hum.SOUND = "LiveWireInverterHum"
Hum.RANGE = 6
Hum.CHECK_MS = 1000
Hum.active = {}   -- inverter object -> { em = emitter, id = sound ref }
local lastCheck = 0

local function playing(h)
    return h and h.id and h.id ~= 0 and h.em:isPlaying(h.id)
end

function Hum.stop(obj)
    local h = Hum.active[obj]
    if playing(h) then h.em:stopSound(h.id) end
    Hum.active[obj] = nil
end

function Hum.start(obj)
    if playing(Hum.active[obj]) then return end
    local sq = obj:getSquare()
    local em = getWorld():getFreeEmitter(sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ())
    if not em then return end
    local ref = em:playSoundImpl(Hum.SOUND, false, nil)
    Hum.active[obj] = { em = em, id = ref }
end

local function wantsHum(player, obj)
    if obj:getObjectIndex() == -1 or not obj:getSquare() then return false end
    local m = LiveWire.Marks.get(obj)
    if not m or m.st ~= "on" then return false end
    local sq = obj:getSquare()
    local dx, dy = player:getX() - (sq:getX() + 0.5), player:getY() - (sq:getY() + 0.5)
    return dx * dx + dy * dy <= Hum.RANGE * Hum.RANGE and math.abs(player:getZ() - sq:getZ()) < 2
end

local function update()
    local player = getPlayer()
    if not player or not LiveWire.Visuals then return end
    local now = getTimestampMs()
    if now - lastCheck < Hum.CHECK_MS then return end
    lastCheck = now
    local seen = {}
    local list = LiveWire.Visuals.inverters()
    for i = 1, #list do
        local o = list[i]
        if wantsHum(player, o) then
            seen[o] = true
            Hum.start(o)
        end
    end
    -- Collect first: never change a Kahlua table during pairs.
    local stale = {}
    for o in pairs(Hum.active) do
        if not seen[o] then stale[#stale + 1] = o end
    end
    for i = 1, #stale do Hum.stop(stale[i]) end
end

Events.OnTick.Add(update)
