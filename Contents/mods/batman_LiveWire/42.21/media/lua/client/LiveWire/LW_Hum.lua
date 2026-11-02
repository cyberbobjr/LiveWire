-- Live Wire: device state selects native sound events. The world updates the
-- emitters; FMOD handles distance, attenuation, occlusion and the SFX volume.
-- Visuals already reconciles loaded device marks: no separate scan or OnTick.
if isServer() then return end

LiveWire = LiveWire or {}
local Hum = { SOUND = "LiveWireInverterHum", PUMP_SOUND = "LiveWirePumpHum", active = {} }
LiveWire.Hum = Hum

local options
if PZAPI and PZAPI.ModOptions then
    options = PZAPI.ModOptions:create("LiveWire", "UI_LW_Options_Title")
    options:addSlider("humVolume", "UI_LW_Options_HumVolume", 0, 100, 5, 100, "UI_LW_Options_HumVolume_tooltip")
end

function Hum.volume()
    local o = options and options:getOption("humVolume")
    return LiveWire.clamp((tonumber(o and o:getValue()) or 100) / 100, 0, 1)
end

local function playing(h)
    return h and h.em:isPlaying(h.id)
end

function Hum.stop(obj)
    local h = Hum.active[obj]
    if playing(h) then h.em:stopSound(h.id) end
    Hum.active[obj] = nil
end

function Hum.start(obj, volume, sound)
    sound = sound or Hum.SOUND
    local h = Hum.active[obj]
    if playing(h) and h.sound == sound then
        if h.volume ~= volume then h.em:setVolume(h.id, volume); h.volume = volume end
        return
    end
    Hum.stop(obj)
    local sq = obj:getSquare()
    if not sq then return end
    local em = getWorld():getFreeEmitter(sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ())
    -- Local playback: playSound would broadcast a loop without a matching MP stop.
    local ref = em:playSoundImpl(sound, false, nil)
    if not ref or ref == 0 then return end
    if sound == Hum.PUMP_SOUND then em:setParameterValueByName(ref, "ClothingWasherLoaded", 0) end
    em:setVolume(ref, volume)
    Hum.active[obj] = { em = em, id = ref, sound = sound, volume = volume }
end

function Hum.sync(obj)
    local model = LiveWire.Defs.modelOfObject(obj)
    local def = model and LiveWire.Defs.devices[model]
    if not def or (def.role ~= "inverter" and model ~= "WaterPump") then Hum.stop(obj); return end
    local mark = LiveWire.Marks.get(obj)
    local sound
    if mark and obj:getSquare() and obj:getObjectIndex() ~= -1 then
        if def.role == "inverter" and mark.st == "on" and not mark.muf then sound = Hum.SOUND end
        if model == "WaterPump" and mark.st == "running" then sound = Hum.PUMP_SOUND end
    end
    local volume = sound and Hum.volume() or 0
    if volume > 0 then Hum.start(obj, volume, sound) else Hum.stop(obj) end
end

function Hum.clear()
    local objects = {}
    for obj in pairs(Hum.active) do objects[#objects + 1] = obj end
    for _, obj in ipairs(objects) do Hum.stop(obj) end
end

Events.OnObjectAboutToBeRemoved.Add(Hum.stop)
Events.OnDisconnect.Add(Hum.clear)
Events.OnMainMenuEnter.Add(Hum.clear)
