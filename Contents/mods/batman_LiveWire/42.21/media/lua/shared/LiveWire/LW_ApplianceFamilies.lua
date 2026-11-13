-- Live Wire: vanilla appliance families as data (D-50). One ordered table says, for every
-- family of placed appliance, how the panel (kind), the inverter interface (category), the
-- consumption profiles (profile) and the restore step (activation) treat it. Pure data and
-- lookups: no timed action is touched here, so any module may require it.
-- LiveWire.Appliances.FAMILIES is this same table (see LW_Appliances).
require "LiveWire/LW_Consumers"
LiveWire = LiveWire or {}
local Fam = {}
LiveWire.ApplianceFamilies = Fam

-- Consumption profile functions: (object, profile table) -> W while on, nil = engine value.
local function stoveWatts(o, t)
    if o:isMicrowave() then return t.microwave end
    return t.stove
end
local function stackedWatts(o, t)
    if not t.washer then return nil end
    local w = 0
    if o:isWasherActivated() then w = w + t.washer end
    if o:isDryerActivated() then w = w + t.dryer end
    return w
end
local function comboWatts(o, t)
    if o:isModeDryer() then return t.comboDryer end
    return t.washer
end
local function fridgeWatts(o, t)
    if o:getContainerByType("fridge") and o:getContainerByType("freezer") then return t.fridgeFreezer end
    return t.fridge
end
local function hasFridgeContainer(o)
    return (o:getContainerByType("fridge") or o:getContainerByType("freezer")) and true or false
end
local function hasFuelAmount(o)
    return (o:getSprite() and o:getSprite():getProperties():has(IsoPropertyType.FUEL_AMOUNT)) and true or false
end
-- Appliances of other mods registered through LiveWire.API.registerConsumer (ADR-002).
local function isConsumer(o) return LiveWire.Consumers.of(o) ~= nil end
local function consumerCategory(o)
    local c = LiveWire.Consumers.of(o)
    return c and c.category or "other"
end
local function consumerCircuit(o)
    local c = LiveWire.Consumers.of(o)
    return c and c.circuit or "equipment"
end
-- IsoObjectChange name sent with the state change; resolved when applied (global set by the engine).
local function comboChange(o) return o:isModeWasher() and "WASHER_STATE" or "DRYER_STATE" end

-- Entry: class (string) or match (function(o) -> boolean), then
--   kind        panel kind saved in ModData (nil: not handled by the panel)
--   category    inverter interface family, or function(o) -> family (nil: reported as "other")
--   circuit     panel circuit that cuts it: "light", or function(o) -> circuit (nil: "equipment")
--   stateless   true: no on/off state of its own is saved or restored (Live Wire only bills it)
--   profile     key of Consumption.PROFILES, or function(o, t) -> W or nil (nil: engine value)
--   activation  steps { get, set, field, change (name or function(o) -> name), sync }: getter and
--               setter of the on/off state, saved field ("on" or "dry"); nil: handled by apply itself
-- The first matching entry wins; the real classes are unrelated siblings of IsoObject, so only the
-- container and sprite tests at the end depend on the order. A registered consumer comes first:
-- its mod's declaration replaces whatever the engine says about the object.
Fam.list = {
    { match = isConsumer, kind = "consumer", category = consumerCategory, circuit = consumerCircuit,
      stateless = true },
    { class = "IsoLightSwitch", kind = "light", category = "light", profile = "light", circuit = "light" },
    { class = "IsoTelevision", kind = "media", category = "tv", profile = "tv" },
    { class = "IsoRadio", kind = "media", category = "radio", profile = "radio" },
    { class = "IsoStove", kind = "stove", category = "stove", profile = stoveWatts,
      activation = { { get = "Activated", set = "setActivated", field = "on" } } },
    { class = "IsoStackedWasherDryer", kind = "stacked", category = "laundry", profile = stackedWatts,
      activation = {
          { get = "isWasherActivated", set = "setWasherActivated", field = "on", change = "WASHER_STATE" },
          { get = "isDryerActivated", set = "setDryerActivated", field = "dry", change = "DRYER_STATE" },
      } },
    { class = "IsoCombinationWasherDryer", kind = "combo", category = "laundry", profile = comboWatts,
      activation = { { get = "isActivated", set = "setActivated", field = "on", change = comboChange } } },
    { class = "IsoClothingWasher", kind = "washer", category = "laundry", profile = "washer",
      activation = { { get = "isActivated", set = "setActivated", field = "on", change = "WASHER_STATE" } } },
    { class = "IsoClothingDryer", kind = "dryer", category = "laundry", profile = "dryer",
      activation = { { get = "isActivated", set = "setActivated", field = "on", change = "DRYER_STATE" } } },
    { class = "IsoCarBatteryCharger", kind = "charger", category = "charger", profile = "charger",
      activation = { { get = "isActivated", set = "setActivated", field = "on", sync = true } } },
    { match = hasFridgeContainer, kind = "fridge", category = "fridge", profile = fridgeWatts },
    { match = hasFuelAmount, kind = "fuel", stateless = true },
}

-- First family of an object that declares `field` ("kind", "category" or "profile"), or nil.
-- Families without that field are not tested: a caller never probes an object for a family
-- it has no use for.
function Fam.of(o, field)
    local list = Fam.list
    for i = 1, #list do
        local f = list[i]
        if f[field] ~= nil then
            if f.class then
                if instanceof(o, f.class) then return f end
            elseif f.match(o) then
                return f
            end
        end
    end
    return nil
end

-- First family declaring `kind` (a saved kind), or nil.
function Fam.ofKind(kind)
    local list = Fam.list
    for i = 1, #list do
        if list[i].kind == kind then return list[i] end
    end
    return nil
end

-- Value of a family field that may be a function of the object (category, circuit).
function Fam.value(family, field, o)
    local v = family and family[field]
    if type(v) == "function" then return v(o) end
    return v
end

-- Panel circuit of an object of family `kind`: "light" or "equipment".
function Fam.circuit(o, kind)
    return Fam.value(Fam.ofKind(kind), "circuit", o) or "equipment"
end
