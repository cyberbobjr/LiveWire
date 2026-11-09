if isClient() then return end
-- LiveWire Extended: link, unlink and forget the sub-mod objects tied to an inverter
-- (LWX_Link kinds), on the authority. A kind may add:
--   onLink(record, dev, key)  after the record is stored (a terminal adds its zone)
--   onForget(record, key)     after the record is dropped (areas, breakers...)
-- A record also keeps the inverter square (ix, iy, iz) and the wire spent (wires).
-- The linked object carries a copy of its link in its own ModData (SL.MARK_KEY), so
-- that a link newer than the saved global ModData can be rebuilt (LWX_Recovery).
require "Moveables/ISMoveableSpriteProps"
require "LiveWireExtended/LWX_Connect"
require "LiveWireExtended/LWX_Inverters"
require "LiveWireExtended/LWX_Link"

local X = LiveWire.Extended
local D, L, Inv = X.Data, X.Link, X.Inverters
local SL = {}
X.Linked = SL

SL.MARK_KEY = "LiveWireExtendedLink"

local function transmit()
    if isServer() then ModData.transmit(X.DATA_KEY) end
end

-- Copy of the link in the object's ModData: inverter id and square, wire spent and,
-- for a breaker board, its breakers (labels and wired points are not kept).
function SL.markObject(obj, record)
    local slots = nil
    if type(record.slots) == "table" then
        slots = {}
        for i, s in ipairs(record.slots) do
            slots[i] = { type = s.type, pos = s.pos, poles = s.poles, amps = s.amps, volts = s.volts }
        end
    end
    obj:getModData()[SL.MARK_KEY] = { inv = record.inv, x = record.x, y = record.y, z = record.z,
        ix = record.ix, iy = record.iy, iz = record.iz, wires = record.wires, slots = slots,
        prewired = record.prewired }
end

local function clearMark(kind, record)
    local sq = getCell():getGridSquare(record.x, record.y, record.z)
    local obj = sq and L.objectOn(kind, sq)
    if obj and obj:hasModData() then obj:getModData()[SL.MARK_KEY] = nil end
end

-- Wire spent on the link of `record`. Records made before it was kept use the
-- cable rule on the distance to the inverter.
function SL.wires(record)
    if type(record.wires) == "number" then return math.max(0, math.floor(record.wires)) end
    local dev = Inv.get(record.inv)
    local ix, iy, iz = record.ix, record.iy, record.iz
    if not ix and dev then ix, iy, iz = dev.x, dev.y, dev.z end
    if not ix then return 0 end
    local API = LiveWire.API
    return API.wiresFor((API.distance(record.x, record.y, record.z, ix, iy, iz)))
end

-- Store the record of `kind` object `obj` linked to inverter `dev`. Returns it.
local function store(kind, obj, dev, wires)
    local sq = obj:getSquare()
    local key = L.key(sq:getX(), sq:getY(), sq:getZ())
    local record = { x = sq:getX(), y = sq:getY(), z = sq:getZ(), inv = dev.id,
        ix = dev.x, iy = dev.y, iz = dev.z, wires = wires }
    L.records(kind)[key] = record
    return record, key
end

-- Link object `obj` to the inverter object `invObj`. Returns true when linked.
function SL.link(character, obj, invObj)
    local ok, why, arg1, arg2 = L.check(character, obj, invObj)
    if not ok then
        LiveWire.notify(character, why, { arg1, arg2 }, true)
        return false
    end
    local kind = L.kindOf(obj)
    local dev = Inv.ofObject(invObj)
    if not dev then
        LiveWire.notify(character, "Tooltip_LWX_NoInverter", {}, true)
        return false
    end
    local wires = arg1 or 0
    if wires > 0 and not LiveWire.API.consume(character, X.WIRE, wires) then return false end
    local record, key = store(kind, obj, dev, wires)
    if kind.onLink then kind.onLink(record, dev, key, obj) end
    SL.markObject(obj, record)
    transmit()
    LiveWire.notify(character, kind.linkedNote, {})
    X.log(kind.name .. " " .. key .. " linked to " .. tostring(dev.id) .. " with " .. wires .. " wires")
    return true
