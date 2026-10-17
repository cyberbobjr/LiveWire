-- Live Wire: recipe callbacks. OnCreate runs in single player or on the server,
-- never on an MP client (ISHandcraftAction.lua:191-234). Signature:
-- (craftRecipeData, character) (CraftRecipeData.java:424-434).

LiveWire = LiveWire or {}
LiveWire.Recipes = LiveWire.Recipes or {}

local function addConditions(list, acc)
    if not list then return end
    for i = 0, list:size() - 1 do
        local it = list:get(i)
        if it and LiveWire.Defs.isBattery(it:getFullType()) then
            acc.sum = acc.sum + it:getCondition()
            acc.n = acc.n + 1
        end
    end
end

-- New deep-cycle battery: empty, condition = mean of the two car batteries used.
function LiveWire.Recipes.onDeepCycleBattery(craftRecipeData, character)
    local acc = { sum = 0, n = 0 }
    addConditions(craftRecipeData:getAllConsumedItems(), acc)
    if acc.n == 0 then addConditions(craftRecipeData:getAllDestroyInputItems(), acc) end
    local cond = 100
    if acc.n > 0 then cond = math.floor(acc.sum / acc.n + 0.5) end
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local it = created:get(i)
        if it and it:getFullType() == "LiveWire.DeepCycleBattery" then
            it:setCurrentUsesFloat(0)
            it:setConditionNoSound(math.max(1, cond))
            if isServer() and character then syncItemFields(character, it) end
        end
    end
end
