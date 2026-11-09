-- Live Wire: placed devices enter and leave the registry (authority only).
-- Called by the vanilla furniture wrappers of LW_Placement.lua: a device is
-- registered when its tile is placed and removed when it is picked up. A rotation
-- (pick up then place on the same square) keeps the same device and its links.
-- Devices destroyed by other means (zombies, sledgehammer) are dropped when their
-- square is loaded and the object is gone (Devices.validate).
if isClient() then return end
require "LiveWire/LW_Circuits"
require "LiveWire/LW_EventBus"

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

-- Inverter id of the network a device is linked to (an inverter: its own id, a slave:
-- the master's id).
local function inverterOf(dev)
    if dev.role == "inverter" then return dev.coupled or dev.id end
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
    if dev.role == "pump" then
        local inv = g and R().device(g.inverter)
        local powered = g and g.powered == true and not g.mainOff and not g.equipmentOff
            and (dev.cond or 0) > 0 and inv and inv.state == "on" and (inv.cond or 0) > 0
            and not (LiveWire.Pump and LiveWire.Pump.disabled())
        return dev.state or "idle", powered == true
    end
    local def = LiveWire.Defs.devices[dev.model]
    if def and def.kind == "breaker" then
        local inv = g and R().device(g.inverter)
        local powered = g and g.powered == true and not g.mainOff
            and dev.state ~= "tripped" and (dev.cond or 0) > 0
            and inv and inv.state == "on" and (inv.cond or 0) > 0
        return dev.state or "ok", powered == true
    end
    if def and def.kind == "alarm" then
        if g and g.alarmOn and (dev.cond or 0) > 0 then return "ringing", false end
        return "ok", false
    end
    return dev.state or "ok", false
end

local function placementFacts(obj, dev)
    local def = LiveWire.Defs.devices[dev.model]
    if def and LiveWire.Defs.ORIENTED_KINDS[def.kind] then
        local name = obj:getSprite():getName()
        dev.facing = (tonumber(string.match(name, "_(%d+)$")) - def.tile) % 4
    end
    if dev.role == "storage" then dev.outside = obj:getSquare():isOutside() end
end

-- An inverter is in service once a first device was linked to it (or, in older
-- saves, while it has equipment or slaves). Linking to an inverter that is not in
-- service needs the inverter's own Electrical level (Install.checkLink).
local function inService(dev)
    if dev.role ~= "inverter" then return nil end
    if dev.svc or dev.coupled then return true end
    local g = dev.grid and R().grid(dev.grid)
    if not g then return nil end
    for _ in pairs(g.members) do return true end
    for _ in pairs(g.slaves or {}) do return true end
    return nil
end

-- Fields of the mark: written by markFromDevice and compared by Devices.find, from
-- this one list, so a field that is written is always a field that is compared.
local MARK_FIELDS = { "id", "model", "cond", "eff", "level", "inv", "st", "pw", "muf",
                      "x", "y", "z", "nb", "nr", "cpl", "nm",
                      "facing", "svc", "xpd" }
-- The fields of the mark that belong to a source kind come from Defs.SOURCE_FIELDS (D-50).

-- Mark content of a device (placementFacts must have run: the facing comes from it).
local function buildMark(dev)
    local st, pw = stateOf(dev)
    local g = dev.grid and R().grid(dev.grid)
    -- Pumps: number of linked barrels (connect menu limit) and of relay tanks (shown
    -- as "nr" by the tap view).
    local nb, nr = nil, nil
    if dev.role == "pump" then
        nb, nr = 0, 0
        for _ in pairs(dev.barrels or {}) do nb = nb + 1 end
        for _ in pairs(dev.relays or {}) do nr = nr + 1 end
    end
    local m = { id = dev.id, model = dev.model, cond = dev.cond, eff = dev.eff,
             level = dev.level, inv = inverterOf(dev), st = st, pw = pw,
             muf = dev.muffled == true or nil, x = dev.x, y = dev.y, z = dev.z,
             nb = nb, nr = nr, cpl = dev.coupled,
             nm = g and g.name or nil,
             facing = dev.facing, svc = inService(dev),
             xpd = dev.xpd == true or nil }
    local def = LiveWire.Defs.devices[dev.model]
    for _, f in ipairs(LiveWire.Defs.SOURCE_FIELDS[def and def.kind] or {}) do
        if f.flag then m[f.mark] = dev[f.field] == true else m[f.mark] = dev[f.field] end
    end
    return m
end

-- Does the mark `m` (nil: none) differ from the fresh content `fresh` on any field?
local function markDiffers(m, fresh)
    if not m then return true end
    for i = 1, #MARK_FIELDS do
        local name = MARK_FIELDS[i]
        if m[name] ~= fresh[name] then return true end
    end
    for _, fields in pairs(LiveWire.Defs.SOURCE_FIELDS) do
        for _, f in ipairs(fields) do
            -- A flag that is off is false or absent alike (marks written before D-50 carry false).
            if m[f.mark] ~= fresh[f.mark] and not (f.flag and not m[f.mark] and not fresh[f.mark]) then
                return true
            end
        end
    end
    return false
end

local function markFromDevice(obj, dev)
    placementFacts(obj, dev)
    local fresh = buildMark(dev)
    LiveWire.Marks.set(obj, fresh)
    dev.shownSt, dev.shownPw, dev.shownInv = fresh.st, fresh.pw, fresh.inv
    if isServer() then obj:transmitModData() end
end

-- Registry identity and the physical tile win over a missing/altered object mark.
-- Do not attach a registry device to an unrelated vanilla object carrying its id.
function Devices.find(dev)
    local sq = getCell():getGridSquare(dev.x, dev.y, dev.z)
    if not sq then return nil end
    local obj = LiveWire.Marks.findOnSquare(sq, dev.id)
    if obj and LiveWire.Defs.modelOfObject(obj) ~= dev.model then obj = nil end
    if not obj then
        local objects = sq:getObjects()
        for i = 0, objects:size() - 1 do
            local candidate = objects:get(i)
            if LiveWire.Defs.modelOfObject(candidate) == dev.model then
                local mark = LiveWire.Marks.get(candidate)
                local bound = mark and R().device(mark.id)
                if not bound or bound.x ~= dev.x or bound.y ~= dev.y or bound.z ~= dev.z
                    or bound.model ~= dev.model then obj = candidate; break end
            end
        end
    end
    if obj then
        -- Old saves have no facing field. Read the physical tile even when wear
        -- is disabled and no other mark field changes; never assume south.
        placementFacts(obj, dev)
        if markDiffers(LiveWire.Marks.get(obj), buildMark(dev)) then
            markFromDevice(obj, dev)
        end
    end
    return obj
end

-- Rewrite the mark of a loaded device (link state shown by the client menus).
function Devices.syncMark(dev)
    if not dev then return end
    local obj = Devices.find(dev)
    if obj then markFromDevice(obj, dev) end
end

-- Rewrite the marks of the inverter and the equipment of a grid whose shown state
-- changed (called after each simulation step).
function Devices.refreshStates(grid)
    local list = { R().device(grid.inverter) }
    local slaves = R().slaves(grid)
    for i = 1, #slaves do list[#list + 1] = slaves[i] end
    local members = R().members(grid)
    local options, pumps = members.option, members.pump
    for i = 1, #options do list[#list + 1] = options[i] end
    for i = 1, #pumps do list[#list + 1] = pumps[i] end
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

-- Registry entry for a device standing on `sq`, from the state its object carries
-- (`raw`: the mark kept by a picked-up kit, or the mark of an orphan object).
-- `level`: installer level; `id`: kept id or nil for a new one.
local function newDevice(sq, model, def, raw, level, id)
    local dev = R().addDevice({
        id = id, role = def.role, model = model, x = sq:getX(), y = sq:getY(), z = sq:getZ(),
        cond = tonumber(raw.cond) or 100,
        eff = LiveWire.Defs.installEfficiency(level), level = level,
        state = (def.role == "inverter") and "on" or "ok",
        xpd = raw.xpd == true,
    })
    if def.role == "inverter" and raw.muf == true then dev.muffled = true end
    for _, f in ipairs(LiveWire.Defs.SOURCE_FIELDS[def.kind] or {}) do
        if not f.flag then
            dev[f.field] = raw[f.mark] or f.default
        elseif raw[f.mark] == true then
            dev[f.field] = true
        end
    end
    if def.role == "storage" then
        dev.wearFactor = LiveWire.Defs.batteryWearSkillFactor(level)
        dev.slots = {}
    end
    if def.role == "pump" then
        dev.barrels = {}
        dev.relays = {}
        dev.state = "idle"
    end
    return dev
end

-- Register the unbound object of sprite `spriteName` on `sq` (or keep the same
-- device after a rotation). `adopted`: reported later by a client (C_ADOPT) instead
-- of the placement wrapper, e.g. another mod replaced placeMoveableInternal: no
-- experience, its own message. Returns the device or nil.
local function register(character, sq, spriteName, adopted)
    local where = LiveWire.posKey(sq:getX(), sq:getY(), sq:getZ())
    if not ready() then
        LiveWire.warn("cannot register " .. tostring(spriteName) .. " at " .. where
            .. ": the registry is not ready or read-only")
        if character and not adopted then LiveWire.notify(character, "IGUI_LW_NotRegistered", {}, true) end
        return nil
    end
    local model = LiveWire.Defs.spriteToModel[spriteName]
    local def = model and LiveWire.Defs.devices[model]
    if not def then return nil end
    -- Repair before looking for an unbound tile, otherwise a client report could
    -- create a second registry entry for an existing device whose mark was lost.
    local existing = R().devicesAt(sq:getX(), sq:getY(), sq:getZ())
    for i = 1, #existing do
        if existing[i].model == model and not Devices.pending[existing[i].id] then
            Devices.find(existing[i])
        end
    end
    local obj, mark = unboundObject(sq, spriteName)
    if not obj then
        if not adopted then
            LiveWire.warn("placed " .. tostring(spriteName) .. " at " .. where
                .. " but no unregistered object of that tile is on the square")
        end
        return nil
    end

    -- Rotation: same device, same square, new object.
    if mark and Devices.pending[mark.id] then
        local dev = R().device(mark.id)
        Devices.pending[mark.id] = nil
        if dev then
            markFromDevice(obj, dev)
            return dev
        end
    end

    -- Placing is free: efficiency, installer level and experience come with the
    -- first link (Devices.wired). `xpd = false` marks a device whose link
    -- experience is still due; the mark keeps `xpd = true` once given, so a moved
    -- device does not give it again. Registry devices of older saves have no xpd
    -- field: their experience was given at placement.
    local dev = newDevice(sq, model, def, LiveWire.Marks.raw(obj) or {}, 0, nil)
    markFromDevice(obj, dev)
    if def.role == "inverter" then
        local grid = R().createGrid(dev)
        LiveWire.Sim.updateAnchor(dev, false)
        LiveWire.Sim.refresh(grid)
    end
    if character then
        if adopted then
            LiveWire.notify(character, "IGUI_LW_Adopted", { "IGUI_LW_Model_" .. model })
        else
            LiveWire.notify(character, "IGUI_LW_Installed", { "IGUI_LW_Model_" .. model })
        end
    end
    LiveWire.log((adopted and "adopted " or "placed ") .. model .. " " .. dev.id .. " at " .. where)
    return dev
end

-- `character` linked `dev` (nil for a vanilla generator or computer) to the
-- inverter `inv`: both keep the best installer level seen (efficiency, wear) and
-- the inverter is in service. Returns the experience due, given once per device.
function Devices.wired(character, dev, inv)
    local level = LiveWire.Install.level(character)
    local xp = 0
    for _, d in ipairs({ dev or false, inv or false }) do
        if d then
            if level > (d.level or 0) then
                d.level = level
                d.eff = math.max(d.eff or 0, LiveWire.Defs.installEfficiency(level))
                if d.role == "storage" then
                    d.wearFactor = math.min(d.wearFactor or 1, LiveWire.Defs.batteryWearSkillFactor(level))
                end
            end
            if d.xpd == false then
                d.xpd = true
                local def = LiveWire.Defs.devices[d.model]
                xp = xp + (def and def.xp or 0)
            end
        end
    end
    if inv then inv.svc = true end
    return xp
end

function Devices.onPlaced(character, sq, spriteName)
    return register(character, sq, spriteName, false)
end

-- Register every unbound Live Wire tile of a loaded square (client report).
function Devices.adoptSquare(character, sq)
    local names = {}
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local spr = objs:get(i):getSprite()
        local name = spr and spr:getName()
        if name and LiveWire.Defs.spriteToModel[name] then names[#names + 1] = name end
    end
    local n = 0
    for i = 1, #names do
        if register(character, sq, names[i], true) then n = n + 1 end
    end
    return n
end

--------------------------------------------------------------------------------
-- Orphan recovery. An object may carry a mark whose id the registry does not know:
-- the map chunk was saved after the global ModData (crash, forced quit, restored
-- backup). Every command on it is then refused and its screens wait forever, and
-- the client never reports it (LW_Adopt only sees objects without a mark). The
-- chunk discovery walk (LW_Circuits) shows each loaded object to Devices.recover,
-- which registers it again from its mark: the same id when it is free, its state,
-- and its link to the inverter named in the mark once that inverter is known
-- (dev.relink, kept in the registry until then).
--------------------------------------------------------------------------------
local INVERTER_STATES = { on = true, off = true, tripped = true, broken = true }

-- Inverter named by dev.relink and its grid, when it may take `dev` by the cable rules.
local function relinkTarget(dev)
    local inv = dev.relink and R().device(dev.relink)
    if not inv or inv.role ~= "inverter" or inv.coupled or inv.id == dev.id then return nil end
    local dist, dz = LiveWire.Install.distance(dev.x, dev.y, dev.z, inv.x, inv.y, inv.z)
    if dist > LiveWire.Config.get("LinkRange") or dz > LiveWire.Config.get("LinkVerticalRange") then
        return nil
    end
    local grid = inv.grid and R().grid(inv.grid)
    if not grid then return nil end
    return inv, grid
end

-- Restore the link a recovered device had. Returns true when linked or coupled.
local function relink(dev)
    local inv, grid = relinkTarget(dev)
    if not inv then
        -- Unknown yet: keep waiting. Known but unable to take it: give up.
        if dev.relink and R().device(dev.relink) then dev.relink = nil end
        return false
    end
    if dev.role == "inverter" then
        local own = dev.grid and R().grid(dev.grid)
        if (own and (next(own.members) ~= nil or next(own.slaves or {}) ~= nil))
            or #R().slaves(grid) >= LiveWire.Defs.MAX_SLAVES then
            dev.relink = nil
            return false
        end
        LiveWire.Sim.updateAnchor(dev, false)
        LiveWire.Anchor.set(dev.id, R().anchors[dev.id] or dev, false)
        LiveWire.Demand.invalidate(dev.id)
        R().couple(dev, grid)
    else
        local def = LiveWire.Defs.devices[dev.model]
        local existing = def and def.role == "option" and def.kind and R().hasOption(grid, def.kind)
        if existing and existing.id ~= dev.id then
            dev.relink = nil
            return false
        end
        R().link(dev, grid)
        if dev.role == "pump" and LiveWire.Pump then LiveWire.Pump.maintain(dev) end
    end
    Devices.syncMark(dev)
    Devices.syncMark(inv)
    LiveWire.Sim.refresh(grid)
    LiveWire.log("relinked " .. tostring(dev.model) .. " " .. dev.id .. " to " .. inv.id)
    return true
end

-- Register again the object `obj` when its mark names a device the registry does
-- not hold at its square. Returns the recovered device or nil.
function Devices.recover(obj)
    if not ready() or Devices.rotating then return nil end
    local model = LiveWire.Defs.modelOfObject(obj)
    local def = model and LiveWire.Defs.devices[model]
    local m = def and LiveWire.Marks.get(obj)
    local sq = m and obj:getSquare()
    if not sq or m.model ~= model or Devices.pending[m.id] then return nil end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    -- A mark written for another square belongs to the client adoption (LW_Adopt).
    if m.x ~= nil and (m.x ~= x or m.y ~= y or m.z ~= z) then return nil end
    local bound = R().device(m.id)
    if bound and bound.x == x and bound.y == y and bound.z == z and bound.model == model then return nil end
    -- A registry device of this model on the square whose own mark was lost wins.
    local here = R().devicesAt(x, y, z)
    for i = 1, #here do
        if here[i].model == model and not Devices.pending[here[i].id] and Devices.find(here[i]) == obj then
            return nil
        end
    end
    local level = math.max(0, math.floor(tonumber(m.level) or 0))
    local dev = newDevice(sq, model, def, m, level, (not bound) and m.id or nil)
    dev.eff = tonumber(m.eff) or dev.eff
    local grid = nil
    if def.role == "inverter" then
        if INVERTER_STATES[m.st] then dev.state = m.st end
        dev.svc = m.svc == true or nil
        grid = R().createGrid(dev)
        if type(m.nm) == "string" then grid.name = LiveWire.Protocol.cleanName(m.nm) end
        dev.relink = m.cpl
    else
        if def.kind == "breaker" and m.st == "tripped" then dev.state = "tripped" end
        dev.relink = m.inv
    end
    markFromDevice(obj, dev)
    LiveWire.log("recovered " .. model .. " " .. dev.id .. " at " .. LiveWire.posKey(x, y, z)
        .. (bound and (" (its id " .. m.id .. " is taken)") or ""))
    if grid then LiveWire.Sim.updateAnchor(dev, false) end
    local linked = relink(dev)
    if grid and not linked then
        LiveWire.Sim.refresh(grid)
        -- An inverter brings back the equipment that waited for it.
        local waiting = {}
        for _, other in pairs(R().devices()) do
            if other.relink == dev.id then waiting[#waiting + 1] = other end
        end
        for i = 1, #waiting do relink(waiting[i]) end
    end
    return dev
end

--------------------------------------------------------------------------------
-- Electric wire of a link: spent when linking or coupling, given back when a
-- player undoes the link (unlink, uncouple, pick-up), lost when it is destroyed.
--------------------------------------------------------------------------------

-- Wire spent on the link of `dev` (a member: its cable to the inverter; a slave:
-- its coupling cable). Links made before the wire was recorded, or restored by
-- Devices.recover, use the cable rule on the distance.
function Devices.linkWires(dev)
    if not dev or not dev.grid then return 0 end
    if dev.role == "inverter" and not dev.coupled then return 0 end
    if type(dev.wires) == "number" then return math.max(0, math.floor(dev.wires)) end
    local g = R().grid(dev.grid)
    local inv = g and R().device(g.inverter)
    if not inv or inv.id == dev.id then return 0 end
    return LiveWire.Install.wiresFor((LiveWire.Install.distance(dev.x, dev.y, dev.z, inv.x, inv.y, inv.z)))
end

-- Wire of every link that removing `dev` undoes (an inverter: its whole network).
function Devices.removalWires(dev)
    if not dev then return 0 end
    if dev.role ~= "inverter" or dev.coupled then return Devices.linkWires(dev) end
    local grid = dev.grid and R().grid(dev.grid)
    if not grid then return 0 end
    local n = 0
    for mid in pairs(grid.members) do n = n + Devices.linkWires(R().device(mid)) end
    local slaves = R().slaves(grid)
    for i = 1, #slaves do n = n + Devices.linkWires(slaves[i]) end
    return n
end

-- Give `n` electric wires back to `character`, with a message. Returns the number given.
function Devices.returnWires(character, n)
    if not character or not n or n <= 0 then return 0 end
    local given = LiveWire.Install.giveItems(character, "Base.ElectricWire", n)
    if given > 0 then LiveWire.notify(character, "IGUI_LW_WiresBack", { tostring(given) }) end
    return given
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

-- Remove a device from the registry (picked up or destroyed). `character`: the
-- player who picked it up, who gets back the wire of the links it undoes.
function Devices.remove(id, character)
    local dev = R().device(id)
    if not dev then return end
    local wires = character and Devices.removalWires(dev) or 0
    -- A slave has no anchor of its own unless an add-on keeps its zone (D-45).
    if dev.role == "inverter" and (not dev.coupled or LiveWire.Coupling.slaveKeepsZone()) then
        LiveWire.Sim.updateAnchor(dev, false)
        LiveWire.Anchor.set(dev.id, R().anchors[dev.id] or dev, false)
    end
    local grid = dev.grid and R().grid(dev.grid)
    local members = {}
    local slaves = {}
    if dev.role == "inverter" and grid then
        for mid in pairs(grid.members) do members[#members + 1] = mid end
        -- Only a master uncouples its slaves (a removed slave owns no grid).
        if not dev.coupled then slaves = R().slaves(grid) end
    end
    if dev.role == "pump" and LiveWire.Pump then LiveWire.Pump.forget(dev) end
    R().removeDevice(dev.id)
    LiveWire.Demand.invalidate(dev.id)
    for i = 1, #members do Devices.syncMark(R().device(members[i])) end
    -- A removed master uncouples its slaves: each one gets its own empty grid.
    for i = 1, #slaves do
        Devices.syncMark(slaves[i])
        local g = slaves[i].grid and R().grid(slaves[i].grid)
        if g then LiveWire.Sim.refresh(g) end
    end
    if grid and R().grid(grid.id) then LiveWire.Sim.refresh(grid) end
    LiveWire.log("removed " .. tostring(dev.model) .. " " .. id)
    Devices.returnWires(character, wires)
end

function Devices.onPickedUp(id, character)
    if not ready() then return end
    if Devices.rotating then
        Devices.pending[id] = true
        return
    end
    Devices.remove(id, character)
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

-- Drop the devices of a loaded square whose object is gone, after MISSING_CHECKS
-- consecutive checks (chunk load, then each simulation tick): one transient miss
-- never deletes a device and its links. Every removal goes through Devices.remove.
-- Returns true when the object is present or its square is not loaded.
Devices.MISSING_CHECKS = 2
function Devices.validate(dev)
    local sq = getCell():getGridSquare(dev.x, dev.y, dev.z)
    if not sq then return true end
    if Devices.find(dev) then
        dev.missing = nil
        return true
    end
    dev.missing = (dev.missing or 0) + 1
    if dev.missing < Devices.MISSING_CHECKS then return false end
    LiveWire.warn("device " .. dev.id .. " (" .. tostring(dev.model) .. ") is gone, removing it")
    Devices.remove(dev.id)
    return false
end

-- Orphan objects are found by the chunk discovery walk (LW_Circuits.lua).
LiveWire.Circuits.addChunkVisitor(Devices.recover)

-- Told by the placement wrappers, on the authority only (LW_EventBus.lua).
LiveWire.Events.on(LiveWire.Events.DEVICE_PLACED, function(character, sq, spriteName)
    return LiveWire.Devices.onPlaced(character, sq, spriteName)
end)
LiveWire.Events.on(LiveWire.Events.DEVICE_PICKED_UP, function(id, character)
    return LiveWire.Devices.onPickedUp(id, character)
end)
LiveWire.Events.on(LiveWire.Events.ROTATION_STARTED, function() return LiveWire.Devices.beginRotation() end)
LiveWire.Events.on(LiveWire.Events.ROTATION_ENDED, function() return LiveWire.Devices.endRotation() end)
