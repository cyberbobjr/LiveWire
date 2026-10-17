-- Live Wire: soft hum of running inverters, played locally on each client (no
-- network packet). playSoundImpl(name, false, nil) is local; playSound / playSoundLooped
-- on a free emitter would be relayed and never stopped for other players
-- (knowledge/sounds-and-noise.md:13-17, FMODSoundEmitter.java:380-461).
-- Sound chosen by the user: the vanilla fridge hum (FridgeHumA).
if isServer() then return end

LiveWire = LiveWire or {}

local Hum = {}
LiveWire.Hum = Hum

Hum.SOUND = "FridgeHumA"
Hum.RANGE = 12
Hum.VOLUME = 0.6
Hum.active = {}   -- inverter id -> { em = emitter, id = sound ref }

function Hum.stop(id)
    local h = Hum.active[id]
    if h and h.id and h.id ~= 0 and h.em:isPlaying(h.id) then h.em:stopSound(h.id) end
    Hum.active[id] = nil
end

function Hum.start(id, a)
    local h = Hum.active[id]
    if h and h.id and h.id ~= 0 and h.em:isPlaying(h.id) then return end
    local em = getWorld():getFreeEmitter(a.x + 0.5, a.y + 0.5, a.z)
    if not em then return end
    local ref = em:playSoundImpl(Hum.SOUND, false, nil)
    if ref and ref ~= 0 then em:setVolume(ref, Hum.VOLUME) end
    Hum.active[id] = { em = em, id = ref }
end

local function update()
    local player = getPlayer()
    if not player then return end
    local anchors = LiveWire.Anchor.table()
    for id in pairs(Hum.active) do
        if not anchors[id] or not anchors[id].on then Hum.stop(id) end
    end
    for id, a in pairs(anchors) do
        if a.on then
            local dx, dy = player:getX() - a.x, player:getY() - a.y
            local close = dx * dx + dy * dy <= Hum.RANGE * Hum.RANGE
                and math.abs(player:getZ() - a.z) < 2
                and getCell():getGridSquare(a.x, a.y, a.z) ~= nil
            if close then Hum.start(id, a) else Hum.stop(id) end
        end
    end
end

Events.EveryOneMinute.Add(update)