end

-- Rebuild the record of `kind` object `obj` from its mark `m` (LWX_Recovery), linked
-- to the registry inverter `dev`: no wire spent, a board gets its breakers back.
function SL.restore(kind, obj, dev, m)
    local record, key = store(kind, obj, dev, tonumber(m.wires))
    record.prewired = m.prewired == true or nil
    if kind.onLink then kind.onLink(record, dev, key, obj) end
    if type(record.slots) == "table" and type(m.slots) == "table" then
        record.slots = {}
        for i, s in ipairs(m.slots) do
            record.slots[i] = { type = s.type, pos = s.pos, poles = s.poles, amps = s.amps, volts = s.volts,
                label = "", off = false, tripped = false, points = {} }
        end
    end
    SL.markObject(obj, record)
    transmit()
    X.log(kind.name .. " " .. key .. " recovered, linked to " .. tostring(dev.id))
    return record
end

-- Forget the `kind` record `key` and what hangs on it.
function SL.forget(kind, key)
    local list = L.records(kind)
    local record = list[key]
    if not record then return false end
    list[key] = nil
    clearMark(kind, record)
    if kind.onForget then kind.onForget(record, key) end
    transmit()
    X.log(kind.name .. " " .. key .. " unlinked")
    return true
end

-- Unlink by a player: the wire of the link comes back.
function SL.unlink(character, obj)
    local kind = L.kindOf(obj)
    local sq = obj and obj:getSquare()
    local record = kind and sq and L.recordAt(kind, sq)
    local wires = record and SL.wires(record) or 0
    if not record or not SL.forget(kind, L.key(sq:getX(), sq:getY(), sq:getZ())) then return false end
    LiveWire.notify(character, kind.unlinkedNote, {})
    LiveWire.API.returnWires(character, wires)
    return true
end

-- Picked up or destroyed: drop its record.
local function onRemoved(obj)
    local kind = obj and L.kindOf(obj)
    local sq = kind and obj:getSquare()
    if sq then SL.forget(kind, L.key(sq:getX(), sq:getY(), sq:getZ())) end
end

-- Picked up by a player: the wire of its link comes back (onRemoved, which drops the
-- record, does not know who picked the object up). Destroyed: the wire is lost.
local MP = ISMoveableSpriteProps
if MP and MP.pickUpMoveableInternal then
    local origPickUp = MP.pickUpMoveableInternal
    function MP:pickUpMoveableInternal(_character, _square, _object, _sprInstance, ...)
        local wires = 0
        local kind = _object and not _sprInstance and L.kindOf(_object)
        local sq = kind and _object:getSquare()
        local record = sq and L.recordAt(kind, sq)
        if record then wires = SL.wires(record) end
        local r = origPickUp(self, _character, _square, _object, _sprInstance, ...)
        if wires > 0 and _object:getObjectIndex() == -1 then LiveWire.API.returnWires(_character, wires) end
        return r
    end
end

-- The inverter of `record` is gone for good. An inverter missing from the registry
-- may only wait for its recovery (Live Wire, Devices.recover): the record stays while
-- the inverter square is not loaded or still holds an inverter marked with its id.
local function inverterGone(record)
    if Inv.get(record.inv) then return false end
    if LiveWire.API.deviceKnown(record.inv) then return true end  -- known, but no longer a master
    if not record.ix then return true end                -- records made before ix was kept
    local sq = getCell():getGridSquare(record.ix, record.iy, record.iz)
    if not sq then return false end
    return LiveWire.API.markOnSquare(sq, record.inv) == nil
end

-- Records of removed inverters, and records whose square is loaded without the object.
-- Records made before the inverter square was kept learn it here.
function SL.prune()
    local any = false
    for _, kind in ipairs(L.kinds) do
        local stale = {}
        for key, r in pairs(L.records(kind)) do
            local dev = Inv.get(r.inv)
            if dev and not r.ix then r.ix, r.iy, r.iz = dev.x, dev.y, dev.z end
            if inverterGone(r) then
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
