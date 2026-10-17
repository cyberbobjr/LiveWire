-- Live Wire: placed devices enter and leave the registry (authority only).
-- Called by the vanilla furniture wrappers of LW_Placement.lua: a device is
-- registered when its tile is placed and removed when it is picked up. A rotation
-- (pick up then place on the same square) keeps the same device and its links.
-- Devices destroyed by other means (zombies, sledgehammer) are dropped when their
-- square is loaded and the object is gone (Devices.validate).
if isClient() then return end

LiveWire = LiveWire or {}

local Devices = {}
LiveWire.Devices = Devices

local function R() return LiveWire.Registry end

Devices.rotating = false
Devices.pending = {}   -- ids picked up during a rotation, waiting for the new tile

local function ready()
    local Rg = R()
    return Rg and Rg.ready and not Rg.readOnly
end

-- Our object of sprite `spriteName` on `sq` that is not bound to a live device.
local function unboundObject(sq, spriteName)
    local objs = sq:getObjects()
    for i = objs:size() - 1, 0, -1 do
        local o = objs:get(i)
        local spr = o:getSprite()
        if spr and spr:getName() == spriteName then
            local m = LiveWire.Marks.get(o)
            local dev = m and R().device(m.id)
            if not dev or Devices.pending[m.id] or dev.x ~= sq:getX() or dev.y ~= sq:getY()
                or dev.z ~= sq:getZ() then
                return o, m
            end
        end
    end
    return nil
end

-- Inverter id of the network a device is linked to (an inverter: its own id).
local function inverterOf(dev)
    if dev.role == "inverter" then return dev.id end
    local g = dev.grid and R().grid(dev.grid)
    return g and g.inverter or nil
end

-- State shown by the client: st (inverter: on/off/tripped/broken; breaker:
-- ok/tripped; alarm: ok/ringing), pw (inverter: the house is powered).
local function stateOf(dev)
    local g = dev.grid and R().grid(dev.grid)
    if dev.role == "inverter" then
        return dev.state or "off", (g and g.powered == true and dev.state == "on") or false
    end
    local def = LiveWire.Defs.devices[dev.model]
    if def and def.kind == "alarm" then
        if g and g.alarmOn and (dev.cond or 0) > 0 then return "ringing", false end
        return "ok", false
    end
    return dev.state or "ok", false
end

local function markFromDevice(obj, dev)
    local st, pw = stateOf(dev)
    LiveWire.Marks.set(obj, { id = dev.id, model = dev.model, cond = dev.cond, eff = dev.eff,
                              level = dev.level, inv = inverterOf(dev), st = st, pw = pw,
                              muf = dev.muffled == true or nil })
    dev.shownSt, dev.shownPw, dev.shownInv = st, pw, inverterOf(dev)
    if isServer() then obj:transmitModData() end
end

-- Rewrite the mark of a loaded device (link state shown by the client menus).
function Devices.syncMark(dev)
    if not dev then return end
    local sq = getCell():getGridSquare(dev.x, dev.y, dev.z)
    local obj = sq and LiveWire.Marks.findOnSquare(sq, dev.id)
    if obj then markFromDevice(obj, dev) end
end

-- Rewrite the marks of the inverter and the equipment of a grid whose shown state
-- changed (called after each simulation step).
function Devices.refreshStates(grid)
    local list = { R().device(grid.inverter) }
    local _, _, options = R().members(grid)
    for i = 1, #options do list[#list + 1] = options[i] end
    for i = 1, #list do
        local dev = list[i]
        if dev then
            local st, pw = stateOf(dev)
            if st ~= dev.shownSt or pw ~= dev.shownPw or inverterOf(dev) ~= dev.shownInv then
                Devices.syncMark(dev)
            end
        end
    end
end

function Devices.onPlaced(character, sq, spriteName)
    if not ready() then return end
    local model = LiveWire.Defs.spriteToModel[spriteName]
    local def = model and LiveWire.Defs.devices[model]
    if not def then return end
    local obj, mark = unboundObject(sq, spriteName)
    if not obj then return end

    -- Rotation: same device, same square, new object.
    if mark and Devices.pending[mark.id] then
        local dev = R().device(mark.id)
        Devices.pending[mark.id] = nil
        if dev then
            markFromDevice(obj, dev)
            return
        end
    end

    local raw = LiveWire.Marks.raw(obj) or {}
    local level = character and LiveWire.Install.level(character) or 0
    local dev = R().addDevice({
        role = def.role, model = model, x = sq:getX(), y = sq:getY(), z = sq:getZ(),
        cond = tonumber(raw.cond) or 100, eff = LiveWire.Defs.installEfficiency(level), level = level,
        state = (def.role == "inverter") and "on" or "ok",
    })
    if def.role == "inverter" and raw.muf == true then dev.muffled = true end
    if def.role == "storage" then
        dev.wearFactor = LiveWire.Defs.batteryWearSkillFactor(level)
        dev.slots = {}
    end
    markFromDevice(obj, dev)
    if def.role == "inverter" then
        local grid = R().createGrid(dev)
        LiveWire.Sim.updateAnchor(dev, false)
        LiveWire.Sim.refresh(grid)
    end
    if character then
        LiveWire.Xp.award(character, def.xp or 0)
        LiveWire.notify(character, "IGUI_LW_Installed", { "IGUI_LW_Model_" .. model })
    end
    LiveWire.log("placed " .. model .. " " .. dev.id .. " at " .. LiveWire.posKey(dev.x, dev.y, dev.z))
end

-- Write the live state into the object's mark so that the picked-up item keeps it.
function Devices.beforePickUp(obj)
    if not ready() then return nil end
    local m = LiveWire.Marks.get(obj)
    local dev = m and R().device(m.id)
    if not dev then return nil end
    markFromDevice(obj, dev)
    return dev.id
end

-- Remove a device from the registry (picked up or destroyed).
function Devices.remove(id)
    local dev = R().device(id)
    if not dev then return end
    if dev.role == "inverter" then
        LiveWire.Sim.updateAnchor(dev, false)
        LiveWire.Anchor.set(dev.id, R().anchors[dev.id] or dev, false)
    end
    local grid = dev.grid and R().grid(dev.grid)
    local members = {}
    if dev.role == "inverter" and grid then
        for mid in pairs(grid.members) do members[#members + 1] = mid end
    end
    R().removeDevice(dev.id)
    LiveWire.Demand.invalidate(dev.id)
    for i = 1, #members do Devices.syncMark(R().device(members[i])) end
    if grid and R().grid(grid.id) then LiveWire.Sim.refresh(grid) end
    LiveWire.log("removed " .. tostring(dev.model) .. " " .. id)
end

function Devices.onPickedUp(id)
    if not ready() then return end
    if Devices.rotating then
        Devices.pending[id] = true
        return
    end
    Devices.remove(id)
end

function Devices.beginRotation()
    Devices.rotating = true
    Devices.pending = {}
end

function Devices.endRotation()
    Devices.rotating = false
    local left = Devices.pending
    Devices.pending = {}
    if not ready() then return end
    for id in pairs(left) do Devices.remove(id) end
end

-- Drop the devices of a loaded square whose object is gone.
function Devices.validate(dev)
    local sq = getCell():getGridSquare(dev.x, dev.y, dev.z)
    if not sq then return true end
    if LiveWire.Marks.findOnSquare(sq, dev.id) then return true end
    LiveWire.warn("device " .. dev.id .. " (" .. tostring(dev.model) .. ") is gone, removing it")
    Devices.remove(dev.id)
    return false
end
