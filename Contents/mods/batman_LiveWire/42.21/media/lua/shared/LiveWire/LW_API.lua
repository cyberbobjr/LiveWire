-- Live Wire: versioned registration API. No registry tables cross this boundary.
require "LiveWire/LW_Defs"
require "LiveWire/LW_Coverage"
require "LiveWire/LW_Extension"
LiveWire = LiveWire or {}
local API = { version = 1, revision = 4 }
LiveWire.API = API
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
    if LiveWire.Extension.isSealed() then return false, "registration_closed" end
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
-- Lights of a registered source (optional `overlays`, see LW_Defs.lua): the first sprite
-- of each light in the source's own sheet, light for facing f = value + f; `rotor` is the
-- first of 4 blade frames of 4 sprites. No light sprite may fall on the device's 4 tiles.
-- Returns a checked copy, false when invalid, nil when absent.
local LIGHTS = { on = 4, fault = 4, muffle = 4, linked = 4, tripped = 4, powered = 4, ringing = 4, rotor = 16 }
local function overlaysOf(o, tile)
    if o == nil then return nil end
    if type(o) ~= "table" then return false end
    local out = {}
    for k, v in pairs(o) do
        if k == "blinkWhenBraked" then
            if type(v) ~= "boolean" then return false end
            out[k] = v
        else
            local span = LIGHTS[k]
            if not span or not number(v, 0, 100000) or v % 1 ~= 0 then return false end
            if v < tile + 4 and v + span > tile then return false end
            out[k] = v
        end
    end
    return out
end
function API.registerSource(model, definition)
    if LiveWire.Extension.isSealed() then return false, "registration_closed" end
    local d = definition
    local overlays = type(d) == "table" and number(d.tile, 0, 100000) and overlaysOf(d.overlays, d.tile)
    if type(model) ~= "string" or #model > 64 or not string.match(model, "^[%a][%w_]+$")
        or type(d) ~= "table" or not identifier(d.item)
        or (d.kind ~= "solar" and d.kind ~= "wind" and d.kind ~= "hydro")
        or not number(d.nominalW, 1, 100000) or not number(d.tile, 0, 100000)
        or d.tile % 1 ~= 0 or d.facings ~= 4 or type(d.sheet) ~= "string"
        or not string.match(d.sheet, "^[%w_]+$") or not number(d.level, 0, 10)
        or not number(d.wearDays, 1, 100000) or overlays == false then return false, "invalid_definition" end
    local defs = LiveWire.Defs
    if defs.devices[model] or defs.itemToModel[d.item] then return false, "duplicate_model" end
    for i = 0, 3 do
        if defs.spriteToModel[d.sheet .. "_" .. (d.tile + i)] then return false, "duplicate_sprite" end
    end
    -- Whitelist primitives: caller mutations and extra fields cannot change our definition.
    defs.devices[model] = { role = "source", kind = d.kind, item = d.item,
        tile = d.tile, facings = 4, sheet = d.sheet, nominalW = d.nominalW,
        level = d.level, wearDays = d.wearDays, xp = 0, needsOutside = true,
        needsRiver = d.kind == "hydro", overlays = overlays or nil }
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
        if LiveWire.Coverage.covers(id, a, x, y, z, radius, floors)
            and (not best or d < dist or (d == dist and id < best)) then best, dist = id, d end
    end
    local inv = best and R.device(best)
    local grid = inv and R.grid(inv.grid)
    return grid and copy(LiveWire.Sim.snapshot(grid)) or nil
end
-- ---------------------------------------------------------------- services for sub-mods (revision 2, D-47)
-- Add-ons never reach the internal modules. Each function below looks its module up when
-- it is called (server modules are not loaded everywhere) and hands out detached copies of
-- anything that comes from the saved state. Where the registry does not exist (client,
-- before initialisation) they answer nil, false, 0 or an empty list.
local WIRE = "Base.ElectricWire"

local function inverterCopy(dev)
    return { id = dev.id, x = dev.x, y = dev.y, z = dev.z, role = dev.role,
        coupled = dev.coupled and true or false, master = dev.coupled or nil }
end

-- Registry (authority): is it ready, and may it be written?
function API.writable()
    local R = LiveWire.Registry
    return R ~= nil and R.ready == true and not R.readOnly
end

-- Inverter `id` as { id, x, y, z, role, coupled (boolean), master (id or nil) }, or nil.
function API.inverter(id)
    local R = LiveWire.Registry
    local dev = R and R.ready and R.device(id)
    if not dev or dev.role ~= "inverter" then return nil end
    return inverterCopy(dev)
