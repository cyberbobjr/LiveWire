-- Live Wire: state lights and moving parts of the placed devices, drawn locally on
-- each client as tile overlays (attachedAnimSprite, IsoObject.java:1821-1880):
--   inverter: lit screen when on, red light when tripped or broken;
--   power bank and sources: green light when connected to an inverter;
--   wind turbine: blades (the tile has none), turning with the wind;
--   breaker: red lamp when tripped; alarm: lit beacon while it rings.
-- The state comes from the device mark (modData.movableData.LiveWire, sent by the
-- server: st, pw, inv). Only our own overlays (index >= 24) are touched; the list
-- is rebuilt from the mark whenever it differs, so overlays saved with a single
-- player world are corrected at the next update.
if isServer() then return end

LiveWire = LiveWire or {}

local V = {}
LiveWire.Visuals = V

local PREFIX = LiveWire.Defs.SHEET .. "_"
local FIRST_OVERLAY = 24

-- Overlay sprites that exist in the pack (lights on the front are not drawn for the
-- N and W facings, where the front is hidden).
local EXISTS = {}
for _, i in ipairs({ 24, 25, 28, 29, 32, 33, 36, 37, 40, 41, 44, 45, 64, 65, 66, 67 }) do EXISTS[i] = true end
for i = 48, 63 do EXISTS[i] = true end

V.SCAN_RADIUS = 18
V.SCAN_MS = 3000
V.STATE_MS = 1000
V.FRAME_MS = 100
V.WIND_CUT_IN = 10   -- km/h, same as the simulation (LW_Physics.lua)

V.tracked = {}       -- list of objects
local known = {}     -- object -> true
local lastScan, lastState, lastFrame = 0, 0, 0

local function spriteIndex(obj)
    local spr = obj:getSprite()
    local name = spr and spr:getName()
    if not name or string.sub(name, 1, #PREFIX) ~= PREFIX then return nil end
    return tonumber(string.sub(name, #PREFIX + 1))
end

local function alive(obj)
    return obj:getSquare() ~= nil and obj:getObjectIndex() ~= -1
end

function V.track(obj)
    if known[obj] or not LiveWire.Defs.modelOfObject(obj) then return end
    known[obj] = true
    V.tracked[#V.tracked + 1] = obj
end

-- Find our devices around the player (new placements, chunks loaded).
local function scan(player)
    local cell = getCell()
    local px, py, pz = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    local r = V.SCAN_RADIUS
    for z = pz - 1, pz + 1 do
        for x = px - r, px + r do
            for y = py - r, py + r do
                local sq = cell:getGridSquare(x, y, z)
                if sq then
                    local objs = sq:getObjects()
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if not known[o] and spriteIndex(o) then V.track(o) end
                    end
                end
            end
        end
    end
    for i = #V.tracked, 1, -1 do
        local o = V.tracked[i]
        if not alive(o) then
            known[o] = nil
            table.remove(V.tracked, i)
        end
    end
end

-- Blade frame of a wind turbine (0-3), or 0 when it does not turn.
local function rotorFrame(obj, mark, now)
    local wind = getClimateManager():getWindspeedKph()
    if wind < V.WIND_CUT_IN or (mark and (mark.cond or 100) <= 0) then return 0 end
    local period = math.max(70, math.floor(600 - wind * 8))
    local offset = (obj:getSquare():getX() * 7 + obj:getSquare():getY() * 13) % 4
    return (math.floor(now / period) + offset) % 4
end

-- Overlays wanted on `obj`, as a sorted list of sprite indices.
function V.wanted(obj, now)
    local idx = spriteIndex(obj)
    local model = LiveWire.Defs.modelOfObject(obj)
    local def = model and LiveWire.Defs.devices[model]
    if not idx or not def or idx >= FIRST_OVERLAY then return {} end
    local f = idx - def.tile
    local m = LiveWire.Marks.get(obj)
    local out = {}
    local function add(i)
        if EXISTS[i] then out[#out + 1] = i end
    end
    if model == "Inverter" then
        if m and m.st == "on" then add(24 + f) end
        if m and (m.st == "tripped" or m.st == "broken") then add(28 + f) end
    elseif model == "PowerBank" then
        if m and m.inv then add(32 + f) end
    elseif model == "SolarPanel" then
        if m and m.inv then add(36 + f) end
    elseif model == "WindTurbine" then
        if m and m.inv then add(40 + f) end
        add(48 + 4 * rotorFrame(obj, m, now) + f)
    elseif model == "WaterWheel" then
        if m and m.inv then add(44 + f) end
    elseif model == "Breaker" then
        if m and m.st == "tripped" then add(64 + f) end
    elseif model == "BatteryAlarm" then
        if m and m.st == "ringing" then add(66 + f) end
    end
    table.sort(out)
    return out
end

-- Our overlays currently on `obj` (sprite indices, sorted) and their list positions.
local function current(obj)
    local list = obj:getAttachedAnimSprite()
    local idx, pos = {}, {}
    if not list then return idx, pos end
    for i = 0, list:size() - 1 do
        local inst = list:get(i)
        local spr = inst and inst:getParentSprite()
        local name = spr and spr:getName()
        if name and string.sub(name, 1, #PREFIX) == PREFIX then
            local n = tonumber(string.sub(name, #PREFIX + 1))
            if n and n >= FIRST_OVERLAY then
                idx[#idx + 1] = n
                pos[#pos + 1] = i
            end
        end
    end
    table.sort(idx)
    return idx, pos
end

local function same(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i] ~= b[i] then return false end
    end
    return true
end

-- A wind turbine changes its blade overlay up to ten times a second. Objects are
-- otherwise drawn once into the chunk render texture (FBO) and redrawn only when
-- the chunk is invalidated; an object flagged as animating is drawn every frame
-- instead (FBORenderCell.isObjectRenderLayer_MinusFloor, FBORenderCell.java:1627).
-- Without it, the turning blades vanished as soon as the wind made them turn.
function V.apply(obj, now)
    if LiveWire.Defs.modelOfObject(obj) == "WindTurbine" and not obj:isAnimating() then
        obj:setAnimating(true)
    end
    local want = V.wanted(obj, now)
    local have, pos = current(obj)
    if same(want, have) then return end
    for i = #pos, 1, -1 do obj:RemoveAttachedAnim(pos[i]) end
    for i = 1, #want do obj:addAttachedAnimSpriteByName(PREFIX .. tostring(want[i])) end
end

-- Inverters seen by this client (for the hum).
function V.inverters()
    local out = {}
    for i = 1, #V.tracked do
        local o = V.tracked[i]
        if LiveWire.Defs.modelOfObject(o) == "Inverter" then out[#out + 1] = o end
    end
    return out
end

local function onTick()
    local player = getPlayer()
    if not player then return end
    local now = getTimestampMs()
    if now - lastScan >= V.SCAN_MS then
        lastScan = now
        scan(player)
    end
    local all = now - lastState >= V.STATE_MS
    if not all and now - lastFrame < V.FRAME_MS then return end
    lastFrame = now
    if all then lastState = now end
    for i = 1, #V.tracked do
        local o = V.tracked[i]
        if alive(o) and (all or LiveWire.Defs.modelOfObject(o) == "WindTurbine") then V.apply(o, now) end
    end
end

Events.OnTick.Add(onTick)
