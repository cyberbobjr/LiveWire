-- LiveWire Extended: connected areas and the coverage provider (D-32, D-33, D-34).
-- Global ModData "LiveWireExtended" (authority writes, clients receive a copy):
--   { inverters = { [inverterId] = { areas = { [areaKey] = area } } } }
--   area = { kind = "building" | "zone", label = { x, y }, positions = { { cx, cy, x, y, z } },
--            bounds = { x0, y0, x1, y1 }, ...kind fields }
-- No secret in it (positions of power only). Session indexes below are rebuilt from it.
require "LiveWireExtended/LWX_Core"
require "LiveWireExtended/LWX_Footprint"

local X = LiveWire.Extended
local F = X.Footprint
local D = {}
X.Data = D

local CHUNK = X.CHUNK

function D.table()
    local t = ModData.getOrCreate(X.DATA_KEY)
    t.inverters = t.inverters or {}
    return t
end

function D.entry(id)
    return D.table().inverters[tostring(id)]
end

-- Areas of inverter `id` as a key-sorted array (stable order for scans and lists).
function D.areaList(id)
    local e = D.entry(id)
    local out = {}
    if not e or not e.areas then return out end
    local keys = {}
    for k in pairs(e.areas) do keys[#keys + 1] = k end
    table.sort(keys)
    for i = 1, #keys do out[i] = { key = keys[i], area = e.areas[keys[i]] } end
    return out
end

-- Which inverter holds area `key` (a building is connected to one inverter at most).
function D.ownerOf(key)
    for id, e in pairs(D.table().inverters) do
        if e.areas and e.areas[key] then return id end
    end
    return nil
end

-- ---------------------------------------------------------------- session caches
local cache = {}     -- id -> { idx, positions, bounds, chunks }
local chunkIds = nil -- "cx,cy" -> { [id] = true }

function D.invalidate(id)
    if id then cache[tostring(id)] = nil else cache = {} end
    chunkIds = nil
end

local function build(id)
    local list = D.areaList(id)
    local c = { positions = {}, chunks = {} }
    local seen = {}
    for i = 1, #list do
        local a = list[i].area
        for _, p in ipairs(a.positions or {}) do
            c.positions[#c.positions + 1] = p
            local key = p.cx .. "," .. p.cy
            local ch = seen[key]
            if not ch then
                ch = { cx = p.cx, cy = p.cy, zmin = p.z, zmax = p.z }
                seen[key] = ch
                c.chunks[#c.chunks + 1] = ch
            end
            ch.zmin, ch.zmax = math.min(ch.zmin, p.z), math.max(ch.zmax, p.z)
        end
        local b = a.bounds
        if b then
            if c.bounds then
                c.bounds.x0, c.bounds.y0 = math.min(c.bounds.x0, b.x0), math.min(c.bounds.y0, b.y0)
                c.bounds.x1, c.bounds.y1 = math.max(c.bounds.x1, b.x1), math.max(c.bounds.y1, b.y1)
            else
                c.bounds = { x0 = b.x0, y0 = b.y0, x1 = b.x1, y1 = b.y1 }
            end
        end
    end
    c.idx = F.index({ positions = c.positions })
    return c
end

local function get(id)
    if id == nil then return nil end
    local key = tostring(id)
    local c = cache[key]
    if not c then
        if not D.entry(key) then return nil end
        c = build(key)
        cache[key] = c
    end
    return c
end

local function ranges()
    return LiveWire.Config.tileRange(), LiveWire.Config.verticalRange()
end

-- ---------------------------------------------------------------- provider (LW_Coverage)
local P = {}
function P.covers(id, a, x, y, z)
    local c = get(id)
    if not c then return false end
    local R, V = ranges()
    return F.coversIndexed(c.idx, x, y, z, R, V)
end
function P.bounds(id, a)
    local c = get(id)
    local b = c and c.bounds
    if not b then return nil end
    return b.x0, b.y0, b.x1, b.y1
end
function P.positions(id, a)
    local c = get(id)
    return c and c.positions or nil
end
-- Resumable walk over the chunks of the areas; visits covered squares only.
function P.scan(id, a)
    local c = get(id)
    if not c or #c.chunks == 0 then return nil end
    local R, V = ranges()
    local first = c.chunks[1]
    return { chunks = c.chunks, idx = c.idx, R = R, V = V, ci = 1, i = 0,
        z = math.max(-32, first.zmin - V) }
end
function P.step(job, budget, visit)
    local n = 0
    while n < budget and job.ci <= #job.chunks do
        local ch = job.chunks[job.ci]
        local x, y = ch.cx * CHUNK + job.i % CHUNK, ch.cy * CHUNK + math.floor(job.i / CHUNK)
        if F.coversIndexed(job.idx, x, y, job.z, job.R, job.V) then visit(x, y, job.z) end
        n = n + 1
        job.i = job.i + 1
        if job.i >= CHUNK * CHUNK then
            job.i = 0
            job.z = job.z + 1
            if job.z > math.min(31, ch.zmax + job.V) then
                job.ci = job.ci + 1
                local nxt = job.chunks[job.ci]
                if nxt then job.z = math.max(-32, nxt.zmin - job.V) end
            end
        end
    end
    return job.ci > #job.chunks, n
end
function P.idsAt(x, y, z)
    if not chunkIds then
        chunkIds = {}
        for id in pairs(D.table().inverters) do
            local c = get(id)
            for _, ch in ipairs(c and c.chunks or {}) do
                local key = ch.cx .. "," .. ch.cy
                chunkIds[key] = chunkIds[key] or {}
                chunkIds[key][id] = true
            end
        end
    end
    local ids = chunkIds[math.floor(x / CHUNK) .. "," .. math.floor(y / CHUNK)]
    local out = {}
    if not ids then return out end
    for id in pairs(ids) do
        if P.covers(id, nil, x, y, z) then out[#out + 1] = id end
    end
    table.sort(out)
    return out
end
D.provider = P

local ok, why = LiveWire.Coverage.register(P)
if not ok then X.warn("coverage provider not registered: " .. tostring(why)) end
D.registered = ok == true
