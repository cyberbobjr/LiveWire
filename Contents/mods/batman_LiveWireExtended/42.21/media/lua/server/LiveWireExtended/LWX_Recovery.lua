if isClient() then return end
-- LiveWire Extended: rebuild the link of a terminal or breaker board that the saved
-- global ModData does not hold (the map chunk was saved after it: crash, forced quit,
-- restored backup). The object carries a copy of its link (LWX_Linked.markObject);
-- Live Wire's chunk discovery walk shows every loaded object to RC.visit. The copy is
-- refreshed every ten minutes so that later breakers are kept too.
require "LiveWireExtended/LWX_Linked"
require "LiveWireExtended/LWX_Inverters"

local X = LiveWire.Extended
local L, SL, Inv = X.Link, X.Linked, X.Inverters
local RC = {}
X.Recovery = RC

RC.pending = {}  -- "x,y,z" -> kind: the inverter was not recovered yet

-- Rebuild the link of `obj` when its mark names a registry inverter and no record
-- holds its square. Returns the rebuilt record or nil.
function RC.visit(obj)
    local kind = L.kindOf(obj)
    if not kind or not obj:hasModData() then return nil end
    local md = obj:getModData()
    local m = md[SL.MARK_KEY]
    local sq = type(m) == "table" and obj:getSquare()
    if not sq then return nil end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local key = L.key(x, y, z)
    -- Moved since it was linked: the copy belongs to its old square.
    if m.x ~= x or m.y ~= y or m.z ~= z then
        md[SL.MARK_KEY] = nil
        return nil
    end
    RC.pending[key] = nil
    if L.records(kind)[key] then return nil end
    local dev = Inv.get(m.inv)
    if not dev then
        -- Still unknown: Live Wire may recover it when its chunk loads.
        if not LiveWire.API.deviceKnown(m.inv) then RC.pending[key] = kind end
        return nil
    end
    -- The same inverter, on the square the link was made to.
    if m.ix and (dev.x ~= m.ix or dev.y ~= m.iy or dev.z ~= m.iz) then return nil end
    return SL.restore(kind, obj, dev, m)
end

-- Every ten minutes: retry the objects whose inverter was missing, and refresh the
-- copy of every loaded linked object.
function RC.tick()
    if not LiveWire.API.writable() then return end
    local cell = getCell()
    local retry = RC.pending
    RC.pending = {}
    for key, kind in pairs(retry) do
        local x, y, z = string.match(key, "^(-?%d+),(-?%d+),(-?%d+)$")
        local sq = x and cell:getGridSquare(tonumber(x), tonumber(y), tonumber(z))
        local obj = sq and L.objectOn(kind, sq)
        if obj then RC.visit(obj) end
    end
    for _, kind in ipairs(L.kinds) do
        for _, r in pairs(L.records(kind)) do
            local sq = cell:getGridSquare(r.x, r.y, r.z)
            local obj = sq and L.objectOn(kind, sq)
            if obj then SL.markObject(obj, r) end
        end
    end
end

if not LiveWire.API.addChunkVisitor(RC.visit) then X.warn("chunk visitor not registered: Live Wire circuits are not loaded") end
Events.EveryTenMinutes.Add(RC.tick)