end

-- Is `id` a device of the registry (any role), whatever its state?
function API.deviceKnown(id)
    local R = LiveWire.Registry
    return R ~= nil and R.device(id) ~= nil
end

-- Inverter behind the placed object `obj`, standing on the square it is registered on
-- (same shape as API.inverter), or nil. Authority only.
function API.inverterOfObject(obj)
    local R = LiveWire.Registry
    local m = LiveWire.Marks.get(obj)
    if not m or not R or not R.ready or isClient() then return nil end
    local dev = R.device(m.id)
    local sq = obj:getSquare()
    if not dev or dev.role ~= "inverter" or not sq
        or dev.x ~= sq:getX() or dev.y ~= sq:getY() or dev.z ~= sq:getZ() then return nil end
    return inverterCopy(dev)
end

-- Ids of the inverters that have an appliance inventory (a new array).
function API.inventoryIds()
    local D = LiveWire.Demand
    return D and D.ids() or {}
end

-- fn(object, watts) for each appliance the last measurement billed to inverter `invId`
-- (watts above 0, circuit loads). The objects are live game objects, not state tables.
function API.eachBilled(invId, fn)
    local D, R = LiveWire.Demand, LiveWire.Registry
    local inv = D and R and type(fn) == "function" and R.device(invId)
    if inv then D.each(inv, fn) end
end

-- Ask for a new measurement of the inverter's appliances (nil: every inverter).
function API.invalidateDemand(id)
    local D = LiveWire.Demand
    if D then D.invalidate(id) end
end

-- Apply the circuit decision to one appliance object.
function API.applyCircuits(obj)
    local C = LiveWire.Circuits
    if C then C.applyObject(obj) end
end

-- Revisit every appliance of the inventories, progressively.
function API.topologyChanged()
    local C = LiveWire.Circuits
    if C then C.topologyChanged() end
end

-- fn(chunk-object) is called by the chunk discovery walk. False when it cannot be registered.
function API.addChunkVisitor(fn)
    local C = LiveWire.Circuits
    if type(fn) ~= "function" or not C then return false end
    C.addChunkVisitor(fn)
    return true
end

-- Placement helpers (character side).
function API.screwdriver(character) return LiveWire.Install.screwdriver(character) end
function API.showScrewdriver(action) LiveWire.Install.showScrewdriver(action) end
function API.countType(character, fullType) return LiveWire.Install.countType(character, fullType) end
function API.hasLevel(character, level) return LiveWire.Install.hasLevel(character, level) end
function API.consume(character, fullType, n) return LiveWire.Install.consume(character, fullType, n) end
function API.giveItem(character, fullType) return LiveWire.Install.giveItem(character, fullType) end
function API.distance(x1, y1, z1, x2, y2, z2) return LiveWire.Install.distance(x1, y1, z1, x2, y2, z2) end
function API.wiresFor(dist) return LiveWire.Install.wiresFor(dist) end

-- Inverter objects within link range of square `sq`, nearest first: a new array of { obj, dist }.
function API.invertersInRange(sq)
    local out = {}
    local list = LiveWire.Install.invertersInRange(sq)
    for i = 1, #list do out[i] = { obj = list[i].obj, dist = list[i].dist } end
    return out
end

-- Can `character` run an electric cable between squares `a` and `b`? Same rules, keys and
-- order as Live Wire's own link: floors (LinkVerticalRange), reach (LinkRange), Electrical
-- level (only when `level` is given; `levelKey` is the refusal key, default
-- "Tooltip_LW_NeedLevel"), wire in the inventory. Returns true, nil, wires; or
-- false, key, arg1, arg2. It goes through API.distance/hasLevel/wiresFor/countType.
function API.cableCheck(character, a, b, level, levelKey)
    if not a or not b then return false, "Tooltip_LW_Invalid" end
    local dist, dz = API.distance(a:getX(), a:getY(), a:getZ(), b:getX(), b:getY(), b:getZ())
    local floors = LiveWire.Config.get("LinkVerticalRange")
    if dz > floors then return false, "Tooltip_LW_TooManyFloors", tostring(dz), tostring(floors) end
    local range = LiveWire.Config.get("LinkRange")
    if dist > range then
        return false, "Tooltip_LW_TooFarForCable", tostring(math.ceil(dist - 1e-9)), tostring(range)
    end
    if level ~= nil and not API.hasLevel(character, level) then
        return false, levelKey or "Tooltip_LW_NeedLevel", tostring(LiveWire.Config.requiredLevel(level))
    end
    local wires = API.wiresFor(dist)
    if API.countType(character, WIRE) < wires then return false, "Tooltip_LW_NeedWire", wires end
    return true, nil, wires
