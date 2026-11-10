-- Live Wire: native appliance service adapters, shared with action validation.
-- Authority owns choices. Client only mirrors container types, never inventory.
require "LiveWire/LW_ServiceSync"
require "LiveWire/LW_ApplianceFamilies"
LiveWire = LiveWire or {}
local A = {}
LiveWire.Appliances = A
A.FAMILIES = LiveWire.ApplianceFamilies.list -- the same table: extensions append to it
local KEY = "LiveWireCircuit"
function A.saved(o) return o and o:hasModData() and o:getModData()[KEY] or nil end
function A.kind(o)
    -- Shared actions also receive inventory radios, vehicle parts and fluid items.
    -- Only placed world appliances belong to the electrical panel.
    -- IsoObject guarantees the container/sprite API; having a square does not.
    if not o or not instanceof(o, "IsoObject") or instanceof(o, "IsoWorldInventoryObject") then return nil end
    if instanceof(o, "IsoRadio") and o:getDeviceData():getIsBatteryPowered() then return nil end
    if instanceof(o, "IsoLightSwitch") and o:getCanBeModified() and o:getUseBattery() then return nil end
    local s = A.saved(o)
    if s then return s.kind end
    local family = LiveWire.ApplianceFamilies.of(o, "kind")
    return family and family.kind or nil
end
-- Cut test of an object whose kind is already known (nil = not an appliance).
function A.blockedAs(o, kind)
    if not kind or not o:getSquare() then return false end
    if not isClient() and LiveWire.Circuits then return LiveWire.Circuits.blockedAs(o, kind) end
    local s = A.saved(o)
    return s and s.cut == true or false
end
function A.blocked(o)
    return A.blockedAs(o, A.kind(o))
end
local function age(cont)
    local items = cont:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if instanceof(it, "Food") then it:updateAge()
        elseif instanceof(it, "InventoryContainer") then age(it:getInventory()) end
    end
end
function A.capture(o, grid)
    local s = A.saved(o)
    if s then return s end
    local kind = A.kind(o)
    if not kind then return nil end
    -- grid is nil for a point cut by a sub-mod's breaker before any inverter serves it
    s = { v = 1, kind = kind, owner = grid and grid.id, cut = true,
        watts = LiveWire.Consumption.watts(o, nil, true), category = LiveWire.Demand.category(o) }
    if kind == "light" then s.on = o:isActivated()
    elseif kind == "media" then s.on = o:getDeviceData():getIsTurnedOn()
    elseif kind == "stove" then s.on = o:Activated()
    elseif kind == "stacked" then s.on, s.dry = o:isWasherActivated(), o:isDryerActivated()
    elseif kind == "fridge" then
        s.types = {}
        for i = 0, o:getContainerCount() - 1 do
            local c = o:getContainerByIndex(i)
            if c:isFridge() or c:isFreezer() then s.types[tostring(i)] = c:getType() end
        end
    elseif kind ~= "fuel" then s.on = o:isActivated() end
    s.syncPending = true
    o:getModData()[KEY] = s
    return s
end
-- A small changed-object packet avoids CONTAINERS, which replaces client items.
local function syncService(o, s, off)
    if isServer() then LiveWire.ServiceSync.publish(o, s) end
end
local function activation(o, getter, setter, wanted, change)
    if o[getter](o) == wanted then return false end
    o[setter](o, wanted)
    if change then o:sendObjectChange(change) end
    return true
