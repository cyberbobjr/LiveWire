-- Live Wire: beep of the low battery alarm, played locally on the client (the
-- server only sends the position, LW_Alarm.lua). Same local playback as the hum
-- (LW_Hum.lua). The vanilla TelevisionTestBeep event may loop
-- (media/scripts/generated/sounds/objects/sounds_object_television.txt:3-10): it is
-- stopped after a few seconds whatever it does.
if isServer() then return end

LiveWire = LiveWire or {}

local Beep = {}
LiveWire.Beep = Beep

Beep.SOUND = "TelevisionTestBeep"
Beep.DURATION_MS = 3000
Beep.VOLUME = 0.8
Beep.playing = {}   -- list of { em = emitter, id = sound ref, stopAt = ms }
local watching = false
local onTick

function Beep.play(x, y, z)
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then return end
    local em = getWorld():getFreeEmitter(x + 0.5, y + 0.5, z)
    if not em then return end
    local ref = em:playSoundImpl(Beep.SOUND, false, nil)
    if not ref or ref == 0 then return end
    em:setVolume(ref, Beep.VOLUME)
    Beep.playing[#Beep.playing + 1] = { em = em, id = ref, stopAt = getTimestampMs() + Beep.DURATION_MS }
    if not watching then watching = true; Events.OnTick.Add(onTick) end
end

onTick = function()
    local now = getTimestampMs()
    for i = #Beep.playing, 1, -1 do
        local b = Beep.playing[i]
        if now >= b.stopAt then
            if b.em:isPlaying(b.id) then b.em:stopSound(b.id) end
            table.remove(Beep.playing, i)
        end
    end
    if #Beep.playing == 0 then watching = false; Events.OnTick.Remove(onTick) end
end

function Beep.clear()
    for _, b in ipairs(Beep.playing) do
        if b.em:isPlaying(b.id) then b.em:stopSound(b.id) end
    end
    Beep.playing = {}
    if watching then watching = false; Events.OnTick.Remove(onTick) end
end

Events.OnDisconnect.Add(Beep.clear)
Events.OnMainMenuEnter.Add(Beep.clear)
