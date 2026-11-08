if isClient() then return end
-- LiveWire Extended: link, unlink and forget the sub-mod objects tied to an inverter
-- (LWX_Link kinds), on the authority. A kind may add:
--   onLink(record, dev, key)  after the record is stored (a terminal adds its zone)
--   onForget(record, key)     after the record is dropped (areas, breakers...)
require "LiveWireExtended/LWX_Connect"
require "LiveWireExtended/LWX_Link"

local X = LiveWire.Extended
local D, C, L = X.Data, X.Connect, X.Link
local SL = {}
X.Linked = SL

local function transmit()
    if isServer() then ModData.transmit(X.DATA_KEY) end
end

-- Link object `obj` to the inverter object `invObj`. Returns true when linked.
function SL.link(character, obj, invObj)
    local ok, why, arg1, arg2 = L.check(character, obj, invObj)
    if not ok then
        LiveWire.notify(character, why, { arg1, arg2 }, true)
        return false
    end
    local kind = L.kindOf(obj)
    local dev = X.inverterOf(invObj)
    if not dev then
        LiveWire.notify(character, "Tooltip_LWX_NoInverter", {}, true)
        return false
    end
    local wires = arg1 or 0
    if wires > 0 and not LiveWire.Install.consume(character, "Base.ElectricWire", wires) then return false end
    local sq = obj:getSquare()
    local key = L.key(sq:getX(), sq:getY(), sq:getZ())
    local record = { x = sq:getX(), y = sq:getY(), z = sq:getZ(), inv = dev.id }
    L.records(kind)[key] = record
    if kind.onLink then kind.onLink(record, dev, key, obj) end
    transmit()
    LiveWire.notify(character, kind.linkedNote, {})
    X.log(kind.name .. " " .. key .. " linked to " .. tostring(dev.id) .. " with " .. wires .. " wires")
    return true
end

-- Forget the `kind` record `key` and what hangs on it.
function SL.forget(kind, key)
    local list = L.records(kind)
    local record = list[key]
    if not record then return false end
    list[key] = nil
    if kind.onForget then kind.onForget(record, key) end
    transmit()
    X.log(kind.name .. " " .. key .. " unlinked")
    return true
end

function SL.unlink(character, obj)
    local kind = L.kindOf(obj)
    local sq = obj and obj:getSquare()
    if not kind or not sq or not SL.forget(kind, L.key(sq:getX(), sq:getY(), sq:getZ())) then return false end
    LiveWire.notify(character, kind.unlinkedNote, {})
    return true
end

-- Picked up or destroyed: drop its record.
local function onRemoved(obj)
    local kind = obj and L.kindOf(obj)
    local sq = kind and obj:getSquare()
    if sq then SL.forget(kind, L.key(sq:getX(), sq:getY(), sq:getZ())) end
end

-- Records of removed inverters, and records whose square is loaded without the object.
function SL.prune()
    local any = false
    for _, kind in ipairs(L.kinds) do
        local stale = {}
        for key, r in pairs(L.records(kind)) do
            if not C.inverter(r.inv) then
                stale[#stale + 1] = key
            else
                local sq = getCell():getGridSquare(r.x, r.y, r.z)
                if sq and not L.objectOn(kind, sq) then stale[#stale + 1] = key end
            end
        end
        for i = 1, #stale do SL.forget(kind, stale[i]) end
        if #stale > 0 then any = true end
    end
    return any
end

Events.OnObjectAboutToBeRemoved.Add(onRemoved)
Events.EveryHours.Add(SL.prune)