end
-- Steps for a saved kind that no family declares: the generic on/off toggle.
local GENERIC_STEPS = { { get = "isActivated", set = "setActivated", field = "on", change = "DRYER_STATE" } }
-- Returns true after restoration succeeded. Native setter limitations are kept.
function A.apply(o, s, off)
    local k, changed = s.kind, false
    -- Native appliance updates switch themselves off without current. Retain the
    -- original ON choice until it can really be restored (e.g. after a main trip).
    local wantsOn = s.on or (k == "stacked" and s.dry)
    if not off and wantsOn and k ~= "light" and k ~= "fuel"
        and not (k == "media" and o:getDeviceData():getIsBatteryPowered())
        and not ItemContainer.isObjectPowered(o, true) then return false end
    if k == "fridge" then
        for i, original in pairs(s.types) do
            local c = o:getContainerByIndex(tonumber(i))
            local wanted = off and "none" or original
            if c and c:getType() ~= wanted then
                age(c) -- settle elapsed time under the OLD service before switching
                c:setType(wanted); changed = true
            end
        end
        if changed then
            local chunk = o:getChunk()
            if chunk then
                if o:couldBePoweredByGenerator() then chunk:addObjectPoweredByGenerator(o)
                else chunk:removeObjectPoweredByGenerator(o) end
            end
            o:checkHaveElectricity()
        end
        if changed or s.syncPending then syncService(o, s, off) end
    elseif k == "light" then
        changed = activation(o, "isActivated", "setActive", not off and s.on)
        -- setActive's full native overload handles room switches and networking.
        if o:isActivated() ~= (not off and s.on) then o:setActive(not off and s.on, false, true) end
        if not off and o:isActivated() ~= s.on then return false end
    elseif k == "media" then
        local d, wanted = o:getDeviceData(), not off and s.on
        if d:getIsTurnedOn() ~= wanted then
            d:setIsTurnedOn(wanted); changed = true
        end
        -- Native setIsTurnedOn only transmits when called by a client. Send the
        -- initial OFF choice too, even when no setter call was necessary.
        if changed or s.syncPending then syncService(o, s, off) end
        if not off and d:getIsTurnedOn() ~= s.on then return false end
    elseif k ~= "fuel" then
        local family = LiveWire.ApplianceFamilies.ofKind(k)
        local steps = family and family.activation or GENERIC_STEPS
        for i = 1, #steps do
            local step = steps[i]
            local name = step.change
            if type(name) == "function" then name = name(o) end
            local did = activation(o, step.get, step.set, not off and s[step.field], name and IsoObjectChange[name])
            if did and step.sync then o:sync() end
            changed = did or changed
        end
    end
    if s.cut ~= off or changed or s.syncPending then
        s.syncPending = nil
        s.cut = off
        -- restore() publishes the final removal in one packet. Do not send an
        -- intermediate restored marker immediately before that same removal.
        if off then o:transmitModData() end
    end
    return true
end
function A.restore(o)
    local s = A.saved(o)
    if not s then return end
    if A.apply(o, s, false) then o:getModData()[KEY] = nil; o:transmitModData() end
end
local function mirror(o)
    local s = A.saved(o)
    if not s or s.kind ~= "fridge" then return end
    for i, original in pairs(s.types) do
        local c = o:getContainerByIndex(tonumber(i))
        if c then c:setType(s.cut and "none" or original) end
    end
end
if isClient() then
    Events.LoadChunk.Add(function(chunk)
        for z = chunk:getMinLevel(), chunk:getMaxLevel() do
            for i = 0, 63 do
                local sq = chunk:getGridSquare(i % 8, math.floor(i / 8), z)
                local objects = sq and sq:getObjects()
                for j = 0, objects and objects:size() - 1 or -1 do mirror(objects:get(j)) end
            end
        end
    end)
    Events.OnObjectAdded.Add(mirror)
end
-- Block native interactions on both peers, and recheck at authoritative completion.
-- These are action hooks, not frame/render hooks. Unrelated actions retain returns.
-- The appliance family of the target never changes during an action: it is resolved on the
-- first call and kept on the action instance (never in ModData). Whether the panel is cut
-- can change at any time (trip, reset), so that test runs on every call.
local function guard(className, class, field, methods)
    for _, name in ipairs(methods) do
        local previous = class[name]
        if previous then
            class[name] = function(self, ...)
                local target = self[field]
                if target ~= nil then
                    local kind = self.lwKind
                    if kind == nil then
                        kind = A.kind(target) or false
                        self.lwKind = kind
                    end
                    if A.blockedAs(target, kind or nil) then return false end
                end
                return previous(self, ...)
            end
        else
            LiveWire.warn("guarded vanilla method missing: " .. className .. "." .. name)
        end
    end
end
local specs = {
    { "ISToggleClothingWasher", "object" }, { "ISToggleClothingDryer", "object" },
    { "ISToggleComboWasherDryer", "object" }, { "ISSetComboWasherDryerMode", "object" },
    { "ISToggleStoveAction", "object" }, { "ISActivateCarBatteryChargerAction", "charger" },
}
for _, spec in ipairs(specs) do
    require("TimedActions/" .. spec[1])
    guard(spec[1], _G[spec[1]], spec[2], { "isValid", "complete" })
end
require "TimedActions/ISTakeFuel"
guard("ISTakeFuel", ISTakeFuel, "fuelStation", { "isValid", "complete", "updateUse" })
require "Vehicles/TimedActions/ISRefuelFromGasPump"
guard("ISRefuelFromGasPump", ISRefuelFromGasPump, "fuelStation", { "isValid", "update", "complete", "serverStop" })
-- B42 fluid-component pumps also expose the general fluid transfer/fill menus.
require "Fluids/ISFluidTransferAction"
guard("ISFluidTransferAction", ISFluidTransferAction, "sourceOwner", { "isValid", "update", "complete" })
require "TimedActions/ISTakeWaterAction"
guard("ISTakeWaterAction", ISTakeWaterAction, "waterObject", { "isValid", "updateUse", "transferFluid", "complete" })
require "RadioCom/ISRadioAction"
guard("ISRadioAction", ISRadioAction, "device", { "isValidToggleOnOff", "performToggleOnOff" })
