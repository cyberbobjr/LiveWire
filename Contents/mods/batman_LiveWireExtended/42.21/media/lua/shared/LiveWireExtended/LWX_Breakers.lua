-- LiveWire Extended: breakers of a breaker board (D-35), rules shared by client
-- tooltips and the authority. A breaker is an inventory item installed in a linked
-- board with a screwdriver; it takes one module (15, 20 or 30 A at 120 V; no double breaker
-- since D-43). Its module is its identity on the board.
--   slot = { type, pos, poles, amps, volts, label = "", off = false, tripped = false,
--            points = {} }
require "LiveWireExtended/LWX_Panel"

local X = LiveWire.Extended
local B = {}
X.Breakers = B

B.TYPES = {
    ["Base.LWXBreaker15"] = { amps = 15, volts = 120, poles = 1 },
    ["Base.LWXBreaker20"] = { amps = 20, volts = 120, poles = 1 },
    ["Base.LWXBreaker30"] = { amps = 30, volts = 120, poles = 1 },
}
B.ORDER = { "Base.LWXBreaker15", "Base.LWXBreaker20", "Base.LWXBreaker30" }

-- Rated power of a breaker type or slot: W = A x V.
function B.capacityW(t) return t.amps * t.volts end

function B.usedModules(record)
    local n = 0
    for _, s in ipairs(record.slots or {}) do n = n + s.poles end
    return n
end

-- First module where `poles` adjacent modules are free, or nil.
function B.freePosition(record, poles)
    local used = {}
    for _, s in ipairs(record.slots or {}) do
        for m = s.pos, s.pos + s.poles - 1 do used[m] = true end
    end
    for m = 1, (record.size or 0) - poles + 1 do
        local free = true
        for k = m, m + poles - 1 do
            if used[k] then free = false; break end
        end
        if free then return m end
    end
    return nil
end

function B.slotAt(record, pos)
    for i, s in ipairs(record.slots or {}) do
        if s.pos == pos then return s, i end
    end
    return nil
end

-- Is module `pos` of the board free (and on the board)?
function B.moduleFree(record, pos)
    pos = tonumber(pos)
    if not pos or pos < 1 or pos > (record.size or 0) or pos ~= math.floor(pos) then return false end
    for _, s in ipairs(record.slots or {}) do
        if pos >= s.pos and pos < s.pos + s.poles then return false end
    end
    return true
end

-- Can `character` install a breaker of `fullType` in the board `obj` (module `at`, or
-- the first free one)? true, pos; or false, key, arg.
function B.checkInstall(character, obj, fullType, at)
    local t = B.TYPES[fullType]
    if not t then return false, "Tooltip_LWX_NoBreakerItem" end
    local record = X.Panel.isPanel(obj) and X.Panel.recordAt(obj:getSquare())
    if not record then return false, "Tooltip_LWX_PanelNotLinked" end
    local I = LiveWire.API
    if not I.screwdriver(character) then return false, "Tooltip_LW_NeedScrewdriver" end
    if not I.hasLevel(character, X.LEVEL) then
        return false, "Tooltip_LWX_NeedLevel", tostring(LiveWire.Config.requiredLevel(X.LEVEL))
    end
    if I.countType(character, fullType) < 1 then return false, "Tooltip_LWX_NoBreakerItem" end
    if at ~= nil then
        if not B.moduleFree(record, at) then return false, "Tooltip_LWX_ModuleTaken" end
        return true, tonumber(at)
    end
    local pos = B.freePosition(record, t.poles)
    if not pos then return false, "Tooltip_LWX_BoardFull" end
    return true, pos
end

-- ---------------------------------------------------------------- window (E19)
B.LABEL_MAX = 24  -- bytes
B.PENS = { "Base.Pen", "Base.Pencil", "Base.RedPen", "Base.BluePen" }

-- Label written by a player, cleaned: control characters become spaces, spaces are
-- collapsed and trimmed, at most LABEL_MAX bytes without cutting a UTF-8 character.
-- nil when `text` is not a string.
function B.cleanLabel(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("[%z\1-\31\127]", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    if #text <= B.LABEL_MAX then return text end
    local cut = B.LABEL_MAX
    -- Step back over continuation bytes (10xxxxxx) and the lead byte they belong to.
    while cut > 0 and text:byte(cut + 1) and text:byte(cut + 1) >= 128 and text:byte(cut + 1) < 192 do
        cut = cut - 1
    end
    return (text:sub(1, cut):gsub(" $", ""))
end

function B.hasPen(character)
    for _, t in ipairs(B.PENS) do
        if LiveWire.API.countType(character, t) > 0 then return true end
    end
    return false
end

-- Current of a circuit from its published load (W / V).
function B.amps(slot) return (slot.load or 0) / slot.volts end

-- Point keys of a slot, sorted.
function B.pointList(slot)
    local out = {}
    for key in pairs(slot.points or {}) do out[#out + 1] = key end
    table.sort(out)
    return out
end

-- ---------------------------------------------------------------- twilight (E21)
B.TWILIGHT_ITEM = "Base.LWXTwilightSwitch"

-- Between the season's dusk and dawn (decimal hours, as the solar panels use).
function B.isNight()
    local season = getClimateManager():getSeason()
    local hour = getGameTime():getTimeOfDay()
    return hour >= season:getDusk() or hour < season:getDawn()
end

-- Is the breaker's circuit open (switched off, tripped, or a twilight switch by day)?
function B.isOpen(slot)
    return slot.off == true or slot.tripped == true or (slot.twilight == true and not B.isNight())
end

-- ---------------------------------------------------------------- meter (E24)
B.METER_DAYS = 60   -- as Live Wire's power history

-- Add the energy of `loadW` since the last update to the breaker's meter; a new day
-- closes the previous one (the interval counts on the day it ends on, as a meter read
-- every ten minutes). slot.meter = { day, kwh, at, days = { { day, kwh } } }.
function B.meterAdd(slot, loadW, nowH)
    local day = math.floor(nowH / 24)
    local m = slot.meter
    if not m then
        slot.meter = { day = day, kwh = 0, at = nowH, days = {} }
        return
    end
    local dt = math.max(0, nowH - (m.at or nowH))
    m.kwh = m.kwh + loadW * dt / 1000
    m.at = nowH
    if day ~= m.day then
        m.days[#m.days + 1] = { day = m.day, kwh = m.kwh }
        while #m.days > B.METER_DAYS do table.remove(m.days, 1) end
        m.day, m.kwh = day, 0
    end
end

-- { today, yesterday, week } in kWh (week = today and the six previous days).
function B.meterSummary(slot)
    local m = slot.meter
    if not m then return { today = 0, yesterday = 0, week = 0 } end
    local out = { today = m.kwh, yesterday = 0, week = m.kwh }
    for _, d in ipairs(m.days) do
        if d.day == m.day - 1 then out.yesterday = d.kwh end
        if d.day >= m.day - 6 then out.week = out.week + d.kwh end
    end
    return out
end
