-- Live Wire: authoritative registry of devices and networks (authority only).
-- Stored in the global ModData "LiveWire" (saved in global_mod_data.bin). Never
-- transmitted: clients receive snapshots and the public anchor table only.
if isClient() then return end
require "LiveWire/LW_PowerHistory"
require "LiveWire/LW_EventBus"

LiveWire = LiveWire or {}

local Registry = {}
LiveWire.Registry = Registry

Registry.ready = false
Registry.readOnly = false

local function data()
    return Registry.data
end

function Registry.init()
    LiveWire.Events.emit(LiveWire.Events.REGISTRY_RESET)
    if LiveWire.Sim then LiveWire.Sim.subscribers = {} end
    local d = ModData.getOrCreate(LiveWire.DATA_KEY)
    d.devices = d.devices or {}
    d.grids = d.grids or {}
    d.byPos = d.byPos or {}
    d.nextId = d.nextId or 1
    Registry.readOnly = not LiveWire.Migration.run(d)
    Registry.data = d
    Registry.rebuildIndexes()
    local a = ModData.getOrCreate(LiveWire.ANCHOR_KEY)
    Registry.anchors = a
    if not Registry.readOnly then
        LiveWire.PowerHistory.init(d, a, getGameTime():getWorldAgeHours())
        Registry.dropCoupledAnchors()
    end
    Registry.ready = true
    local n = 0
    for _ in pairs(d.devices) do n = n + 1 end
    LiveWire.log("version " .. tostring(LiveWire.VERSION) .. ", registry ready: " .. tostring(n) .. " device(s)")
end

-- At load, when no add-on keeps the zones of coupled inverters (D-45), drop the anchors
-- they still hold: they were left by an add-on that has since been removed, and nothing
-- would switch them on or off anymore. The engine purges generator positions when a
-- chunk loads and Live Wire re-applies only the anchor table, so removing them here is
-- enough. Returns the number of anchors dropped.
function Registry.dropCoupledAnchors()
    if LiveWire.Coupling.slaveKeepsZone() then return 0 end
    local n = 0
    for _, dev in ipairs(Registry.devicesByRole("inverter")) do
        if dev.coupled and Registry.anchors[dev.id] ~= nil then
            Registry.setAnchor(dev, nil)
            n = n + 1
        end
    end
    if n > 0 then LiveWire.log("dropped the zone of " .. n .. " coupled inverter(s): no add-on keeps them") end
    return n
end

function Registry.newId(prefix)
    local d = data()
    local id = prefix .. tostring(d.nextId)
    d.nextId = d.nextId + 1
    return id
end

-- An id restored from an object mark (Devices.recover) must never be handed out
-- again: move the counter past it.
function Registry.reserveId(id)
    local n = tonumber(string.match(tostring(id), "^%a+(%d+)$"))
    if n and n >= data().nextId then data().nextId = n + 1 end
end

function Registry.device(id)
    return data().devices[id]
end

function Registry.grid(id)
    return data().grids[id]
end

function Registry.devices()
    return data().devices
end

function Registry.grids()
    return data().grids
end

-- Pumps disabled by the debug tool "remove every water relay". The flag is persisted
-- in the registry data under `pumpsDisabled` (true or absent); only these two functions
-- read or write it.
function Registry.pumpsDisabled()
    local d = Registry.data
    return d ~= nil and d.pumpsDisabled == true
end

function Registry.setPumpsDisabled(disabled)
    data().pumpsDisabled = disabled and true or nil
end

