-- Live Wire: consumers of other mods (ADR-002). An appliance whose draw the engine does not
-- know (couldBePoweredByGenerator() false, getGeneratorPowerConsumption() 0) is declared
-- by its mod through LiveWire.API.registerConsumer, the Lua counterpart of those two
-- engine methods: `couldBePowered(o)` and `powerConsumption(o)`.
-- Lookup is by exact sprite name first, so the demand census never calls a function of
-- another mod on an object that is not one of its own. No event subscription here.
require "LiveWire/LW_Extension"
LiveWire = LiveWire or {}

local Consumers = {}
LiveWire.Consumers = Consumers

local byId, bySprite, order = {}, {}, {}
local count = 0 -- registrations: nothing to look up while it is 0

-- Categories of the inverter interface a consumer may use (see LW_ApplianceFamilies).
Consumers.CATEGORIES = { light = true, tv = true, radio = true, stove = true, laundry = true,
    charger = true, fridge = true, other = true }
Consumers.CIRCUITS = { light = true, equipment = true }

local function validId(v)
    return type(v) == "string" and #v <= 64 and string.match(v, "^[%a][%w_]*$") ~= nil
end
local function validSprites(list)
    if type(list) ~= "table" or #list == 0 or #list > 256 then return false end
    local seen = {}
    for i = 1, #list do
        local s = list[i]
        if type(s) ~= "string" or #s == 0 or #s > 128 or seen[s] then return false end
        seen[s] = true
    end
    return true
end

-- true, or false and "registration_closed", "invalid_definition", "duplicate_consumer",
-- "duplicate_sprite". The definition is copied field by field: later changes by the caller
-- have no effect.
function Consumers.register(id, d)
    if LiveWire.Extension.isSealed() then return false, "registration_closed" end
    if not validId(id) or type(d) ~= "table" or not validSprites(d.sprites)
        or type(d.powerConsumption) ~= "function"
        or (d.couldBePowered ~= nil and type(d.couldBePowered) ~= "function")
        or (d.display ~= nil and type(d.display) ~= "function")
        or (d.summary ~= nil and type(d.summary) ~= "function")
        or (d.category ~= nil and not Consumers.CATEGORIES[d.category])
        or (d.circuit ~= nil and not Consumers.CIRCUITS[d.circuit]) then
        return false, "invalid_definition"
    end
    if byId[id] then return false, "duplicate_consumer" end
    for i = 1, #d.sprites do
        if bySprite[d.sprites[i]] then return false, "duplicate_sprite" end
    end
    local entry = { id = id, powerConsumption = d.powerConsumption, couldBePowered = d.couldBePowered,
        category = d.category or "other", circuit = d.circuit or "equipment", display = d.display,
        summary = d.summary }
    byId[id] = entry
    order[#order + 1] = entry
    count = count + 1
    for i = 1, #d.sprites do bySprite[d.sprites[i]] = entry end
    return true
end

-- Registration entry of world object `o`, or nil.
function Consumers.of(o)
    if count == 0 or not o or not o.getSprite then return nil end
    local sprite = o:getSprite()
    local name = sprite and sprite:getName()
    local entry = name and bySprite[name]
    if not entry then return nil end
    if entry.couldBePowered and entry.couldBePowered(o) ~= true then return nil end
    return entry
end

-- Draw in W of a registered consumer while not cut, before the sandbox settings (0 when off).
function Consumers.rawWatts(entry, o)
    local w = tonumber(entry.powerConsumption(o)) or 0
    if w ~= w or w <= 0 then return 0 end
    return w
end

-- ---------------------------------------------------------------- data shown by the management software (D07)
-- `display(o)` of the mod, called on the authority while a snapshot is built, answers
-- { name = key, lines = { { key, arg1, ... }, ... } }. Only a bounded copy of primitives travels:
-- translation keys (the client translates: a dedicated server may not load the mod's texts).
Consumers.MAX_LINES, Consumers.MAX_ARGS, Consumers.MAX_KEY, Consumers.MAX_ARG = 4, 4, 64, 32
Consumers.MAX_SUMMARY_LINES = 2

local function validKey(v)
    return type(v) == "string" and #v > 0 and #v <= Consumers.MAX_KEY and string.match(v, "^[%w_]+$") ~= nil
end
local function copyLine(line)
    if type(line) ~= "table" or not validKey(line[1]) or #line > Consumers.MAX_ARGS + 1 then return nil end
    local out = { line[1] }
    for i = 2, #line do
        local a = line[i]
        if type(a) == "number" then
            if a ~= a then return nil end
        elseif type(a) ~= "string" or #a > Consumers.MAX_ARG then
            return nil
        end
        out[i] = a
    end
    return out
end

-- Bounded copy { name, lines } of an answer of `display` or `summary`, or nil when it breaks a rule.
local function copyAnswer(d, maxLines)
    if type(d) ~= "table" then return nil end
    if d.name ~= nil and not validKey(d.name) then return nil end
    if d.lines ~= nil and (type(d.lines) ~= "table" or #d.lines > maxLines) then return nil end
    local lines = {}
    for i = 1, d.lines and #d.lines or 0 do
        lines[i] = copyLine(d.lines[i])
        if not lines[i] then return nil end
    end
    if d.name == nil and #lines == 0 then return nil end
    return { name = d.name, lines = lines }
end

-- Bounded copy of what `entry.display` answers for `o`, or nil (no display, or an answer
-- outside the rules: the usual row is shown).
function Consumers.info(entry, o)
    if not entry or not entry.display then return nil end
    return copyAnswer(entry.display(o), Consumers.MAX_LINES)
end

-- Network totals (D08). `each(fn)` calls fn(o) for every object the network serves. Returns a
-- new array of { id, name, lines }, in registration order, one per consumer that has a
-- `summary` and at least one served object; an answer outside the rules is left out.
function Consumers.summaries(each)
    local out, wanted = {}, false
    for i = 1, #order do
        if order[i].summary then wanted = true; break end
    end
    if not wanted then return out end
    local groups = {}
    each(function(o)
        local entry = Consumers.of(o)
        if entry and entry.summary then
            local g = groups[entry.id] or {}
            groups[entry.id] = g
            g[#g + 1] = o
        end
    end)
    for i = 1, #order do
        local entry = order[i]
        local objects = groups[entry.id]
        local copy = objects and copyAnswer(entry.summary(objects), Consumers.MAX_SUMMARY_LINES)
        if copy then out[#out + 1] = { id = entry.id, name = copy.name, lines = copy.lines } end
    end
    return out
end
