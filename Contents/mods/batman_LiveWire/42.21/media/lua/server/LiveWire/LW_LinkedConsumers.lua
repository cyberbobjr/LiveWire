-- Live Wire: consumers of other mods wired to an inverter (authority only, ADR-004).
-- A consumer registered with `link` (LW_Consumers.lua) is wired like the backup generator
-- and the management computer: its link lives in the object ModData under Defs.LINK_KEY
-- ({ id, inverter, pw }), its device in the registry ({ role = "consumer", model = <consumer
-- id>, x, y, z, wires, level, lastW }). Linked, it is powered by and billed to that inverter
-- only, wherever it stands. A mark whose device is unknown or elsewhere (the object was
-- moved) is ignored, and cleared when furniture is placed on its square.
if isClient() then return end
require "LiveWire/LW_EventBus"

LiveWire = LiveWire or {}

local LinkedConsumers = {}
LiveWire.LinkedConsumers = LinkedConsumers

local function R() return LiveWire.Registry end
local function key() return LiveWire.Defs.LINK_KEY end

-- The link mark of `obj` ({ id, inverter, pw }), valid or not, or nil.
function LinkedConsumers.markOf(obj)
    if not obj or not obj.hasModData or not obj:hasModData() then return nil end
    local m = obj:getModData()[key()]
    if type(m) == "table" and type(m.id) == "string" then return m end
    return nil
end

-- Registry device of the linked consumer `obj` and its mark, or nil when `obj` carries no
-- mark or a stale one (unknown device, other role, other square, no network).
function LinkedConsumers.deviceOf(obj)
    local m = LinkedConsumers.markOf(obj)
    local dev = m and R() and R().device(m.id)
    if not dev or dev.role ~= "consumer" or not dev.grid then return nil end
    local sq = obj:getSquare()
    if not sq or dev.x ~= sq:getX() or dev.y ~= sq:getY() or dev.z ~= sq:getZ() then return nil end
    return dev, m
end

-- Network the linked consumer `obj` belongs to, or nil.
function LinkedConsumers.gridOf(obj)
    local dev = LinkedConsumers.deviceOf(obj)
    return dev and R().grid(dev.grid) or nil
end

-- The linked object of `dev`, or nil; second result true when its square is loaded.
function LinkedConsumers.find(dev)
    local sq = getCell():getGridSquare(dev.x, dev.y, dev.z)
    if not sq then return nil, false end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local m = LinkedConsumers.markOf(o)
        if m and m.id == dev.id then return o, true end
    end
    return nil, true
end

-- fn(dev) for every consumer linked to `grid`. No sort: every caller sums or updates, and
-- billing must not sort (Demand.consumers runs it on every snapshot).
local function eachDevice(grid, fn)
    local Rg = R()
    for id in pairs(grid.members) do
        local dev = Rg.device(id)
        if dev and dev.role == "consumer" then fn(dev) end
    end
end

local function writeMark(obj, value)
    obj:getModData()[key()] = value
    if isServer() then obj:transmitModData() end
end

-- Wire `obj` (a linkable consumer) to `grid`; `level`: Electrical level of the electrician.
function LinkedConsumers.register(obj, grid, level)
    local sq = obj:getSquare()
    local entry = LiveWire.Consumers.linkable(obj)
    local info = LiveWire.Consumers.info(entry, obj)
    local dev = R().addDevice({
        role = "consumer", model = entry.id, x = sq:getX(), y = sq:getY(), z = sq:getZ(), level = level,
        -- Journal name: the mod's own name key, else the category of the consumer.
        nameKey = info and info.name or ("IGUI_LW_Appliance_" .. entry.category),
    })
    writeMark(obj, { id = dev.id, inverter = grid.inverter, pw = false })
    R().link(dev, grid)
    return dev
end

