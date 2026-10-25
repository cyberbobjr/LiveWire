-- Live Wire: state lights and moving parts of the placed devices, drawn locally on
-- each client as tile overlays (attachedAnimSprite, IsoObject.java:1821-1880):
--   inverter: lit screen when on, red light when tripped or broken, acoustic
--             foam panels when soundproofed;
--   power bank and sources: green light when connected to an inverter;
--   wind turbine: blades (the tile has none), turning with the wind;
--   breaker: green while supplied, red when tripped; pump: blue LCD glow while
--            supplied; alarm: lit beacon while it rings.
-- The state comes from the device mark (modData.movableData.LiveWire, sent by the
-- server: st, pw, inv). Only our own overlays (24-71 and 80-87) are touched; the list
-- is rebuilt from the mark whenever it differs, so overlays saved with a single
-- player world are corrected at the next update.
-- Devices are tracked when their chunk loads, when the server adds them (MP), by a small scan around the player and a slow spread sweep (no full scan in one frame).
if isServer() then return end

LiveWire = LiveWire or {}

local V = {}
LiveWire.Visuals = V

local PREFIX = LiveWire.Defs.SHEET .. "_"
local FIRST_OVERLAY = 24
local LAST_OVERLAY = 71   -- 72-75 are the water pump (base device), 76 the relay tank

-- Overlay sprite indices: 24-71 (inverter, sources, breaker, alarm, wind blades) and
-- 80-87 (water pump light, breaker green light; 86-87 remain reserved).
local function isOverlay(n)
    return (n >= FIRST_OVERLAY and n <= LAST_OVERLAY) or (n >= 80 and n <= 87)
end

-- Overlay sprites that exist in the pack (lights on the front are not drawn for the
-- N and W facings, where the front is hidden).
local EXISTS = {}
for _, i in ipairs({ 24, 25, 28, 29, 32, 33, 36, 37, 40, 41, 44, 45, 64, 65, 66, 67, 68, 69, 70, 71 }) do
    EXISTS[i] = true
end
for i = 48, 63 do EXISTS[i] = true end
for i = 80, 83 do EXISTS[i] = true end   -- pump light on top of the motor: all four facings
EXISTS[84], EXISTS[85] = true, true      -- breaker supplied: S/E wall facings

V.NEAR_RADIUS = 4      -- squares around the player checked every NEAR_MS (single player placement)
V.NEAR_MS = 1000
V.SWEEP_RADIUS = 18    -- fallback sweep of the old scan area, spread over ticks
V.SWEEP_MS = 30000
V.PRUNE_DIST = 160     -- tracked objects farther than this (tiles) are dropped
V.STATE_MS = 1000
V.FRAME_MS = 100
V.WIND_CUT_IN = 10   -- km/h, same as the simulation (LW_Physics.lua)

V.tracked = {}       -- list of objects
local known = {}     -- object -> true
local lastState, lastFrame, lastNear, lastSweep = 0, 0, 0, 0
local SPRITES = LiveWire.Defs.spriteToModel
local sweep = nil      -- { x, x1, y0, y1, z0, z1 } while a sweep is running

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

-- Track our base tiles found on a square (one table lookup per object).
local function considerSquare(sq)
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if not known[o] then
            local spr = o:getSprite()
            local name = spr and spr:getName()
            if name and SPRITES[name] then V.track(o) end
        end
    end
end

-- Every chunk loaded on this client (fires on both sides: IsoChunk.java:3612).
local function onLoadChunk(chunk)
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for i = 0, 63 do
            local sq = chunk:getGridSquare(i % 8, math.floor(i / 8), z)
            if sq then considerSquare(sq) end
        end
    end
end

-- Objects added by the server (MP clients only: AddItemToMapPacket.java:90).
local function onObjectAdded(obj)
    if obj and obj.getSprite and not known[obj] and LiveWire.Defs.modelOfObject(obj) then V.track(obj) end
end

-- New placements in single player (OnObjectAdded does not fire there).
local function nearScan(player)
    local cell = getCell()
    local px, py, pz = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    local r = V.NEAR_RADIUS
    for x = px - r, px + r do
        for y = py - r, py + r do
            local sq = cell:getGridSquare(x, y, pz)
            if sq then considerSquare(sq) end
        end
    end
end

-- Fallback: the old 37 x 37 x 3 area, one column per tick.
local function startSweep(player)
    local px, py, pz = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    local r = V.SWEEP_RADIUS
    sweep = { x = px - r, x1 = px + r, y0 = py - r, y1 = py + r, z0 = pz - 1, z1 = pz + 1 }
end

