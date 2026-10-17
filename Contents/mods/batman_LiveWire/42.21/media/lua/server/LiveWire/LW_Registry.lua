-- Live Wire: authoritative registry of devices and networks (authority only).
-- Stored in the global ModData "LiveWire" (saved in global_mod_data.bin). Never
-- transmitted: clients receive snapshots and the public anchor table only.
if isClient() then return end

LiveWire = LiveWire or {}

local Registry = {}
LiveWire.Registry = Registry

Registry.ready = false
Registry.readOnly = false

local function data()
    return Registry.data
end

function Registry.init()
    local d = ModData.getOrCreate(LiveWire.DATA_KEY)
    d.devices = d.devices or {}
    d.grids = d.grids or {}
    d.byPos = d.byPos or {}
    d.nextId = d.nextId or 1
    Registry.readOnly = not LiveWire.Migration.run(d)
    Registry.data = d
    local a = ModData.getOrCreate(LiveWire.ANCHOR_KEY)
    Registry.anchors = a
    Registry.ready = true
    local n = 0
    for _ in pairs(d.devices) do n = n + 1 end
    LiveWire.log("registry ready: " .. tostring(n) .. " device(s)")
end

function Registry.newId(prefix)
    local d = data()
    local id = prefix .. tostring(d.nextId)
    d.nextId = d.nextId + 1
    return id
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

local function indexAdd(dev)
    local k = LiveWire.posKey(dev.x, dev.y, dev.z)
    local list = data().byPos[k] or {}
    list[#list + 1] = dev.id
    data().byPos[k] = list
end

local function indexRemove(dev)
    local k = LiveWire.posKey(dev.x, dev.y, dev.z)
    local list = data().byPos[k]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == dev.id then table.remove(list, i) end
    end
    if #list == 0 then data().byPos[k] = nil end
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
    dev.id = dev.id or Registry.newId("d")
    data().devices[dev.id] = dev
    indexAdd(dev)
    return dev
end

function Registry.moveDevice(dev, x, y, z)
    indexRemove(dev)
    dev.x, dev.y, dev.z = x, y, z
    indexAdd(dev)
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

function Registry.link(dev, grid)
    if dev.grid and dev.grid ~= grid.id then Registry.unlink(dev) end
    dev.grid = grid.id
    grid.members[dev.id] = true
end

function Registry.unlink(dev)
    if dev.role == "inverter" then return end
    local g = dev.grid and data().grids[dev.grid]
    if g then g.members[dev.id] = nil end
    dev.grid = nil
end

-- Members of a grid by role: sources, batteries, options (each a list).
function Registry.members(grid)
    local sources, batteries, options = {}, {}, {}
    for id in pairs(grid.members) do
        local dev = data().devices[id]
        if not dev then
            grid.members[id] = nil
        elseif dev.role == "source" then sources[#sources + 1] = dev
        elseif dev.role == "battery" then batteries[#batteries + 1] = dev
        elseif dev.role == "option" then options[#options + 1] = dev
        end
    end
    return sources, batteries, options
end

function Registry.hasOption(grid, kind)
    local _, _, options = Registry.members(grid)
    for i = 1, #options do
        local def = LiveWire.Defs.devices[options[i].model]
        if def and def.kind == kind and (options[i].cond or 0) > 0 then return options[i] end
    end
    return nil
end

function Registry.removeDevice(id)
    local dev = data().devices[id]
    if not dev then return end
    if dev.role == "inverter" then
        local g = dev.grid and data().grids[dev.grid]
        if g then
            for mid in pairs(g.members) do
                local m = data().devices[mid]
                if m then m.grid = nil end
            end
            data().grids[g.id] = nil
        end
        Registry.setAnchor(dev, nil)
    else
        Registry.unlink(dev)
    end
    indexRemove(dev)
    data().devices[id] = nil
end

-- Public anchor table: anchors[inverterId] = { x, y, z, on } (nil removes it).
-- Returns true when the published state changed.
function Registry.setAnchor(inverter, on)
    local a = Registry.anchors
    local cur = a[inverter.id]
    if on == nil then
        if cur == nil then return false end
        a[inverter.id] = nil
    else
        if cur and cur.on == on and cur.x == inverter.x and cur.y == inverter.y
            and cur.z == inverter.z then
            return false
        end
        a[inverter.id] = { x = inverter.x, y = inverter.y, z = inverter.z, on = on }
    end
    if isServer() then ModData.transmit(LiveWire.ANCHOR_KEY) end
    return true
end

Events.OnInitGlobalModData.Add(function(isNewGame)
    Registry.init()
end)
