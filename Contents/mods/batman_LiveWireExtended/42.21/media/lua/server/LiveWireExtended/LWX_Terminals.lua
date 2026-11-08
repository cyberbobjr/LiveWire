if isClient() then return end
-- LiveWire Extended: power terminals on the authority (D-34). A terminal is a placed
-- object of this sub-mod (tiles batman_livewireext_01_0..3), linked to an inverter by
-- Live Wire's cable rules (LinkRange, LinkVerticalRange, WirePerTiles) and recorded
-- in this sub-mod's ModData only: Live Wire's registry gets no new role.
--   terminals["x,y,z"] = { x, y, z, inv = inverterId }
--   its zone: inverters[inv].areas["t:x,y,z"] = LWX_Zone area
require "LiveWireExtended/LWX_Connect"
require "LiveWireExtended/LWX_Linked"
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

-- Linking and forgetting go through LWX_Linked; a terminal adds its default zone when
-- linked and drops every area it carries (its zone, a relayed building) when forgotten.
T.kind.onLink = function(t, dev, key)
    local area = S.zoneArea(t, X.Zone.default(t.x, t.y))
    C.commit(dev.id, function(e) if area then e.areas[S.zoneKey(key)] = area end end)
end
T.kind.onForget = function(t, key)
    local e = D.entry(t.inv)
    if e and e.areas then
        C.commit(t.inv, function(entry)
            for k, a in pairs(entry.areas) do
                if a.terminal == key or a.via == key then entry.areas[k] = nil end
            end
        end)
    end
end

function S.link(character, obj, invObj)
    if not T.isTerminal(obj) then return false end
    return X.Linked.link(character, obj, invObj)
end
function S.forget(key) return X.Linked.forget(T.kind, key) end
function S.unlink(character, obj)
    if not T.isTerminal(obj) then return false end
    return X.Linked.unlink(character, obj)
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

-- Relay (D-33): a linked terminal connects the building it stands in or touches,
-- fed by the terminal's inverter. The area remembers the terminal (via).
S.RELAY_REACH = 2
function S.connectBuilding(character, obj)
    local sq = obj and obj:getSquare()
    local key = sq and T.key(sq:getX(), sq:getY(), sq:getZ())
    local t = key and (D.table().terminals or {})[key]
    local dev = t and C.inverter(t.inv)
    if not dev then
        LiveWire.notify(character, "Tooltip_LWX_TerminalNotLinked", {}, true)
        return false
    end
    return C.connectBuilding(character, dev, t.x, t.y, t.z, S.RELAY_REACH, key)
end

-- Pick-up, destruction and the hourly prune: LWX_Linked.
S.prune = function() return X.Linked.prune() end
