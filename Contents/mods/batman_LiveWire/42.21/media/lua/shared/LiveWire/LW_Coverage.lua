-- Live Wire: coverage of an inverter anchor (which squares it powers), D-32.
-- Default: the disc of D-12, GeneratorTileRange around the inverter square and
-- +/- GeneratorVerticalPowerRange floors (IsoGenerator.isPoweringSquare,
-- IsoGenerator.java:637-644). An optional sub-mod may register ONE provider that
-- ADDS squares to that disc (D-33: the extra coverage adds to the radius, it never
-- replaces it). Without a provider every function below is the disc, nothing more.
--
-- Provider contract (all functions receive the inverter id and its public anchor
-- { x, y, z, on }; none may keep a reference to the anchor table):
--   covers(id, a, x, y, z)   -> true when the square is in the EXTRA coverage
--   bounds(id, a)            -> minX, minY, maxX, maxY of the extra coverage, or nil
--   positions(id, a)         -> array of { cx, cy, x, y, z }: generator positions to
--                               declare on chunk (cx, cy), each on a real square
--   scan(id, a)              -> resumable job over the extra squares, or nil
--   step(job, budget, visit) -> done, used (like LiveWire.SquareScan.step)
--   idsAt(x, y, z)           -> array of inverter ids whose extra coverage holds the square
--   describe(id)             -> optional: lines for the inverter screen, { { key, args } }
-- Registration happens while Lua files load, before OnInitGlobalModData, like API v1.
require "LiveWire/LW_SquareScan"
LiveWire = LiveWire or {}

local Coverage = { version = 1 }
LiveWire.Coverage = Coverage

local CHUNK = 8 -- IsoChunkMap.CHUNK_SIZE_IN_SQUARES (IsoChunkMap.java:61)
local EMPTY = {}
local provider, sealed = nil, false

local function radius() return LiveWire.Config.tileRange() end
local function floors() return LiveWire.Config.verticalRange() end

-- ---------------------------------------------------------------- the disc (D-12)
function Coverage.inDisc(a, x, y, z, R, V)
    R, V = R or radius(), V or floors()
    local dx, dy = x - a.x, y - a.y
    return dx * dx + dy * dy <= R * R and math.abs(z - a.z) <= V
end

-- Does the disc of radius R around the anchor touch chunk (cx, cy)?
function Coverage.touchesDisc(cx, cy, a, R)
    local px, py = a.x + 0.5, a.y + 0.5
    local minX, minY = cx * CHUNK, cy * CHUNK
    local maxX, maxY = minX + CHUNK, minY + CHUNK
    local nx = math.max(minX, math.min(px, maxX))
    local ny = math.max(minY, math.min(py, maxY))
    local dx, dy = px - nx, py - ny
    return dx * dx + dy * dy <= R * R
end

-- ---------------------------------------------------------------- provider
local REQUIRED = { "covers", "bounds", "positions", "scan", "step", "idsAt" }
function Coverage.register(p)
    if sealed then return false, "registration_closed" end
    if provider then return false, "already_registered" end
    if type(p) ~= "table" then return false, "invalid_provider" end
    for i = 1, #REQUIRED do
        if type(p[REQUIRED[i]]) ~= "function" then return false, "invalid_provider" end
    end
    provider = p
    return true
end
function Coverage.active() return provider ~= nil end

-- ---------------------------------------------------------------- disc + extra
function Coverage.covers(id, a, x, y, z, R, V)
    if Coverage.inDisc(a, x, y, z, R, V) then return true end
    return provider ~= nil and provider.covers(id, a, x, y, z) == true
end

-- Square only in the provider's extra coverage (outside the disc).
function Coverage.coversExtra(id, a, x, y, z, R, V)
    return provider ~= nil and not Coverage.inDisc(a, x, y, z, R, V) and provider.covers(id, a, x, y, z) == true
end

function Coverage.extraBounds(id, a)
    if not provider then return nil end
    return provider.bounds(id, a)
end

-- Chunk rectangle holding the disc and the extra coverage.
function Coverage.chunkRange(id, a, R)
    R = R or radius()
    local x0, y0, x1, y1 = a.x - R, a.y - R, a.x + R, a.y + R
    local bx0, by0, bx1, by1 = Coverage.extraBounds(id, a)
    if bx0 then
        x0, y0 = math.min(x0, bx0), math.min(y0, by0)
        x1, y1 = math.max(x1, bx1), math.max(y1, by1)
    end
    return math.floor(x0 / CHUNK), math.floor(y0 / CHUNK), math.floor(x1 / CHUNK), math.floor(y1 / CHUNK)
end

-- Does the bounding rectangle of the extra coverage touch chunk (cx, cy)?
function Coverage.extraTouchesChunk(id, a, cx, cy)
    local bx0, by0, bx1, by1 = Coverage.extraBounds(id, a)
    if not bx0 then return false end
    return cx >= math.floor(bx0 / CHUNK) and cx <= math.floor(bx1 / CHUNK)
        and cy >= math.floor(by0 / CHUNK) and cy <= math.floor(by1 / CHUNK)
end

function Coverage.touchesChunk(id, a, cx, cy, R)
    return Coverage.touchesDisc(cx, cy, a, R or radius()) or Coverage.extraTouchesChunk(id, a, cx, cy)
end

function Coverage.extraPositions(id, a)
    if not provider then return EMPTY end
    return provider.positions(id, a) or EMPTY
end

function Coverage.extraIdsAt(x, y, z)
    if not provider then return EMPTY end
    return provider.idsAt(x, y, z) or EMPTY
end

-- Lines describing the extra coverage on the inverter screen (translation key and
-- arguments); empty without provider or when it describes nothing.
function Coverage.describe(id)
    if not provider or type(provider.describe) ~= "function" then return EMPTY end
    return provider.describe(id) or EMPTY
end

-- Resumable job over the extra squares only; nil without provider.
function Coverage.extraScan(id, a)
    if not provider then return nil end
    local job = provider.scan(id, a)
    if not job then return nil end
    return { inner = job, a = { x = a.x, y = a.y, z = a.z }, R = radius(), V = floors() }
end
-- Visits extra squares outside the disc (the disc has its own scans).
function Coverage.stepExtra(job, budget, visit)
    local a, R, V = job.a, job.R, job.V
    return provider.step(job.inner, budget, function(x, y, z)
        if not Coverage.inDisc(a, x, y, z, R, V) then visit(x, y, z) end
    end)
end

-- Whole coverage: the disc scan of LiveWire.SquareScan, then the extra squares.
function Coverage.scan(id, a, R, V)
    return { disc = LiveWire.SquareScan.new(a.x, a.y, a.z, R or radius(), V or floors()),
        extra = Coverage.extraScan(id, a) }
end
function Coverage.step(job, budget, visit)
    local used = 0
    if job.disc then
        local done, n = LiveWire.SquareScan.step(job.disc, budget, visit)
        used = n
        if not done then return false, used end
        job.disc = nil
    end
    if not job.extra or not provider then return true, used end
    if used >= budget then return false, used end
    local done, n = Coverage.stepExtra(job.extra, budget - used, visit)
    return done, used + n
end

Events.OnInitGlobalModData.Add(function() sealed = true end)