-- Drop the link: the mark of the loaded object is cleared and the device leaves the registry.
function LinkedConsumers.forget(dev)
    local obj = LinkedConsumers.find(dev)
    if obj then writeMark(obj, nil) end
    R().removeDevice(dev.id)
end

-- Is the linked consumer `dev` supplied by `grid`? The rule of every wired device
-- (Inverters.supplies) on the panel circuit its mod declared.
function LinkedConsumers.powered(dev, grid)
    local entry = LiveWire.Consumers.get(dev.model)
    return LiveWire.Inverters.supplies(grid, dev, entry and entry.circuit or "equipment")
end

-- Draw in W of the consumers linked to `grid` and its breakdown by category
-- ({ other = { n, w } }). A loaded, supplied consumer is measured (Consumption.watts) and
-- the value kept as `lastW`; an unloaded one bills its last measure (0 if never measured);
-- one that is not supplied bills nothing.
function LinkedConsumers.demandW(grid)
    local total, breakdown = 0, {}
    eachDevice(grid, function(dev)
        local w = 0
        if LinkedConsumers.powered(dev, grid) then
            local obj, loaded = LinkedConsumers.find(dev)
            if obj then
                w = LiveWire.Consumption.watts(obj)
                dev.lastW = w
            elseif not loaded then
                w = dev.lastW or 0
            end
        end
        if w > 0 then
            local entry = LiveWire.Consumers.get(dev.model)
            local cat = entry and entry.category or "other"
            local b = breakdown[cat] or { n = 0, w = 0 }
            b.n, b.w = b.n + 1, b.w + w
            breakdown[cat] = b
            total = total + w
        end
    end)
    return total, breakdown
end

-- Write the supplied state `pw` into the marks of the loaded linked consumers whose state
-- changed (read by LiveWire.API.consumerPowered on a client).
function LinkedConsumers.refreshMarks(grid)
    eachDevice(grid, function(dev)
        local obj = LinkedConsumers.find(dev)
        local m = obj and LinkedConsumers.markOf(obj)
        local pw = LinkedConsumers.powered(dev, grid)
        if m and m.pw ~= pw then
            writeMark(obj, { id = m.id, inverter = m.inverter, pw = pw })
        end
    end)
end

-- fn(obj, dev) for every loaded linked consumer of `grid`.
function LinkedConsumers.eachLoaded(grid, fn)
    eachDevice(grid, function(dev)
        local obj = LinkedConsumers.find(dev)
        if obj then fn(obj, dev) end
    end)
end

-- Picked up (not rotated): the wire comes back to `character` and the link is dropped.
function LinkedConsumers.onPickedUp(id, character)
    local dev = R() and R().device(id)
    if not dev or dev.role ~= "consumer" then return end
    local grid = dev.grid and R().grid(dev.grid)
    local wires = LiveWire.Devices.linkWires(dev)
    LinkedConsumers.forget(dev)
    if grid then LiveWire.Sim.refresh(grid) end
    LiveWire.Devices.returnWires(character, wires)
end

-- Furniture placed on `sq`: clear the stale link marks it carries (a picked-up thumpable
-- keeps its ModData in the item, IsoThumpable parameters in ISMoveableSpriteProps).
function LinkedConsumers.clearStale(sq)
    local Rg = R()
    if not sq or not Rg or not Rg.ready or Rg.readOnly then return end
    local objs = sq:getObjects()
    local stale = {}
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if LinkedConsumers.markOf(o) and not LinkedConsumers.deviceOf(o) then stale[#stale + 1] = o end
    end
    for i = 1, #stale do writeMark(stale[i], nil) end
end

LiveWire.Events.on(LiveWire.Events.LINKED_PICKED_UP, function(id, character)
    return LiveWire.LinkedConsumers.onPickedUp(id, character)
end)
LiveWire.Events.on(LiveWire.Events.SQUARE_CHANGED, function(sq)
    return LiveWire.LinkedConsumers.clearStale(sq)
end)
