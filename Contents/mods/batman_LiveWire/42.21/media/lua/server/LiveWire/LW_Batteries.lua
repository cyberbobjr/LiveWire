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
Batteries.CONDITION_KEY = "LiveWireCondition"
Batteries.ENERGY_KEY = "LiveWireEnergyRemainder"

-- Keep fractional wear across native integer condition writes. An external native
-- condition change wins when it no longer matches the last shown integer.
function Batteries.condition(item)
    local native = item:getCondition()
    local value = item:getModData()[Batteries.CONDITION_KEY]
    if native > 0 and type(value) == "number" and value == value and value >= 0 and value <= 100
        and math.floor(value + 0.5) == native then return value end
    return native
end

function Batteries.setCondition(item, value)
    local native = math.max(0, math.floor(value + 0.5))
    if native == 0 then value = 0 end
    item:setConditionNoSound(native)
    item:getModData()[Batteries.CONDITION_KEY] = value
    return value
end

function Batteries.def(fullType)
    return LiveWire.Defs.batteries[fullType]
end

function Batteries.capacity(model, cond)
    local def = Batteries.def(model)
    if not def then return 0 end
    return LiveWire.Physics.batteryCapacity(def.capacityKWh, cond,
        LiveWire.Config.get("BatteryCapacityMultiplier"))
end

-- Preserve the sub-use remainder on authority. Native charge changes invalidate
-- this small remainder, so vanilla charging/discharging remains the source of truth.
function Batteries.energy(item, capacity)
    local fraction = item:getCurrentUsesFloat()
    local energy = fraction * capacity
    local r = item:getModData()[Batteries.ENERGY_KEY]
    if type(r) == "table" and r.fraction == fraction and r.capacity == capacity
        and type(r.kWh) == "number" and r.kWh == r.kWh and r.kWh >= 0
        and r.kWh <= capacity * item:getUseDelta() + 1e-8 then
        return math.min(capacity, energy + r.kWh)
    end
    return energy
end

-- Native drainables round to integer uses. Never round energy upward or lose a
-- graduation on every tiny simulation step; carry the exact positive remainder.
function Batteries.setEnergy(item, energy, capacity)
    energy = LiveWire.clamp(energy, 0, capacity)
    item:setCurrentUsesFloat(capacity > 0 and energy / capacity or 0)
    if item:getCurrentUsesFloat() * capacity > energy + 1e-8 then
        item:setCurrentUses(math.max(0, item:getCurrentUses() - 1))
    end
    local fraction = item:getCurrentUsesFloat()
    item:getModData()[Batteries.ENERGY_KEY] = { fraction = fraction, capacity = capacity,
        kWh = math.max(0, energy - fraction * capacity) }
    return capacity > 0 and energy / capacity or 0
end

function Batteries.coldFactor(bank)
    local sq = getCell():getGridSquare(bank.x, bank.y, bank.z)
    if sq then bank.outside = sq:isOutside() end
    return LiveWire.Physics.coldFactor(getClimateManager():getTemperature(), bank.outside,
        LiveWire.Config.get("BatteryCold"))
end

-- Missing fields are lazy defaults for existing saves; item charge remains a warm fraction.
function Batteries.entry(bank, model, id, cond, fraction, cycles, item)
    local warm = Batteries.capacity(model, cond)
    local factor = Batteries.coldFactor(bank)
    local energy = warm * fraction
    local reserve = math.min(energy, warm * (1 - factor))
    return { bank = bank, model = model, id = id, item = item, cond = cond,
        capacity = warm * factor, charge = math.max(0, energy - reserve),
        reserve = reserve, warmCapacity = warm, coldFactor = factor,
        cycles = cycles or 0, wearFactor = bank.wearFactor or 1 }
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
            local cond = Batteries.condition(it)
            local cap = Batteries.capacity(it:getFullType(), cond)
            entries[#entries + 1] = Batteries.entry(bank, it:getFullType(), it:getID(), cond,
                cap > 0 and Batteries.energy(it, cap) / cap or 0, it:getModData()[Batteries.CYCLES_KEY], it)
        end
    elseif not gone then
        for i, s in ipairs(bank.slots or {}) do
            entries[#entries + 1] = Batteries.entry(bank, s.model, s.id, s.cond, s.charge or 0, s.cycles)
        end
    end
    return entries
end

-- Read-only LCD view, including an independent bank. Use the same energy/cold
-- model as simulation, never write quantised item charge from an interface read.
function Batteries.snapshot(bank)
    local def = LiveWire.Defs.devices[bank.model]
    if not def or bank.role ~= "storage" then return nil end
    local snap = { device = bank.id, model = bank.model,
        slots = def.slots or 4, extra = 0, stock = 0, capacity = 0, reserve = 0, batteries = {} }
    local entries = Batteries.read(bank)
    snap.extra = bank.extra or 0
    for i, e in ipairs(entries) do
        snap.stock = snap.stock + e.charge
        snap.capacity = snap.capacity + e.capacity
        snap.reserve = snap.reserve + e.reserve
        snap.batteries[i] = { model = e.model, charge = e.charge,
            capacity = e.capacity, cond = math.floor(e.cond + 0.5), coldFactor = e.coldFactor }
    end
    return snap
end

-- Write entries back: snapshot in the registry, and the items when loaded.
function Batteries.write(bank, entries)
    local slots = {}
    for i = 1, #entries do
        local e = entries[i]
        local frac = 0
        local warm = e.warmCapacity or e.capacity
        if warm > 0 then frac = LiveWire.clamp((e.charge + (e.reserve or 0)) / warm, 0, 1) end
        local cond = math.max(0, e.cond)
        slots[#slots + 1] = { id = e.id, model = e.model, charge = frac, cond = cond, cycles = e.cycles }
        local it = e.item
        if it then
            local oldFrac = it:getCurrentUsesFloat()
            local newCond = math.floor(cond + 0.5)
            local changedCondition = it:getCondition() ~= newCond
            cond = Batteries.setCondition(it, cond)
            slots[#slots].cond = cond
            local actualCapacity = Batteries.capacity(e.model, cond)
            frac = Batteries.setEnergy(it, e.charge + (e.reserve or 0), actualCapacity)
            slots[#slots].charge = frac
            e.cond, e.warmCapacity = cond, actualCapacity
            e.capacity = actualCapacity * (e.coldFactor or 1)
            local energy = frac * actualCapacity
            e.reserve = math.min(energy, math.max(0, actualCapacity - e.capacity))
            e.charge = math.max(0, energy - e.reserve)
            local changed = math.abs(oldFrac - frac) >= 0.005 or changedCondition
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
            Batteries.setCondition(it, s.cond or it:getCondition())
            local cap = Batteries.capacity(it:getFullType(), Batteries.condition(it))
            Batteries.setEnergy(it, LiveWire.clamp(s.charge or 0, 0, 1) * cap, cap)
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
