-- Live Wire: private, time-bounded power history for authoritative food catch-up.
-- No network traffic: the public anchor log remains a separate 16-entry table.
if isClient() then return end

LiveWire = LiveWire or {}
local History = {}
LiveWire.PowerHistory = History
History.HOURS = 60 * 24

local function copyLog(log)
    local out = {}
    for i = 1, #(log or {}) do out[i] = { t = log[i].t, on = log[i].on == true } end
    return out
end

function History.prune(data, now)
    local cutoff, expired = now - History.HOURS, {}
    for id, h in pairs(data.powerHistory or {}) do
        local kept = {}
        for i = 1, #h.log do
            local e = h.log[i]
            if e.t <= cutoff then h.log0 = e.on else kept[#kept + 1] = e end
        end
        h.log = kept
        local panel = {}
        for _, e in ipairs(h.panelLog or {}) do
            if e.t <= cutoff then h.panel0 = e.off else panel[#panel + 1] = e end
        end
        h.panelLog = panel
        h.since = math.max(h.since, cutoff)
        if h.retired and h.retired <= cutoff then expired[#expired + 1] = id end
    end
    for i = 1, #expired do data.powerHistory[expired[i]] = nil end
end

-- Additive save upgrade: seed only the history that the old public log contains.
-- Never pretend to recover the events already discarded by earlier versions.
function History.init(data, anchors, now)
    data.powerHistory = data.powerHistory or {}
    for id, a in pairs(anchors) do
        if not data.powerHistory[id] then
            local log = copyLog(a.log)
            data.powerHistory[id] = { x = a.x, y = a.y, z = a.z, log = log,
                log0 = a.log0 == true, on = a.on == true,
                since = log[1] and log[1].t or now }
        end
    end
    History.prune(data, now)
    for id, h in pairs(data.powerHistory) do h.id = id end
end

function History.record(data, inverter, on, t)
    data.powerHistory = data.powerHistory or {}
    local all, id = data.powerHistory, inverter.id
    local h = all[id]
    if h and (h.x ~= inverter.x or h.y ~= inverter.y or h.z ~= inverter.z) then
        History.record(data, { id = id, x = h.x, y = h.y, z = h.z }, nil, t)
        all[id .. "@" .. tostring(t)] = h -- preserve the old location for its food
        h = nil
    end
    if not h then
        h = { id = id, x = inverter.x, y = inverter.y, z = inverter.z, log = {},
            log0 = false, on = false, since = t }
        all[id] = h
    end
    local last = h.log[#h.log]
    t = math.max(t, last and last.t or h.since) -- a UI refresh may overlap the last minute
    local state = on == true
    if h.on ~= state then
        if last and last.t == t then
            last.on = state
            local before = h.log0
            if #h.log > 1 then before = h.log[#h.log - 1].on end
            if before == state then table.remove(h.log, #h.log) end
        else
            h.log[#h.log + 1] = { t = t, on = state }
        end
        h.on = state
    end
    h.retired = on == nil and t or nil
end

-- Separate service timeline: an equipment cut must never switch the light anchor.
function History.equipment(data, inverter, off, t)
    local h = data.powerHistory and data.powerHistory[inverter.id]
    if not h then History.record(data, inverter, false, t); h = data.powerHistory[inverter.id] end
    h.panelLog = h.panelLog or {}
    local before = h.panel0 == true
    local last = h.panelLog[#h.panelLog]
    if last then before = last.off; t = math.max(t, last.t) end
    if before ~= off then
        if last and last.t == t then
            last.off = off
            local prior = h.panel0 == true
            if #h.panelLog > 1 then prior = h.panelLog[#h.panelLog - 1].off end
            if prior == off then table.remove(h.panelLog) end
        else h.panelLog[#h.panelLog + 1] = { t = t, off = off } end
    end
end

Events.EveryHours.Add(function()
    local r = LiveWire.Registry
    if r and r.ready and not r.readOnly then
        History.prune(r.data, getGameTime():getWorldAgeHours())
    end
end)

return History
