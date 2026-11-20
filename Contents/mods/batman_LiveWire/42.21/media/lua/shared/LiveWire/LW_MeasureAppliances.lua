-- Live Wire: the electric appliances of a square read by the voltage tester, with their draw.
-- An appliance is what the engine can power (couldBePoweredByGenerator) or a consumer another mod
-- registered (LiveWire.Consumers, ADR-002). A piece of a multi-tile furniture stands for the whole
-- furniture: the piece that is billed (the registered consumer, else the piece the engine counts,
-- Consumption.countedPiece), so any square of the furniture can be measured.
--   list(sq) -> array of { name = arg, w = watts (integer, 0 when off) }, at most MAX rows
-- `name` is an argument for LiveWire.notify, translated by the client: the mod's own name of a
-- consumer (a translation key), else "Moveable:<group and custom name>" (vanilla moveable name),
-- else the appliance family key IGUI_LW_Appliance_<category>.
-- Authority side (the measure's complete()), also correct in single player.
LiveWire = LiveWire or {}
local M = {}
LiveWire.MeasureAppliances = M

M.MAX = 8
M.MOVEABLE_PREFIX = "Moveable:"

local pieces -- reused ArrayList

local function isAppliance(o)
    return o:couldBePoweredByGenerator() or LiveWire.Consumers.of(o) ~= nil
end

-- The objects of the square and, for multi-tile furniture, every piece of it.
local function candidates(sq)
    local out = {}
    local objects = sq:getObjects()
    for i = 0, objects:size() - 1 do
        local o = objects:get(i)
        if o:getSpriteGrid() then
            pieces = pieces or ArrayList.new()
            o:getSpriteGridObjectsIncludingSelf(pieces)
            for j = 0, pieces:size() - 1 do out[#out + 1] = pieces:get(j) end
            pieces:clear()
        else
            out[#out + 1] = o
        end
    end
    return out
end

-- Better piece to stand for a furniture: a registered consumer, then the piece the engine counts.
local function rank(o)
    if LiveWire.Consumers.of(o) then return 2 end
    if LiveWire.Consumption.countedPiece(o) then return 1 end
    return 0
end

local function category(o)
    if LiveWire.Demand and LiveWire.Demand.category then return LiveWire.Demand.category(o) end
    local consumer = LiveWire.Consumers.of(o)
    if consumer then return consumer.category end
    local Fam = LiveWire.ApplianceFamilies
    return Fam.value(Fam.of(o, "category"), "category", o) or "other"
end

function M.name(o)
    local consumer = LiveWire.Consumers.of(o)
    local info = consumer and LiveWire.Consumers.info(consumer, o)
    if info and info.name then return info.name end
    local props = o:getProperties()
    local custom = props and props:get("CustomName")
    if custom and custom ~= "" then
        local group = props:get("GroupName")
        if group and group ~= "" then return M.MOVEABLE_PREFIX .. group .. " " .. custom end
        return M.MOVEABLE_PREFIX .. custom
    end
    return "IGUI_LW_Appliance_" .. category(o)
end

function M.list(sq)
    local chosen, order = {}, {}
    for _, o in ipairs(candidates(sq)) do
        if isAppliance(o) then
            local key = o:getSpriteGrid() or o
            local best = chosen[key]
            if not best then
                order[#order + 1] = key
                chosen[key] = o
            elseif rank(o) > rank(best) then
                chosen[key] = o
            end
        end
    end
    local rows = {}
    for i = 1, math.min(#order, M.MAX) do
        local o = chosen[order[i]]
        rows[#rows + 1] = { name = M.name(o), w = math.floor(LiveWire.Consumption.watts(o) + 0.5) }
    end
    return rows
end

return M
