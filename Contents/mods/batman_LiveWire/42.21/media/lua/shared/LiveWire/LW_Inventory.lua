-- Live Wire: what a character carries and holds. Counting and moving items (with the
-- network echo to the owning client), and the screwdriver used by the timed actions.
-- LiveWire.Install keeps every name below for its callers.

LiveWire = LiveWire or {}

local Inventory = {}
LiveWire.Inventory = Inventory

local function notBroken(item)
    return not item:isBroken()
end

function Inventory.screwdriver(character)
    return character:getInventory():getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, notBroken)
end

-- Primary is the working/right hand in the native rig (Prop1), secondary the
-- left (Prop2). If the tool is in a bag, timed actions show it in primary.
function Inventory.screwdriverHand(character)
    local primary = character:getPrimaryHandItem()
    if primary and primary:hasTag(ItemTag.SCREWDRIVER) and not primary:isBroken() then
        return BodyPartType.Hand_R
    end
    local secondary = character:getSecondaryHandItem()
    if secondary and secondary:hasTag(ItemTag.SCREWDRIVER) and not secondary:isBroken() then
        return BodyPartType.Hand_L
    end
    return BodyPartType.Hand_R
end

function Inventory.showScrewdriver(action)
    local character = action.character
    local hand = Inventory.screwdriverHand(character)
    local held = hand == BodyPartType.Hand_L and character:getSecondaryHandItem()
        or character:getPrimaryHandItem()
    local tool = held and held:hasTag(ItemTag.SCREWDRIVER) and not held:isBroken() and held
        or Inventory.screwdriver(character)
    -- Use the actual item so modded screwdrivers keep their own model.
    if hand == BodyPartType.Hand_L then action:setOverrideHandModels(nil, tool)
    else action:setOverrideHandModels(tool, nil) end
end

function Inventory.countType(character, fullType)
    return character:getInventory():getCountTypeRecurse(fullType)
end

-- Remove `n` items of a type from the character's inventory (bags included).
function Inventory.consume(character, fullType, n)
    if n <= 0 then return true end
    local list = character:getInventory():getSomeTypeRecurse(fullType, n)
    if list:size() < n then return false end
    for i = 0, list:size() - 1 do
        local item = list:get(i)
        local container = item:getContainer()
        if container then
            character:removeFromHands(item)
            container:DoRemoveItem(item)
            sendRemoveItemFromContainer(container, item)
        end
    end
    return true
end

function Inventory.giveItem(character, fullType)
    local item = character:getInventory():AddItem(fullType)
    if item then sendAddItemToContainer(character:getInventory(), item) end
    return item
end

-- Give `n` items of a type; returns the number given. `give` is the function that
-- gives one item (default Inventory.giveItem; LiveWire.Install passes its own name so a
-- replaced Install.giveItem is honoured).
function Inventory.giveItems(character, fullType, n, give)
    give = give or Inventory.giveItem
    local given = 0
    for _ = 1, n or 0 do
        if give(character, fullType) then given = given + 1 end
    end
    return given
end
