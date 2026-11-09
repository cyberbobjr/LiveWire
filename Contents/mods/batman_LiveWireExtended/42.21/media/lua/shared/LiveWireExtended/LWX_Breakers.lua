-- LiveWire Extended: breakers of a breaker board (D-35), rules shared by client
-- tooltips and the authority. A breaker is an inventory item installed in a linked
-- board with a screwdriver; it takes one module (15, 20, 30 A at 120 V) or two (double
-- 30 A at 240 V, oven and dryer). Its first module is its identity on the board.
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
    ["Base.LWXBreaker2P30"] = { amps = 30, volts = 240, poles = 2 },
}
B.ORDER = { "Base.LWXBreaker15", "Base.LWXBreaker20", "Base.LWXBreaker30", "Base.LWXBreaker2P30" }

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

-- Can `character` install a breaker of `fullType` in the board `obj`? true, pos; or
-- false, key, arg.
function B.checkInstall(character, obj, fullType)
    local t = B.TYPES[fullType]
    if not t then return false, "Tooltip_LWX_NoBreakerItem" end
    local record = X.Panel.isPanel(obj) and X.Panel.recordAt(obj:getSquare())
    if not record then return false, "Tooltip_LWX_PanelNotLinked" end
    local I = LiveWire.Install
    if not I.screwdriver(character) then return false, "Tooltip_LW_NeedScrewdriver" end
    if not I.hasLevel(character, X.Panel.LEVEL) then
        return false, "Tooltip_LWX_NeedLevel", tostring(LiveWire.Config.requiredLevel(X.Panel.LEVEL))
    end
    if I.countType(character, fullType) < 1 then return false, "Tooltip_LWX_NoBreakerItem" end
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
        if LiveWire.Install.countType(character, t) > 0 then return true end
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
