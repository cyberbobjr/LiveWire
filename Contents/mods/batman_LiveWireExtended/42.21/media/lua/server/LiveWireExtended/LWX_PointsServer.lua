if isClient() then return end
-- LiveWire Extended: wiring points to breakers on the authority (D-36, D-37, D-41).
-- The cut decision of every adapter is X.Points.blocked: for vanilla families Live Wire
-- asks it through the circuit provider and cuts with its I21 service adapters.
require "LiveWireExtended/LWX_Points"
require "LiveWireExtended/LWX_Panels"

local X = LiveWire.Extended
local PT, Ad, B, P = X.Points, X.Adapters, X.Breakers, X.Panel
local PS = X.Panels

Ad.isCut = function(o) return PT.blocked(o) end

local function transmit()
    if isServer() then ModData.transmit(X.DATA_KEY) end
end

-- Apply the current decision to point `o` (vanilla: through LiveWire.Circuits).
function PT.apply(o)
    local a = Ad.find(o)
    if a then a.apply(o, PT.blocked(o)) end
end

-- Loaded objects of point `key` recorded at p.x, p.y, p.z.
function PT.objectsOf(key, p)
    local out = {}
    local sq = getCell():getGridSquare(p.x, p.y, p.z)
    local objs = sq and sq:getObjects()
    for i = 0, objs and objs:size() - 1 or -1 do
        local o = objs:get(i)
        if Ad.find(o) and Ad.identity(o) == key then out[#out + 1] = o end
    end
    return out
end

local function applyKeys(keys)
    for key, p in pairs(keys) do
        for _, o in ipairs(PT.objectsOf(key, p)) do PT.apply(o) end
    end
end

-- Served regions changed (a board linked or forgotten): revisit every appliance of
-- Live Wire's inventories, progressively (LiveWire.Circuits queue).
function PT.regionsChanged()
    PT.changed()
    if LiveWire.Circuits then LiveWire.Circuits.topologyChanged() end
end

-- Drop the points of a breaker slot of board `boardKey`; returns them (key -> point).
local function dropSlotPoints(slot)
    local dropped, points = {}, PT.table()
    for key in pairs(slot.points or {}) do
        dropped[key] = points[key]
        points[key] = nil
    end
    slot.points = {}
    return dropped
end

function PT.connect(character, o, boardObj, pos)
    local ok, why, arg1, arg2 = PT.checkConnect(character, o, boardObj, pos)
    if not ok then
        LiveWire.notify(character, why, { arg1, arg2 }, true)
        return false
    end
    local wires = why or 0
    if wires > 0 and not LiveWire.Install.consume(character, "Base.ElectricWire", wires) then return false end
    local bsq, sq = boardObj:getSquare(), o:getSquare()
    local boardKey = X.Link.key(bsq:getX(), bsq:getY(), bsq:getZ())
    local record = P.recordAt(bsq)
    local slot = B.slotAt(record, tonumber(pos))
    local key = Ad.identity(o)
    PT.table()[key] = { board = boardKey, pos = slot.pos, x = sq:getX(), y = sq:getY(), z = sq:getZ(),
        adapter = Ad.find(o).id }
    slot.points = slot.points or {}
    slot.points[key] = true
    LiveWire.Xp.awardLimited(character, "lwx:" .. key, PT.XP, 24)
    transmit()
    PT.apply(o)
    LiveWire.notify(character, "IGUI_LWX_PointConnected", { tostring(slot.pos) })
    X.log("point " .. key .. " wired to module " .. slot.pos .. " of board " .. boardKey .. " with " .. wires .. " wires")
    return true
end

function PT.disconnect(character, o)
    local key = Ad.identity(o)
    local p = PT.point(key)
    if not p then return false end
    local slot = PT.slotOf(p)
    if slot and slot.points then slot.points[key] = nil end
    PT.table()[key] = nil
    transmit()
    PT.apply(o)
    LiveWire.notify(character, "IGUI_LWX_PointDisconnected", {})
    X.log("point " .. key .. " unwired")
    return true
end

-- Apply the decision to every point of a breaker slot.
function PT.applySlot(slot)
    local keys = {}
    for key in pairs(slot.points or {}) do keys[key] = PT.point(key) end
    applyKeys(keys)
end

-- Open (off = true) or close the breaker of module `pos`.
function PS.setBreaker(character, boardObj, pos, off)
    local record = P.isPanel(boardObj) and P.recordAt(boardObj:getSquare())
    if not record then return false end
    local slot = B.slotAt(record, tonumber(pos))
    if not slot or type(off) ~= "boolean" then return false end
    -- Switching on also resets a tripped breaker (E18).
    if slot.off ~= off or (not off and slot.tripped) then
        slot.off = off
        if not off then slot.tripped = false end
        transmit()
        PT.applySlot(slot)
    end
    LiveWire.notify(character, off and "IGUI_LWX_BreakerOff" or "IGUI_LWX_BreakerOn", { tostring(slot.pos) })
    return true
end

-- A breaker leaves its board: its points are unwired.
local previousRemoved = PS.onBreakerRemoved
PS.onBreakerRemoved = function(record, slot)
    if previousRemoved then previousRemoved(record, slot) end
    applyKeys(dropSlotPoints(slot))
end

-- A board is linked or forgotten: regions change; a forgotten board unwires its points.
local previousLink, previousForget = P.kind.onLink, P.kind.onForget
P.kind.onLink = function(...)
    if previousLink then previousLink(...) end
    PT.regionsChanged()
end
P.kind.onForget = function(record, key)
    if previousForget then previousForget(record, key) end
    local dropped = {}
    for _, slot in ipairs(record.slots or {}) do
        for k, p in pairs(dropSlotPoints(slot)) do dropped[k] = p end
    end
    PT.regionsChanged()
    applyKeys(dropped)
end