end

-- Give `n` electric wires back to `character` (with Live Wire's message); returns the number given.
function API.returnWires(character, n)
    local D = LiveWire.Devices
    if not D then return 0 end
    return D.returnWires(character, n)
end

-- Electrical XP once per `periodHours` for (character, key); false when refused or unavailable.
function API.awardXp(character, key, amount, periodHours)
    local Xp = LiveWire.Xp
    if not Xp then return false end
    return Xp.awardLimited(character, key, amount, periodHours)
end

-- Draw in W of a load the engine reports as 0, estimated at `w` W (sandbox applied).
function API.estimateWatts(w) return LiveWire.Consumption.estimate(w) end

-- Draw in W of a placed appliance, 0 when it is off.
function API.watts(obj) return LiveWire.Consumption.watts(obj) end

-- Appliance family of a placed object ("light", "fridge"...), or nil.
function API.applianceKind(obj) return LiveWire.Appliances.kind(obj) end

-- Is the appliance cut by a circuit decision?
function API.applianceCut(obj)
    local saved = LiveWire.Appliances.saved(obj)
    return (saved and saved.cut) and true or false
end

-- Mark of a placed Live Wire object (a copy: id, model, ...), or nil.
function API.mark(obj)
    local m = LiveWire.Marks.get(obj)
    return m and copy(m) or nil
end

-- Placed Live Wire object `id` on square `sq` (a live game object), or nil.
function API.markOnSquare(sq, id) return LiveWire.Marks.findOnSquare(sq, id) end

-- Definition of device model `name` (a copy), or nil.
function API.model(name) return copy(LiveWire.Defs.devices[name]) end

-- Id of the water pump a placed object is, or nil.
function API.pumpId(obj)
    local m = LiveWire.Marks.get(obj)
    local def = m and LiveWire.Defs.devices[m.model]
    if def and def.role == "pump" then return m.id end
    return nil
end

-- Id of the management computer link a vanilla computer object carries, or nil.
function API.computerId(obj)
    local c = obj.hasModData and obj:hasModData() and obj:getModData()[LiveWire.Defs.COMPUTER_KEY]
    return c and c.id or nil
end

-- One provider of extra lines for the House tab of the inverter software (client).
-- fn(inverterId) -> array of translated strings. A second, different function is refused.
local softwareProvider
function API.registerSoftwareLines(fn)
    if type(fn) ~= "function" then return false, "invalid_provider" end
    if softwareProvider and softwareProvider ~= fn then return false, "already_registered" end
    softwareProvider = fn
    return true
end

-- Lines of the registered provider for `inverterId`: a new array of strings, empty when
-- there is no provider. Read by the inverter software.
function API.softwareLines(inverterId)
    local out = {}
    local lines = softwareProvider and softwareProvider(inverterId)
    if type(lines) ~= "table" then return out end
    for i = 1, #lines do
        if type(lines[i]) == "string" then out[#out + 1] = lines[i] end
    end
    return out
end


-- Drawing kit of the enclosure windows (client, LiveWire.Enclosure, D-54): the module itself, not a
-- copy, as it holds no game state. Read by LiveWire Extended when its window opens; nil on a server.
function API.enclosure() return LiveWire.Enclosure end

-- Name of the network an inverter feeds: a string ("" when the network is unnamed), or nil when
-- the inverter is unknown. The authority reads the saved grid; a client reads the snapshot of
-- the inverter it subscribed to (API.subscribeInverter). LiveWire Extended shows it on the LCD
-- of its board window (D-47).
function API.gridName(inverterId)
    local R = LiveWire.Registry
    if not isClient() then
        local dev = R and R.ready and R.device(inverterId)
        local grid = dev and dev.grid and R.grid(dev.grid)
        return grid and grid.name or nil
    end
    local C = LiveWire.Client
    local snap = C and C.snapshot and C.snapshot(inverterId)
    return snap and snap.name or nil
end

-- Client: player 0 when a direct left click on world object `obj` may open its screen, under
-- the rules of Live Wire's own screens (reach, sight, same floor, no obstacle, safehouse, not
-- aiming, asleep, driving, dragging or paused); nil otherwise and where there is no client UI.
function API.directClickPlayer(obj)
    local E = LiveWire.Equipment
    return obj and E and E.clickPlayer(obj) or nil
end

-- Placement rule of a sub-mod (D-62): rule(spriteName, square, character) returns nil when the
-- tile is not its concern, true, or false and a tooltip key shown in red by the furniture cursor.
-- Checked on the client and on the authority for every tile. Call while Lua files load: false
-- after OnInitGlobalModData or when `rule` is not a function.
function API.addPlacementRule(rule)
    local Placement = LiveWire.Placement
    return Placement ~= nil and Placement.addRule(rule) or false
end

-- Asks the server for the snapshots of an inverter, as Live Wire's own panels do (client).
-- Returns false where there is no client.
function API.subscribeInverter(inverterId)
    local C, Protocol = LiveWire.Client, LiveWire.Protocol
    if not isClient() or not C or not C.send or not Protocol then return false end
    C.send(Protocol.C_SUBSCRIBE, { inverter = inverterId })
    return true
end

-- ---------------------------------------------------------------- network and range view (revision 3)
-- Asked by the author of a coupling add-on, so that it stops reading LiveWire.Anchor,
-- LiveWire.RangeView and LiveWire.Menu directly.

-- Inverters of the network that inverter `inverterId` belongs to (master or coupled): a new
-- array of { id, x, y, z, master (boolean) }, master first, or nil when the network is
-- unknown. The authority reads the registry; a client reads the snapshot of the inverter
-- it subscribed to (API.subscribeInverter: pass the master's id).
function API.networkInverters(inverterId)
    local R = LiveWire.Registry
    if not isClient() then
        local dev = R and R.ready and R.device(inverterId)
        local grid = dev and dev.grid and R.grid(dev.grid)
        local master = grid and R.device(grid.inverter)
        if not master then return nil end
        local out = { { id = master.id, x = master.x, y = master.y, z = master.z, master = true } }
        local slaves = R.slaves(grid)
        for i = 1, #slaves do
            local sl = slaves[i]
            out[i + 1] = { id = sl.id, x = sl.x, y = sl.y, z = sl.z, master = false }
        end
        return out
    end
    local C = LiveWire.Client
    local snap = C and C.snapshot and C.snapshot(inverterId)
    return snap and snap.network and copy(snap.network) or nil
end

-- Every power anchor (powered zone) known on this side, server or client: a new table
-- { [inverterId] = { x, y, z, on (boolean) } }. Coupled inverters appear only while a
-- coupling add-on keeps their zone (D-45).
function API.anchors()
    local out = {}
    local A = LiveWire.Anchor
    for id, a in pairs(A and A.table() or {}) do
        out[id] = { x = a.x, y = a.y, z = a.z, on = a.on == true }
    end
    return out
end

-- Range view (client). Show the powered area of inverter `inverterId` centred on (x, y, z), as
-- the "Show powered area" option does; `opts` (optional) { radius, color = { r, g, b, a },
-- floors } draws another circle instead. False where there is no range view (server).
function API.showRange(inverterId, x, y, z, opts)
    local RV = LiveWire.RangeView
    if not RV then return false end
    RV.show(inverterId, x, y, z, opts)
    return true
end

function API.hideRange()
    local RV = LiveWire.RangeView
    if RV then RV.hide() end
end

-- Is the powered area of `inverterId` shown? (nil: is any range shown?)
function API.rangeShown(inverterId)
    local RV = LiveWire.RangeView
    if not RV then return false end
    if inverterId == nil then return RV.inverterId ~= nil end
    return RV.isShown(inverterId)
end

-- Colour of the powered area line (a copy { r, g, b, a }), or nil on a server.
function API.rangeColor()
    local RV = LiveWire.RangeView
    return RV and copy(RV.COLOR) or nil
end

-- fn(inverterId, shown) is called on a client when the powered area of an inverter is shown
-- or hidden (menu option, walking away, another view replacing it). May be called from any
-- file, shared or client; registering the same function twice keeps one. False when `fn` is
-- not a function.
local rangeListeners = {}
function API.onRangeView(fn)
    if type(fn) ~= "function" then return false end
    for i = 1, #rangeListeners do
        if rangeListeners[i] == fn then return true end
    end
    rangeListeners[#rangeListeners + 1] = fn
    return true
end

-- The listeners of API.onRangeView (a new array), read by the range view (LW_RangeView).
function API.rangeViewListeners()
    local out = {}
    for i = 1, #rangeListeners do out[i] = rangeListeners[i] end
    return out
end
