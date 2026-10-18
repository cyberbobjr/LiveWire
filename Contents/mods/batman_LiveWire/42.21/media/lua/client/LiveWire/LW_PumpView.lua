-- Live Wire: "Show the supplied taps" on a water pump (client only, local display).
-- Draws a blue circle of PumpRange tiles around the pump (LW_RangeView.lua) and
-- highlights, in blue, the pump, the barrels linked to it, and every plumbed fixture
-- it supplies. A fixture is supplied when vanilla finds one of this pump's relay
-- tanks as its external water source (IsoObject.FindExternalWaterSource).
-- The highlight is re-applied on every refresh: another code may clear it.
if isServer() then return end

LiveWire = LiveWire or {}

local PV = {}
LiveWire.PumpView = PV

PV.REFRESH_MS = 2000
PV.obj = nil            -- the pump object shown
PV.id = nil             -- its device id (mark)
PV.hl = {}              -- object -> true, objects currently highlighted by this view
PV.lastRefresh = 0

local function defs() return LiveWire.Defs end

local function hasWaterPipe(o)
    local spr = o:getSprite()
    local props = spr and spr:getProperties()
    return props ~= nil and props:has(IsoFlagType.waterPiped)
end

-- True when `src` (a water source found above a fixture) is one of this pump's relays.
local function servedBy(src, id)
    if LiveWire.Install.isRelay(src) then
        local m = src:getModData()[defs().RELAY_KEY]
        return m ~= nil and m.pump == id
    end
    -- Relay ModData not received by this client (not yet streamed): accept any relay,
    -- recognised by its tile only. Vanilla barrels have another sprite.
    local spr = src:getSprite()
    return spr ~= nil and spr:getName() == defs().RELAY_SPRITE
end

-- Objects to highlight: the pump, its linked barrels, and the fixtures it supplies.
-- Returns an array and a set (object -> true).
local function collect(pumpSq, id)
    local list, set = {}, {}
    local function add(o)
        if o and not set[o] then
            set[o] = true
            list[#list + 1] = o
        end
    end
    add(PV.obj)

    local barrels = LiveWire.Install.barrelsInRange(pumpSq)
    for i = 1, #barrels do
        local m = LiveWire.Install.barrelMark(barrels[i].obj)
        if m and m.pump == id then add(barrels[i].obj) end
    end

    local cell = getCell()
    local px, py, pz = pumpSq:getX(), pumpSq:getY(), pumpSq:getZ()
    local range = LiveWire.Config.get("PumpRange")
    local r = math.floor(range)
    local r2 = range * range
    local vertical = LiveWire.Config.verticalRange()
    for z = pz - vertical, pz + vertical do
        for x = px - r, px + r do
            for y = py - r, py + r do
                local dx, dy = x - px, y - py
                if dx * dx + dy * dy <= r2 then
                    local sq = cell:getGridSquare(x, y, z)
                    if sq and sq:getRoom() ~= nil then
                        local objs = sq:getObjects()
                        local src, looked = nil, false
                        for i = 0, objs:size() - 1 do
                            local o = objs:get(i)
                            if not instanceof(o, "IsoWorldInventoryObject") and hasWaterPipe(o) then
                                if not looked then
                                    src = IsoObject.FindExternalWaterSource(sq)
                                    looked = true
                                end
                                if src ~= nil and servedBy(src, id) then add(o) end
                            end
                        end
                    end
                end
            end
        end
    end
    return list, set
end

-- Un-highlight every object this view highlighted (keys collected first).
local function clearHighlights()
    local player = getPlayer()
    local objs = {}
    for o in pairs(PV.hl) do objs[#objs + 1] = o end
    for i = 1, #objs do
        if player then objs[i]:setHighlighted(player:getPlayerNum(), false, false) end
    end
    PV.hl = {}
end

function PV.isShown(id)
    return PV.id ~= nil and PV.id == id
end

function PV.hide()
    clearHighlights()
    if PV.id and LiveWire.RangeView.isShown(PV.id) then LiveWire.RangeView.hide() end
    PV.obj, PV.id = nil, nil
end

-- Re-collect the supplied objects and update the highlights.
function PV.refresh()
    if not PV.id then return end
    -- The circle was replaced (inverter range shown) or the view was closed elsewhere.
    if not LiveWire.RangeView.isShown(PV.id) then
        PV.hide()
        return
    end
    local player = getPlayer()
    local sq = PV.obj and PV.obj:getSquare()
    if not player or not sq then return end
    local idx = player:getPlayerNum()
    local list, set = collect(sq, PV.id)
    -- Un-highlight what is no longer supplied (keys collected first).
    local old = {}
    for o in pairs(PV.hl) do old[#old + 1] = o end
    for i = 1, #old do
        if not set[old[i]] then
            old[i]:setHighlighted(idx, false, false)
            PV.hl[old[i]] = nil
        end
    end
    for i = 1, #list do
        local o = list[i]
        o:setHighlightColor(idx, 0.30, 0.55, 1.0, 1.0)
        o:setHighlighted(idx, true, false)
        PV.hl[o] = true
    end
end

-- Show the circle and the highlights for the pump object `pumpObj`.
function PV.show(pumpObj)
    PV.hide()
    local mark = LiveWire.Marks.get(pumpObj)
    local sq = pumpObj:getSquare()
    if not mark or not sq then return end
    PV.obj, PV.id = pumpObj, mark.id
    LiveWire.RangeView.show(mark.id, sq:getX(), sq:getY(), sq:getZ(), {
        radius = LiveWire.Config.get("PumpRange"),
        color = LiveWire.RangeView.PUMP_COLOR,
    })
    PV.lastRefresh = getTimestampMs()
    PV.refresh()
end

local function onTick()
    if not PV.id then return end
    local obj = PV.obj
    local sq = obj and obj:getSquare()
    if not sq or obj:getObjectIndex() == -1 then
        PV.hide()
        return
    end
    local player = getPlayer()
    if not player then return end
    local dx, dy = player:getX() - sq:getX(), player:getY() - sq:getY()
    if dx * dx + dy * dy > LiveWire.RangeView.HIDE_DISTANCE * LiveWire.RangeView.HIDE_DISTANCE then
        PV.hide()
        return
    end
    local now = getTimestampMs()
    if now - PV.lastRefresh >= PV.REFRESH_MS then
        PV.lastRefresh = now
        PV.refresh()
    end
end

Events.OnTick.Add(onTick)
