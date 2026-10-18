-- Live Wire: soft electrical hum of switched-on inverters, played locally on each
-- client (no network packet). playSoundImpl(name, false, nil) is local; playSound /
-- playSoundLooped on a free emitter would be relayed and never stopped for other
-- players (knowledge/sounds-and-noise.md:13-17, FMODSoundEmitter.java:380-461).
-- Sound of the mod (media/sound/LiveWireInverterHum.ogg, looped), heard only one
-- tile around a switched-on inverter (powered or not), on the same floor. Silent
-- when the inverter is soundproofed (kit, mark field muf). The water pump has its own
-- motor sound (LiveWirePumpHum), heard within PUMP_RANGE while it runs (mark st
-- "running"). Each player sets its volume in Options > Mods (0 = off).
if isServer() then return end

LiveWire = LiveWire or {}

local Hum = {}
LiveWire.Hum = Hum

Hum.SOUND = "LiveWireInverterHum"
Hum.PUMP_SOUND = "LiveWirePumpHum"
Hum.RANGE = 1.5   -- tiles from the inverter centre: one tile around it
Hum.PUMP_RANGE = 4.5   -- tiles from the pump centre while it runs
Hum.CHECK_MS = 250
Hum.active = {}   -- inverter object -> { em = emitter, id = sound ref, volume }
local lastCheck = 0

-- Player option: hum volume in percent (Options > Mods > Live Wire).
local options = nil
if PZAPI and PZAPI.ModOptions then
    options = PZAPI.ModOptions:create("LiveWire", "UI_LW_Options_Title")
    options:addSlider("humVolume", "UI_LW_Options_HumVolume", 0, 100, 5, 100, "UI_LW_Options_HumVolume_tooltip")
end

function Hum.volume()
    local o = options and options:getOption("humVolume")
    local v = o and o:getValue() or 100
    return LiveWire.clamp((tonumber(v) or 100) / 100, 0, 1)
end

local function playing(h)
    return h and h.id and h.id ~= 0 and h.em:isPlaying(h.id)
end

function Hum.stop(obj)
    local h = Hum.active[obj]
    if playing(h) then h.em:stopSound(h.id) end
    Hum.active[obj] = nil
end

function Hum.start(obj, volume, sound)
    local h = Hum.active[obj]
    if playing(h) then
        if h.volume ~= volume then
            h.em:setVolume(h.id, volume)
            h.volume = volume
        end
        return
    end
    local sq = obj:getSquare()
    local em = getWorld():getFreeEmitter(sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ())
    if not em then return end
    local ref = em:playSoundImpl(sound or Hum.SOUND, false, nil)
    if ref and ref ~= 0 then em:setVolume(ref, volume) end
    Hum.active[obj] = { em = em, id = ref, volume = volume }
end

local function wantsHum(player, obj)
    if obj:getObjectIndex() == -1 or not obj:getSquare() then return false end
    local m = LiveWire.Marks.get(obj)
    if not m or m.st ~= "on" or m.muf then return false end
    local sq = obj:getSquare()
    if math.floor(player:getZ()) ~= sq:getZ() then return false end
    local dx, dy = player:getX() - (sq:getX() + 0.5), player:getY() - (sq:getY() + 0.5)
    return dx * dx + dy * dy <= Hum.RANGE * Hum.RANGE
end

local function wantsPump(player, obj)
    if obj:getObjectIndex() == -1 or not obj:getSquare() then return false end
    local m = LiveWire.Marks.get(obj)
    if not m or m.st ~= "running" then return false end
    local sq = obj:getSquare()
    if math.floor(player:getZ()) ~= sq:getZ() then return false end
    local dx, dy = player:getX() - (sq:getX() + 0.5), player:getY() - (sq:getY() + 0.5)
    return dx * dx + dy * dy <= Hum.PUMP_RANGE * Hum.PUMP_RANGE
end

local function update()
    local player = getPlayer()
    if not player or not LiveWire.Visuals then return end
    local now = getTimestampMs()
    if now - lastCheck < Hum.CHECK_MS then return end
    lastCheck = now
    local volume = Hum.volume()
    local seen = {}
    if volume > 0 then
        local list = LiveWire.Visuals.inverters()
        for i = 1, #list do
            local o = list[i]
            if wantsHum(player, o) then
                seen[o] = true
                Hum.start(o, volume)
            end
        end
        local pumps = LiveWire.Visuals.pumps()
        for i = 1, #pumps do
            local o = pumps[i]
            if wantsPump(player, o) then
                seen[o] = true
                Hum.start(o, volume, Hum.PUMP_SOUND)
            end
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
