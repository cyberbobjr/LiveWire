-- Live Wire: batteries stored in power banks (authority only).
-- A power bank is a placed object with a container that players open like a crate.
-- Batteries are moved with the vanilla inventory (server-side transactions).
-- Charge lives in the item uses (0..1 of the effective capacity), wear in its
-- condition; both reach clients with sendItemStats() for an item in a furniture
-- container (knowledge/multiplayer.md:319-322; ModData is not sent, it is server-only).
-- While the power bank is not loaded, a per-slot snapshot in the registry carries
-- the state; it is written back onto the items when the chunk loads.
if isClient() then return end

LiveWire = LiveWire or {}

local Batteries = {}
LiveWire.Batteries = Batteries

Batteries.CYCLES_KEY = "LiveWireCycles"

function Batteries.def(fullType)
    return LiveWire.Defs.batteries[fullType]
end

function Batteries.capacity(model, cond)
    local def = Batteries.def(model)
    if not def then return 0 end
    return LiveWire.Physics.batteryCapacity(def.capacityKWh, cond,
        LiveWire.Config.get("BatteryCapacityMultiplier"))
end

-- Container of a loaded power bank, or nil when its square is not loaded.
-- Second result is true when the square is loaded but the object is gone.
function Batteries.container(bank)
    local sq = getCell():getGridSquare(bank.x, bank.y, bank.z)
    if not sq then return nil, false end
    local obj = LiveWire.Marks.findOnSquare(sq, bank.id)
    if not obj then return nil, true end
    return obj:getContainer(), false
end

-- Batteries counted by a bank: the first `slots` battery items of its container.
local function batteryItems(container, slots)
    local list, extra = {}, 0
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and Batteries.def(it:getFullType()) then
            if #list < slots then list[#list + 1] = it else extra = extra + 1 end
        end
    end
    return list, extra
end

-- Physics entries for one power bank: { dev, model, item?, cond, capacity, charge }.
function Batteries.read(bank)
    local def = LiveWire.Defs.devices[bank.model] or {}
    local slots = def.slots or 4
    local container, gone = Batteries.container(bank)
    local entries = {}
    bank.extra = 0
    if container then
        local items, extra = batteryItems(container, slots)
        bank.extra = extra
        for i = 1, #items do
            local it = items[i]
            local cond = it:getCondition()
            local cap = Batteries.capacity(it:getFullType(), cond)
            entries[#entries + 1] = {
                bank = bank, model = it:getFullType(), item = it, id = it:getID(),
                cond = cond, capacity = cap, charge = it:getCurrentUsesFloat() * cap,
                cycles = it:getModData()[Batteries.CYCLES_KEY] or 0,
                wearFactor = bank.wearFactor or 1,
            }
        end
    elseif not gone then
        for i, s in ipairs(bank.slots or {}) do
            local cap = Batteries.capacity(s.model, s.cond)
            entries[#entries + 1] = {
                bank = bank, model = s.model, id = s.id, cond = s.cond,
                capacity = cap, charge = (s.charge or 0) * cap, cycles = s.cycles or 0,
                wearFactor = bank.wearFactor or 1,
            }
        end
    end
    return entries
end

-- Write entries back: snapshot in the registry, and the items when loaded.
function Batteries.write(bank, entries)
    local slots = {}
    for i = 1, #entries do
        local e = entries[i]
        local frac = 0
        if e.capacity > 0 then frac = LiveWire.clamp(e.charge / e.capacity, 0, 1) end
        local cond = math.max(0, e.cond)
        slots[#slots + 1] = { id = e.id, model = e.model, charge = frac, cond = cond, cycles = e.cycles }
        local it = e.item
        if it then
            local oldFrac = it:getCurrentUsesFloat()
            local newCond = math.floor(cond + 0.5)
            local changed = math.abs(oldFrac - frac) >= 0.005 or it:getCondition() ~= newCond
            it:setCurrentUsesFloat(frac)
            if it:getCondition() ~= newCond then it:setConditionNoSound(newCond) end
            it:getModData()[Batteries.CYCLES_KEY] = e.cycles
            if changed then sendItemStats(it) end
        end
    end
    bank.slots = slots
end

-- Chunk just loaded: nobody could touch the bank while it was unloaded, so the
-- snapshot is written onto the items with the same id.
function Batteries.restore(bank)
    local container = Batteries.container(bank)
    if not container or not bank.slots then return end
    local byId = {}
    for _, s in ipairs(bank.slots) do byId[s.id] = s end
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        local s = it and byId[it:getID()]
        if s then
            it:setCurrentUsesFloat(LiveWire.clamp(s.charge or 0, 0, 1))
            it:setConditionNoSound(math.floor((s.cond or it:getCondition()) + 0.5))
            it:getModData()[Batteries.CYCLES_KEY] = s.cycles or 0
            sendItemStats(it)
        end
    end
end

-- A power bank cannot be dismantled while it holds items.
function Batteries.isEmpty(obj)
    local c = obj and obj:getContainer()
    return c == nil or c:getItems():size() == 0
end
