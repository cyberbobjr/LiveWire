if isClient() then return end
-- LiveWire Extended: power terminals on the authority (D-34). A terminal is a placed
-- object of this sub-mod (tiles batman_livewireext_01_0..3), linked to an inverter by
-- Live Wire's cable rules (LinkRange, LinkVerticalRange, WirePerTiles) and recorded
-- in this sub-mod's ModData only: Live Wire's registry gets no new role.
--   terminals["x,y,z"] = { x, y, z, inv = inverterId }
--   its zone: inverters[inv].areas["t:x,y,z"] = LWX_Zone area
require "LiveWireExtended/LWX_Connect"
require "LiveWireExtended/LWX_Zone"
require "LiveWireExtended/LWX_Terminal"

local X = LiveWire.Extended
local D, C, T = X.Data, X.Connect, X.Terminal
local S = {}
X.Terminals = S

function S.zoneKey(key) return "t:" .. key end

local function salt(id)
    local n = 0
    for i = 1, #tostring(id) do n = n + string.byte(tostring(id), i) end
    return n
end

local function exists(x, y, z) return getCell():getGridSquare(x, y, z) ~= nil end

-- Zone area for the terminal record `t` and chunk rectangle `rect`.
function S.zoneArea(t, rect)
    local area = X.Zone.compute(rect, t.x, t.y, t.z, { V = LiveWire.Config.verticalRange(),
        salt = salt(t.inv), exists = exists })
    if area then area.terminal = T.key(t.x, t.y, t.z) end
    return area
end

-- Link terminal object `obj` to the inverter object `invObj`. Returns true when linked.
function S.link(character, obj, invObj)
    local ok, why, arg1, arg2 = T.checkLink(character, obj, invObj)
    if not ok then
        LiveWire.notify(character, why, { arg1, arg2 }, true)
        return false
    end
    local dev = X.inverterOf(invObj)
    if not dev then
        LiveWire.notify(character, "Tooltip_LWX_NoInverter", {}, true)
        return false
    end
    local wires = arg1 or 0
    if wires > 0 and not LiveWire.Install.consume(character, "Base.ElectricWire", wires) then return false end
    local sq = obj:getSquare()
    local key = T.key(sq:getX(), sq:getY(), sq:getZ())
    local t = { x = sq:getX(), y = sq:getY(), z = sq:getZ(), inv = dev.id }
    D.table().terminals = D.table().terminals or {}
    D.table().terminals[key] = t
    local area = S.zoneArea(t, X.Zone.default(t.x, t.y))
    C.commit(dev.id, function(e) if area then e.areas[S.zoneKey(key)] = area end end)
    LiveWire.notify(character, "IGUI_LWX_TerminalLinked", {})
    X.log("terminal " .. key .. " linked to " .. tostring(dev.id) .. " with " .. wires .. " wires")
    return true
end

-- Forget terminal `key` and every area it carries (its zone, a relayed building).
function S.forget(key)
    local terminals = D.table().terminals or {}
    local t = terminals[key]
    if not t then return false end
    terminals[key] = nil
    local e = D.entry(t.inv)
    if e and e.areas then
        C.commit(t.inv, function(entry)
            for k, a in pairs(entry.areas) do
                if a.terminal == key or a.via == key then entry.areas[k] = nil end
            end
        end)
    elseif isServer() then
        ModData.transmit(X.DATA_KEY)
    end
    X.log("terminal " .. key .. " unlinked")
    return true
end

function S.unlink(character, obj)
    local sq = obj:getSquare()
    if not sq or not S.forget(T.key(sq:getX(), sq:getY(), sq:getZ())) then return false end
    LiveWire.notify(character, "IGUI_LWX_TerminalUnlinked", {})
    return true
end

-- Set the zone of terminal `obj` from a drawn rectangle (squares, any corners). The
-- rectangle is rounded to whole chunks and must respect LWX_Zone.allowed.
function S.setZone(character, obj, x0, y0, x1, y1)
    local sq = obj and obj:getSquare()
    local key = sq and T.key(sq:getX(), sq:getY(), sq:getZ())
    local t = key and (D.table().terminals or {})[key]
    if not t or not C.inverter(t.inv) then
        LiveWire.notify(character, "Tooltip_LWX_TerminalNotLinked", {}, true)
        return false
    end
    local rect = X.Zone.round(x0, y0, x1, y1)
    local ok, why = X.Zone.allowed(rect, t.x, t.y)
    if not ok then
        LiveWire.notify(character, why, {}, true)
        return false
    end
    local area = S.zoneArea(t, rect)
    if not area then
        LiveWire.notify(character, "IGUI_LWX_ZoneTooFar", {}, true)
        return false
    end
    C.commit(t.inv, function(e) e.areas[S.zoneKey(key)] = area end)
    LiveWire.notify(character, "IGUI_LWX_ZoneSet", { tostring(#area.positions) })
    X.log("zone of terminal " .. key .. " set to chunks " .. rect.cx0 .. "," .. rect.cy0 .. ".." .. rect.cx1 .. "," .. rect.cy1)
    return true
end

-- Picked up or destroyed: drop its record (authority).
local function onRemoved(obj)
    if not obj or not T.isTerminal(obj) then return end
    local sq = obj:getSquare()
    if sq then S.forget(T.key(sq:getX(), sq:getY(), sq:getZ())) end
end

-- Terminals of removed inverters, and terminals whose square is loaded without them.
function S.prune()
    local terminals = D.table().terminals or {}
    local stale = {}
    for key, t in pairs(terminals) do
        if not C.inverter(t.inv) then
            stale[#stale + 1] = key
        else
            local sq = getCell():getGridSquare(t.x, t.y, t.z)
            if sq and not T.onSquare(sq) then stale[#stale + 1] = key end
        end
    end
    for i = 1, #stale do S.forget(stale[i]) end
    return #stale > 0
end

Events.OnObjectAboutToBeRemoved.Add(onRemoved)
Events.EveryHours.Add(S.prune)
