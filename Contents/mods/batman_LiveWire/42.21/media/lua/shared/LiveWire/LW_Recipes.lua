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

-- Dismantling Live Wire equipment (LWDismantle* recipes). The script outputs are the
-- parts that always survive (metal, screws, sub-assemblies); the electronic parts
-- below come on top, in proportion to the condition carried by the picked-up item
-- (its mark, LW_Marks.lua; the deep-cycle battery has no mark and uses its own condition;
-- an item without either is new: 100). Every total stays
-- below the matching crafting recipe, so a craft/dismantle cycle loses materials,
-- and a worn device gives fewer parts, so a dismantle/craft cycle is no cheaper than
-- an overhaul. A fitted soundproofing kit is given back (a coupling kit comes back
-- when the coupled inverter is picked up, LW_Devices.lua Devices.remove).
LiveWire.Recipes.DISMANTLE = {
    ["Base.Mov_LiveWire_SolarPanel"] = { { "LiveWire.SolarCell", 8 }, { "Base.ElectricWire", 1 } },
    ["Base.Mov_LiveWire_WindTurbine"] = { { "Base.Amplifier", 2 }, { "Base.ElectricWire", 2 },
                                          { "Base.ElectronicsScrap", 3 } },
    ["Base.Mov_LiveWire_WaterWheel"] = { { "Base.Amplifier", 2 }, { "Base.ElectricWire", 2 },
                                         { "Base.ElectronicsScrap", 3 } },
    ["Base.Mov_LiveWire_Inverter"] = { { "Base.Amplifier", 2 }, { "Base.ElectricWire", 2 },
                                       { "Base.ElectronicsScrap", 3 } },
    ["Base.Mov_LiveWire_InverterCabinet"] = { { "Base.Amplifier", 4 }, { "Base.ElectricWire", 5 },
                                              { "Base.ElectronicsScrap", 6 } },
    ["Base.Mov_LiveWire_PowerBank"] = { { "Base.ElectricWire", 2 }, { "Base.ElectronicsScrap", 1 } },
    ["Base.Mov_LiveWire_Breaker"] = { { "Base.ElectricWire", 1 }, { "Base.ElectronicsScrap", 1 } },
    ["Base.Mov_LiveWire_BatteryAlarm"] = { { "Base.Amplifier", 1 } },
    ["Base.Mov_LiveWire_WaterPump"] = { { "Base.ElectricWire", 1 }, { "Base.ElectronicsScrap", 2 } },
    ["LiveWire.DeepCycleBattery"] = { { "Base.ElectricWire", 2 } },
}

-- Number of bonus parts for a device at `cond` percent (rounded down).
function LiveWire.Recipes.salvaged(count, cond)
    cond = tonumber(cond) or 100
    if cond < 0 then cond = 0 elseif cond > 100 then cond = 100 end
    return math.floor(count * cond / 100)
end

local function dismantled(list)
    if not list then return nil end
    for i = 0, list:size() - 1 do
        local it = list:get(i)
        if it and LiveWire.Recipes.DISMANTLE[it:getFullType()] then return it end
    end
    return nil
end

-- The vanilla DismantleElectronics (recipes_electrical.txt) also takes calculators but only gives
-- electronics scrap. Its OnCreate, RecipeCodeOnCreate.dismantleFlashlight, is looked up by name in
-- the Lua environment at each craft (CraftRecipeData.initLuaFunctions, LuaManager.getFunctionObject):
-- wrapped here, it keeps its vanilla effect (a torch gives back its battery) and a dismantled
-- calculator gives a solar cell too. The recipe itself is not redefined: a second craftRecipe of the
-- same name adds its inputs to the vanilla one (CraftRecipe has no reset, BaseScriptObject.java:181).
LiveWire.Recipes.CALCULATOR = "Base.Calculator"
function LiveWire.Recipes.calculatorCells(craftRecipeData, character)
    if not character then return end
    local seen = {}
    for _, list in ipairs({ craftRecipeData:getAllConsumedItems(), craftRecipeData:getAllDestroyInputItems() }) do
        for i = 0, list and list:size() - 1 or -1 do
            local it = list:get(i)
            if it and not seen[it] and it:getFullType() == LiveWire.Recipes.CALCULATOR then
                seen[it] = true
                LiveWire.Install.giveItem(character, "LiveWire.SolarCell")
            end
        end
    end
end
if RecipeCodeOnCreate and RecipeCodeOnCreate.dismantleFlashlight and not LiveWire.Recipes.vanillaDismantleFlashlight then
    LiveWire.Recipes.vanillaDismantleFlashlight = RecipeCodeOnCreate.dismantleFlashlight
    RecipeCodeOnCreate.dismantleFlashlight = function(craftRecipeData, character)
        LiveWire.Recipes.vanillaDismantleFlashlight(craftRecipeData, character)
        LiveWire.Recipes.calculatorCells(craftRecipeData, character)
    end
end

-- Condition of the dismantled item: its mark when it has one (devices), else the item's own
-- condition for the deep-cycle battery (no mark). nil means new (salvaged treats it as 100).
local function conditionOf(item, m)
    if m.cond ~= nil then return m.cond end
    if item:getFullType() == "LiveWire.DeepCycleBattery" then return item:getCondition() end
    return nil
end

function LiveWire.Recipes.onDismantle(craftRecipeData, character)
    if not character then return end
    local item = dismantled(craftRecipeData:getAllDestroyInputItems())
        or dismantled(craftRecipeData:getAllConsumedItems())
    if not item then return end
    local m = LiveWire.Marks.raw(item) or {}
    local give = LiveWire.Install.giveItem
    local cond = conditionOf(item, m)
    for _, part in ipairs(LiveWire.Recipes.DISMANTLE[item:getFullType()]) do
        for _ = 1, LiveWire.Recipes.salvaged(part[2], cond) do give(character, part[1]) end
    end
    if m.muf == true then give(character, LiveWire.Defs.SOUNDPROOF_KIT) end
end
