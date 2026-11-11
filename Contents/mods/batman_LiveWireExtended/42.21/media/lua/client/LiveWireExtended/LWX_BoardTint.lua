-- LiveWire Extended: tint of the appliances of a board's region while its window is open.
--   red   : wired to no board (no current where a board serves, D-37)
--   green : wired to this board, breaker closed
--   blue  : wired to this board, breaker open or tripped
--   grey  : wired to another board (a building may have several boards)
-- One scan of the region's loaded squares when the window opens, then again only when the
-- public table changes (X.Data.rev): no per-frame scan, no OnTick. The tint is a native
-- highlight drawn by the engine; objects highlighted by someone else are left alone, and
-- only objects still carrying our colour are released.
if isServer() then return end
require "LiveWireExtended/LWX_Points"
require "LiveWireExtended/LWX_Link"

local X = LiveWire.Extended
local Tint = {}
X.BoardTint = Tint

Tint.COLORS = {
    unwired = { 1, 0.2, 0.2 },
    on = { 0.2, 1, 0.2 },
    off = { 0.3, 0.6, 1 },
    other = { 0.6, 0.6, 0.6 },
}
local ALPHA = 0.85

-- Tint kind of point `key` seen from board `boardKey`.
function Tint.kindOf(key, boardKey)
    local p = X.Points.point(key)
    if not p then return "unwired" end
    if p.board ~= boardKey then return "other" end
    local slot = X.Points.slotOf(p)
    return (slot and not X.Breakers.isOpen(slot)) and "on" or "off"
end

-- { [object] = colour } for board `record`, and whether the board serves a region.
-- The region's loaded squares, plus this board's points standing outside it.
function Tint.compute(record)
    local Ad, PT = X.Adapters, X.Points
    local boardKey = X.Link.key(record.x, record.y, record.z)
    local wanted, seen = {}, {}
    local function add(o, key)
        if seen[key] then return end
        seen[key] = true
        local c = Tint.COLORS[Tint.kindOf(key, boardKey)]
        for _, piece in ipairs(Ad.find(o).pieces(o)) do wanted[piece] = c end
    end
    local points = PT.regionPoints(record)
    for _, e in ipairs(points or {}) do add(e.o, e.key) end
    for _, slot in ipairs(record.slots or {}) do
        for key in pairs(slot.points or {}) do
            if not seen[key] then
                local found = PT.objectsOf(key, PT.point(key))[1]
                if found then add(found, key) end
            end
        end
    end
    return wanted, points ~= nil
end

local function ours(o, idx, c)
    local v = o:getHighlightColor(idx)
    return v ~= nil and math.abs(v:getR() - c[1]) < 0.001 and math.abs(v:getG() - c[2]) < 0.001
        and math.abs(v:getB() - c[3]) < 0.001
end

-- Release every object still carrying the colour we gave it. `state` = { idx, lit }.
function Tint.clear(state)
    for o, c in pairs(state.lit or {}) do
        if o:getObjectIndex() ~= -1 and o:isHighlighted(state.idx) and ours(o, state.idx, c) then
            o:setHighlighted(state.idx, false, false)
        end
    end
    state.lit = {}
end

-- Replace the tint of `state` with `wanted` (from Tint.compute).
function Tint.apply(state, wanted)
    Tint.clear(state)
    for o, c in pairs(wanted) do
        if o:getObjectIndex() ~= -1 and not o:isHighlighted(state.idx) then
            o:setHighlightColor(state.idx, c[1], c[2], c[3], ALPHA)
            o:setHighlighted(state.idx, true, false)
            state.lit[o] = c
        end
    end
end