local function sweepStep()
    local cell = getCell()
    local x = sweep.x
    for z = sweep.z0, sweep.z1 do
        for y = sweep.y0, sweep.y1 do
            local sq = cell:getGridSquare(x, y, z)
            if sq then considerSquare(sq) end
        end
    end
    sweep.x = x + 1
    if sweep.x > sweep.x1 then sweep = nil end
end

-- Drop dead or far objects.
local function prune(player)
    local px, py = player:getX(), player:getY()
    local d2 = V.PRUNE_DIST * V.PRUNE_DIST
    for i = #V.tracked, 1, -1 do
        local o = V.tracked[i]
        local keep = alive(o)
        if keep then
            local sq = o:getSquare()
            local dx, dy = sq:getX() - px, sq:getY() - py
            keep = dx * dx + dy * dy <= d2
        end
        if not keep then
            known[o] = nil
            table.remove(V.tracked, i)
            if LiveWire.Adopt then LiveWire.Adopt.forget(o) end
        end
    end
end

-- Blade frame of a wind turbine (0-3), or 0 when it does not turn.
local function rotorFrame(obj, mark, now)
    local wind = getClimateManager():getWindspeedKph()
    if wind < V.WIND_CUT_IN or (mark and ((mark.cond or 100) <= 0 or mark.br)) then return 0 end
    local period = math.max(70, math.floor(600 - wind * 8))
    local offset = (obj:getSquare():getX() * 7 + obj:getSquare():getY() * 13) % 4
    return (math.floor(now / period) + offset) % 4
end

-- Overlays wanted on `obj`, as a sorted list of sprite indices.
function V.wanted(obj, now)
    local idx = spriteIndex(obj)
    local model = LiveWire.Defs.modelOfObject(obj)
    local def = model and LiveWire.Defs.devices[model]
    if not idx or not def or isOverlay(idx) then return {} end
    local f = idx - def.tile
    local m = LiveWire.Marks.get(obj)
    local out = {}
    local function add(i)
        if EXISTS[i] then out[#out + 1] = i end
    end
    if model == "Inverter" then
        if m and m.st == "on" then add(24 + f) end
        if m and (m.st == "tripped" or m.st == "broken") then add(28 + f) end
        if m and m.muf then add(68 + f) end
    elseif model == "PowerBank" then
        if m and m.inv then add(32 + f) end
    elseif model == "SolarPanel" then
        if m and m.inv then add(36 + f) end
    elseif model == "WindTurbine" then
        if m and m.inv and (not m.br or math.floor(now / 500) % 2 == 0) then add(40 + f) end
        add(48 + 4 * rotorFrame(obj, m, now) + f)
    elseif model == "WaterWheel" then
        if m and m.inv then add(44 + f) end
    elseif model == "Breaker" then
        if m and m.st == "tripped" then add(64 + f)
        elseif m and m.inv and m.pw and (m.cond or 0) > 0 then add(84 + f) end
    elseif model == "BatteryAlarm" then
        if m and m.st == "ringing" then add(66 + f) end
    elseif model == "WaterPump" then
        -- LCD glow while supplied, including an idle pump with no linked fixture.
        if m and m.inv and m.pw and (m.cond or 0) > 0 then add(80 + f) end
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
            if n and isOverlay(n) then
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

-- Water pumps seen by this client (for the pump hum). No overlay for the pump.
function V.pumps()
    local out = {}
    for i = 1, #V.tracked do
        local o = V.tracked[i]
        if LiveWire.Defs.modelOfObject(o) == "WaterPump" then out[#out + 1] = o end
    end
    return out
end

local function onTick()
    local player = getPlayer()
    if not player then return end
    local now = getTimestampMs()
    if sweep then
        sweepStep()
    elseif now - lastSweep >= V.SWEEP_MS then
        lastSweep = now
        startSweep(player)
    end
    if now - lastNear >= V.NEAR_MS then
        lastNear = now
        nearScan(player)
    end
    local all = now - lastState >= V.STATE_MS
    if not all and now - lastFrame < V.FRAME_MS then return end
    lastFrame = now
    if all then
        lastState = now
        prune(player)
    end
    for i = 1, #V.tracked do
        local o = V.tracked[i]
        if alive(o) and (all or LiveWire.Defs.modelOfObject(o) == "WindTurbine") then
            V.apply(o, now)
            if all and LiveWire.Adopt then LiveWire.Adopt.check(o, now) end
        end
    end
end

Events.LoadChunk.Add(onLoadChunk)
Events.OnObjectAdded.Add(onObjectAdded)
Events.OnTick.Add(onTick)
