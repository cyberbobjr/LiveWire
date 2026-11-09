-- LiveWire Extended: outdoor zone of a power terminal (pure, no world access), D-34.
-- The engine powers by 8 x 8 chunk (IsoChunk.java:4773-4783): a zone is a rectangle
-- of whole chunks, at most MAX_CHUNKS x MAX_CHUNKS, each within one chunk of the
-- terminal's chunk, on the terminal's floor +/- 1 (one generator position per chunk
-- covers +/- GeneratorVerticalPowerRange floors). A position stands on a square that
-- exists: the terminal's floor when `exists` says so, else the ground floor if it
-- still reaches the terminal's floor.
require "LiveWireExtended/LWX_Core"
LiveWire = LiveWire or {}
LiveWire.Extended = LiveWire.Extended or {}
local Z = {}
LiveWire.Extended.Zone = Z

local CHUNK = LiveWire.Extended.CHUNK
Z.MAX_CHUNKS = 2
local CENTRE = { { 3, 3 }, { 4, 3 }, { 3, 4 }, { 4, 4 } }

function Z.chunkOf(x, y) return math.floor(x / CHUNK), math.floor(y / CHUNK) end

-- Square rectangle (any corners, in squares) -> chunk rectangle covering it.
function Z.round(x0, y0, x1, y1)
    local ax, bx = math.min(x0, x1), math.max(x0, x1)
    local ay, by = math.min(y0, y1), math.max(y0, y1)
    return { cx0 = math.floor(ax / CHUNK), cy0 = math.floor(ay / CHUNK),
             cx1 = math.floor(bx / CHUNK), cy1 = math.floor(by / CHUNK) }
end

-- Default zone: the terminal's own chunk.
function Z.default(tx, ty)
    local cx, cy = Z.chunkOf(tx, ty)
    return { cx0 = cx, cy0 = cy, cx1 = cx, cy1 = cy }
end

-- Is chunk rectangle `c` allowed for a terminal at (tx, ty)? Returns ok, reason key.
function Z.allowed(c, tx, ty)
    local tcx, tcy = Z.chunkOf(tx, ty)
    if c.cx1 - c.cx0 + 1 > Z.MAX_CHUNKS or c.cy1 - c.cy0 + 1 > Z.MAX_CHUNKS then
        return false, "IGUI_LWX_ZoneTooBig"
    end
    if c.cx0 < tcx - 1 or c.cx1 > tcx + 1 or c.cy0 < tcy - 1 or c.cy1 > tcy + 1 then
        return false, "IGUI_LWX_ZoneTooFar"
    end
    return true
end

-- Area of a zone: { kind = "zone", positions, bounds, rect }, or nil when no chunk can
-- carry a position. exists(x, y, z) tells whether a square exists (authority world check).
function Z.compute(c, tx, ty, tz, opts)
    local V, salt, exists = opts.V, opts.salt or 0, opts.exists
    local out = { kind = "zone", positions = {}, label = { x = tx, y = ty },
        rect = { cx0 = c.cx0, cy0 = c.cy0, cx1 = c.cx1, cy1 = c.cy1 },
        bounds = { x0 = c.cx0 * CHUNK, y0 = c.cy0 * CHUNK, x1 = c.cx1 * CHUNK + CHUNK - 1, y1 = c.cy1 * CHUNK + CHUNK - 1 } }
    for cy = c.cy0, c.cy1 do
        for cx = c.cx0, c.cx1 do
            local d = CENTRE[(salt % #CENTRE) + 1]
            local x, y = cx * CHUNK + d[1], cy * CHUNK + d[2]
            local tcx, tcy = Z.chunkOf(tx, ty)
            if cx == tcx and cy == tcy and not (exists and exists(x, y, tz)) then
                x, y = tx, ty -- the terminal's own square always exists
            end
            local z
            if exists and exists(x, y, tz) or (x == tx and y == ty) then
                z = tz
            elseif math.abs(tz) <= V then
                z = 0
            end
            if z then out.positions[#out.positions + 1] = { cx = cx, cy = cy, x = x, y = y, z = z } end
        end
    end
    if #out.positions == 0 then return nil end
    return out
end