local function indexAdd(dev)
    local k = LiveWire.posKey(dev.x, dev.y, dev.z)
    local list = data().byPos[k] or {}
    list[#list + 1] = dev.id
    data().byPos[k] = list
    local ck = math.floor(dev.x / 8) .. "," .. math.floor(dev.y / 8)
    Registry.byChunk[ck] = Registry.byChunk[ck] or {}
    Registry.byChunk[ck][dev.id] = true
    if dev.role then
        Registry.byRole[dev.role] = Registry.byRole[dev.role] or {}
        Registry.byRole[dev.role][dev.id] = true
    end
    if dev.role == "inverter" then
        Registry.inverters[dev.id] = true
        Registry.invertersByChunk[ck] = Registry.invertersByChunk[ck] or {}
        Registry.invertersByChunk[ck][dev.id] = true
    end
end

local function indexRemove(dev)
    local ck = math.floor(dev.x / 8) .. "," .. math.floor(dev.y / 8)
    local bucket = Registry.byChunk[ck]
    if bucket then
        bucket[dev.id] = nil
        local any = false
        for _ in pairs(bucket) do any = true; break end
        if not any then Registry.byChunk[ck] = nil end
    end
    Registry.inverters[dev.id] = nil
    local roleSet = dev.role and Registry.byRole[dev.role]
    if roleSet then roleSet[dev.id] = nil end
    local inverters = Registry.invertersByChunk[ck]
    if inverters then
        inverters[dev.id] = nil
        local any = false
        for _ in pairs(inverters) do any = true; break end
        if not any then Registry.invertersByChunk[ck] = nil end
    end
    local k = LiveWire.posKey(dev.x, dev.y, dev.z)
    local list = data().byPos[k]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == dev.id then table.remove(list, i) end
    end
    if #list == 0 then data().byPos[k] = nil end
end

-- Derived session indexes, rebuilt for existing saves without a schema change.
function Registry.rebuildIndexes()
    Registry.byChunk, Registry.inverters, Registry.invertersByChunk = {}, {}, {}
    Registry.byRole = {}
    if Registry.readOnly then return end
    data().byPos = {}
    for _, dev in pairs(data().devices) do indexAdd(dev) end
end

-- A detached list: callers may validate/remove a device while iterating.
function Registry.devicesInChunk(cx, cy)
    local out = {}
    for id in pairs(Registry.byChunk[cx .. "," .. cy] or {}) do
        local dev = Registry.device(id)
        if dev then out[#out + 1] = dev end
    end
    return out
end

-- Devices of one role (in any grid or none), sorted by id for a stable order, from the
-- session role index. A detached list: callers may remove a device while iterating.
function Registry.devicesByRole(role)
    local ids = {}
    for id in pairs(Registry.byRole[role] or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    local out = {}
    for i = 1, #ids do
        local dev = data().devices[ids[i]]
        if dev then out[#out + 1] = dev end
    end
    return out
end

-- Session index lookup only: never visit map squares or distant devices. Coupled
-- inverters count only when an add-on lets them keep their zone (D-45).
function Registry.invertersNear(x, y, radius)
    local slaves = LiveWire.Coupling.slaveKeepsZone()
    local out, r2 = {}, radius * radius
    for cy = math.floor((y - radius) / 8), math.floor((y + radius) / 8) do
        for cx = math.floor((x - radius) / 8), math.floor((x + radius) / 8) do
            for id in pairs(Registry.invertersByChunk[cx .. "," .. cy] or {}) do
                local d = Registry.device(id)
                if d and d.role == "inverter" and (slaves or not d.coupled)
                    and (d.x - x)^2 + (d.y - y)^2 <= r2 then out[#out + 1] = d end
            end
        end
    end
    return out
end

function Registry.devicesAt(x, y, z)
    local list = data().byPos[LiveWire.posKey(x, y, z)]
    local out = {}
    if list then
        for i = 1, #list do
            local dev = data().devices[list[i]]
            if dev then out[#out + 1] = dev end
        end
    end
    return out
end

-- Adds a device table (must have role, model, x, y, z). Returns it with an id.
function Registry.addDevice(dev)
    if dev.id then Registry.reserveId(dev.id) else dev.id = Registry.newId("d") end
    local previous = data().devices[dev.id]
    if previous then indexRemove(previous) end
    data().devices[dev.id] = dev
    indexAdd(dev)
    return dev
end

-- Creates the network owned by a new inverter.
function Registry.createGrid(inverter)
    local g = {
        id = Registry.newId("g"), name = "", inverter = inverter.id,
        members = {}, demand = 0, powered = false,
        lastTick = getGameTime():getWorldAgeHours(), rev = 0,
    }
    data().grids[g.id] = g
    inverter.grid = g.id
    return g
end

-- Slave inverters of a grid (sorted by id), dropping ids whose device is gone.
function Registry.slaves(grid)
    local out = {}
    if not grid.slaves then return out end
    local ids = {}
    for id in pairs(grid.slaves) do ids[#ids + 1] = id end
    table.sort(ids)
    for i = 1, #ids do
        local dev = data().devices[ids[i]]
        if dev then out[#out + 1] = dev else grid.slaves[ids[i]] = nil end
    end
    return out
end

-- Couple `slave` (an inverter with its own empty grid) to `masterGrid`: its own grid
-- is removed, it joins the master's grid as a slave. Its anchor (zone) is removed
-- too, unless an add-on lets coupled inverters keep their zone (D-45).
function Registry.couple(slave, masterGrid)
    local own = slave.grid and data().grids[slave.grid]
    if own and own.id ~= masterGrid.id then data().grids[own.id] = nil end
    if not LiveWire.Coupling.slaveKeepsZone() then Registry.setAnchor(slave, nil) end
    slave.grid = masterGrid.id
    slave.coupled = masterGrid.inverter
    slave.relink = nil
    masterGrid.slaves = masterGrid.slaves or {}
    masterGrid.slaves[slave.id] = true
    LiveWire.Events.emit(LiveWire.Events.TOPOLOGY_CHANGED)
    LiveWire.Events.emit(LiveWire.Events.JOURNAL_ENTRY, masterGrid, "IGUI_LW_Coupled")
end

-- Make a slave independent again: it leaves the master's grid and gets a new empty grid.
function Registry.uncouple(slave)
    local g = slave.grid and data().grids[slave.grid]
    if g and g.slaves then g.slaves[slave.id] = nil end
    if g then LiveWire.Events.emit(LiveWire.Events.JOURNAL_ENTRY, g, "IGUI_LW_Uncoupled") end
    slave.coupled = nil
    slave.grid = nil
    slave.wires = nil
    Registry.createGrid(slave)
    LiveWire.Events.emit(LiveWire.Events.TOPOLOGY_CHANGED)
end

function Registry.link(dev, grid)
    local already = dev.grid == grid.id and grid.members[dev.id]
    if dev.grid and dev.grid ~= grid.id then Registry.unlink(dev) end
    dev.grid = grid.id
    dev.relink = nil
    grid.members[dev.id] = true
    if not already then
        LiveWire.Events.emit(LiveWire.Events.JOURNAL_ENTRY, grid, "IGUI_LW_Event_State",
            { "IGUI_LW_Model_" .. dev.model, "IGUI_LW_Event_Connected" })
    end
end

function Registry.unlink(dev)
    if dev.role == "inverter" then return end
    local g = dev.grid and data().grids[dev.grid]
    local def = LiveWire.Defs.devices[dev.model]
    if g and def and def.kind == "breaker" then
        LiveWire.Events.emit(LiveWire.Events.GRID_RELEASED, g)
    end
    if g then g.members[dev.id] = nil end
    if g then
        LiveWire.Events.emit(LiveWire.Events.JOURNAL_ENTRY, g, "IGUI_LW_Event_State",
            { "IGUI_LW_Model_" .. dev.model, "IGUI_LW_Event_Disconnected" })
    end
    dev.grid = nil
    dev.wires = nil
end

-- Visits the members of a grid in id order (a stable order), dropping the ids whose
-- device is gone.
local function eachMember(grid, fn)
    local ids = {}
    for id in pairs(grid.members) do ids[#ids + 1] = id end
    table.sort(ids)
    for i = 1, #ids do
        local id = ids[i]
        local dev = data().devices[id]
        if dev then fn(dev) else grid.members[id] = nil end
    end
end

-- Members of a grid by role: { source, storage, option, backup, computer, pump }, each
-- a list sorted by id (empty when the grid has none). Inverters are not members.
function Registry.members(grid)
    local out = { source = {}, storage = {}, option = {}, backup = {}, computer = {}, pump = {} }
    eachMember(grid, function(dev)
        local list = out[dev.role]
        if list then list[#list + 1] = dev end
    end)
    return out
end

-- Members of one role, sorted by id (an empty list when the grid has none of it).
function Registry.membersByRole(grid, role)
    local out = {}
    eachMember(grid, function(dev)
        if dev.role == role then out[#out + 1] = dev end
    end)
    return out
end

-- Vanilla objects (generator, computer) only exist in the registry through their
-- link: dropping the link removes them and clears the ModData left on the object.
function Registry.forgetVanilla(dev)
    if dev.role == "backup" and LiveWire.Backup then
        LiveWire.Backup.forget(dev)
    elseif dev.role == "computer" and LiveWire.Computer then
        LiveWire.Computer.forget(dev)
    else
        return false
    end
    return true
end

function Registry.hasOption(grid, kind)
    local options = Registry.membersByRole(grid, "option")
    for i = 1, #options do
        local def = LiveWire.Defs.devices[options[i].model]
        if def and def.kind == kind and (options[i].cond or 0) > 0 then return options[i] end
    end
    return nil
end

-- Delete a master's grid: its slaves become independent, its members are left
-- unlinked and its linked vanilla objects are forgotten. Also used for a grid whose
-- inverter vanished from the registry, whose public anchor is then removed too.
function Registry.dropGrid(g)
    LiveWire.Events.emit(LiveWire.Events.GRID_RELEASED, g, true)
    -- The slaves lose their master: each becomes an independent inverter.
    local slaves = Registry.slaves(g)
    for i = 1, #slaves do Registry.uncouple(slaves[i]) end
    local vanilla = {}
    for mid in pairs(g.members) do
        local m = data().devices[mid]
        if m then
            m.grid, m.wires = nil, nil
            if m.role == "backup" or m.role == "computer" then vanilla[#vanilla + 1] = m end
        end
    end
    data().grids[g.id] = nil
    for i = 1, #vanilla do Registry.forgetVanilla(vanilla[i]) end
    local a = g.inverter and not data().devices[g.inverter] and Registry.anchors[g.inverter]
    if a then Registry.setAnchor({ id = g.inverter, x = a.x, y = a.y, z = a.z }, nil) end
end

function Registry.removeDevice(id)
    local dev = data().devices[id]
    if not dev then return end
    if dev.role == "inverter" and dev.coupled then
        -- A slave owns no grid: it leaves its master's grid and drops the anchor it
        -- may keep (D-45).
        local g = dev.grid and data().grids[dev.grid]
        if g and g.slaves then g.slaves[id] = nil end
        Registry.setAnchor(dev, nil)
        indexRemove(dev)
        data().devices[id] = nil
        LiveWire.Events.emit(LiveWire.Events.INVERTER_REMOVED, id)
        return
    end
    if dev.role == "inverter" then
        local g = dev.grid and data().grids[dev.grid]
        if g then Registry.dropGrid(g) end
        Registry.setAnchor(dev, nil)
    else
        Registry.unlink(dev)
    end
    indexRemove(dev)
    data().devices[id] = nil
    if dev.role == "inverter" then
        LiveWire.Events.emit(LiveWire.Events.TOPOLOGY_CHANGED)
        LiveWire.Events.emit(LiveWire.Events.INVERTER_REMOVED, id)
    end
end

-- Public anchor table: anchors[inverterId] = { x, y, z, on, log, log0 } (nil removes it).
-- log: state changes { t = world age hours, on = bool }, oldest first, at most
-- ANCHOR_LOG_MAX; log0: state before log[1]. Kept for compatibility; authoritative
-- food catch-up now reads the private 60-day PowerHistory instead.
-- Returns true when the published state changed.
Registry.ANCHOR_LOG_MAX = 16

function Registry.setAnchor(inverter, on)
    local a = Registry.anchors
    local cur = a[inverter.id]
    if on ~= nil or cur then
        LiveWire.PowerHistory.record(data(), inverter, on, getGameTime():getWorldAgeHours())
    end
    if on == nil then
        if cur == nil then return false end
        a[inverter.id] = nil
    else
        if cur and cur.on == on and cur.x == inverter.x and cur.y == inverter.y
            and cur.z == inverter.z then
            return false
        end
        local log, log0 = {}, false
        if cur then
            if type(cur.log) == "table" then
                log = cur.log
                log0 = cur.log0 == true
            else
                log0 = cur.on == true  -- anchor saved before the log existed
            end
        end
        if not cur or cur.on ~= on then
            log[#log + 1] = { t = getGameTime():getWorldAgeHours(), on = on }
            while #log > Registry.ANCHOR_LOG_MAX do
                log0 = log[1].on == true
                table.remove(log, 1)
            end
            LiveWire.log("anchor " .. tostring(inverter.id) .. " " .. (on and "on" or "off"))
        end
        a[inverter.id] = { x = inverter.x, y = inverter.y, z = inverter.z, on = on,
                           log = log, log0 = log0 }
    end
    if isServer() then ModData.transmit(LiveWire.ANCHOR_KEY) end
    return true
end

Events.OnInitGlobalModData.Add(function(isNewGame)
    Registry.init()
end)
