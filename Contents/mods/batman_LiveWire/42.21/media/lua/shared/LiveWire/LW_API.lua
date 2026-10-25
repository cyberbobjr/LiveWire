-- Live Wire: versioned registration API. No registry tables cross this boundary.
require "LiveWire/LW_Defs"
LiveWire = LiveWire or {}
local API = { version = 1 }
LiveWire.API = API
local sealed = false
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = copy(v) end
    return out
end
local function number(v, low, high)
    return type(v) == "number" and v == v and v >= low and v <= high
end
local function identifier(v)
    return type(v) == "string" and #v <= 120 and string.match(v, "^[%w_]+%.[%w_]+$") ~= nil
end
function API.registerBattery(fullType, kWh, lifeCycles)
    if sealed then return false, "registration_closed" end
    if not identifier(fullType) or not number(kWh, 0.001, 1000)
        or not number(lifeCycles, 1, 1000000) then return false, "invalid_definition" end
    if LiveWire.Defs.batteries[fullType] then return false, "duplicate_type" end
    local script = getScriptManager():FindItem(fullType)
    if not script or script:getItemType() ~= ItemType.DRAINABLE
        or script:getConditionMax() ~= 100 or not script:isKeepOnDeplete() then
        return false, "invalid_definition"
    end
    LiveWire.Defs.batteries[fullType] = { capacityKWh = kWh, lifeCycles = lifeCycles }
    return true
end
function API.registerSource(model, definition)
    if sealed then return false, "registration_closed" end
    local d = definition
    if type(model) ~= "string" or #model > 64 or not string.match(model, "^[%a][%w_]+$")
        or type(d) ~= "table" or not identifier(d.item)
        or (d.kind ~= "solar" and d.kind ~= "wind" and d.kind ~= "hydro")
        or not number(d.nominalW, 1, 100000) or not number(d.tile, 0, 100000)
        or d.tile % 1 ~= 0 or d.facings ~= 4 or type(d.sheet) ~= "string"
        or not string.match(d.sheet, "^[%w_]+$") or not number(d.level, 0, 10)
        or not number(d.wearDays, 1, 100000) then return false, "invalid_definition" end
    local defs = LiveWire.Defs
    if defs.devices[model] or defs.itemToModel[d.item] then return false, "duplicate_model" end
    for i = 0, 3 do
        if defs.spriteToModel[d.sheet .. "_" .. (d.tile + i)] then return false, "duplicate_sprite" end
    end
    -- Whitelist primitives: caller mutations and extra fields cannot change our definition.
    defs.devices[model] = { role = "source", kind = d.kind, item = d.item,
        tile = d.tile, facings = 4, sheet = d.sheet, nominalW = d.nominalW,
        level = d.level, wearDays = d.wearDays, xp = 0, needsOutside = true,
        needsRiver = d.kind == "hydro" }
    defs.itemToModel[d.item] = model
    for i = 0, 3 do defs.spriteToModel[d.sheet .. "_" .. (d.tile + i)] = model end
    return true
end
function API.battery(fullType) return copy(LiveWire.Defs.batteries[fullType]) end
function API.source(model)
    local d = LiveWire.Defs.devices[model]
    return d and d.role == "source" and copy(d) or nil
end
function API.gridAt(x, y, z)
    local R = LiveWire.Registry
    if isClient() or not R or not R.ready or not LiveWire.Sim then return nil, "not_ready" end
    if not number(x, -1000000, 1000000) or not number(y, -1000000, 1000000)
        or not number(z, -32, 31) then return nil, "invalid_position" end
    local best, dist
    local radius, floors = LiveWire.Config.tileRange(), LiveWire.Config.verticalRange()
    for id, a in pairs(R.anchors or {}) do
        local d = (x - a.x)^2 + (y - a.y)^2
        if d <= radius^2 and math.abs(z - a.z) <= floors
            and (not best or d < dist or (d == dist and id < best)) then best, dist = id, d end
    end
    local inv = best and R.device(best)
    local grid = inv and R.grid(inv.grid)
    return grid and copy(LiveWire.Sim.snapshot(grid)) or nil
end
Events.OnInitGlobalModData.Add(function() sealed = true end)
