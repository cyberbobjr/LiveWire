-- Live Wire: coupling extension point (D-45). Without a registered add-on, every
-- function below is Live Wire's own rule: a coupled (slave) inverter has no zone of
-- its own, and two inverters couple within the cable range (LinkRange).
--
-- One add-on may register, while Lua files load (before OnInitGlobalModData):
--   LiveWire.Coupling.register({
--       slaveKeepsZone = true,            -- optional: each coupled inverter keeps its
--                                         -- own powered zone; the network shares one
--                                         -- load (sum of the zones) and one capacity
--       range = function() return 70 end, -- optional: coupling distance in tiles
--       inverters = function(sq) ... end, -- optional: inverters a coupling can reach
--                                         -- from `sq`, as Install.invertersInRange
--                                         -- returns them ({ obj, dist, kind }, nearest
--                                         -- first); needed when `range` exceeds what a
--                                         -- square scan of the cable range finds
--       menu = function(menu, player, obj, mark, isSlave) end, -- optional, client:
--                                         -- adds options to an inverter's Live Wire menu
--   })
-- Returns true, or false and a reason: "registration_closed", "already_registered",
-- "invalid_provider".
require "LiveWire/LW_Config"
LiveWire = LiveWire or {}

local Coupling = { version = 1 }
LiveWire.Coupling = Coupling

local provider, sealed = nil, false
local FIELDS = { range = "function", inverters = "function", menu = "function", slaveKeepsZone = "boolean" }

function Coupling.register(p)
    if sealed then return false, "registration_closed" end
    if provider then return false, "already_registered" end
    if type(p) ~= "table" then return false, "invalid_provider" end
    for k, v in pairs(p) do
        if not FIELDS[k] or type(v) ~= FIELDS[k] then return false, "invalid_provider" end
    end
    provider = p
    return true
end

function Coupling.active() return provider ~= nil end

-- Does a coupled inverter keep its own powered zone?
function Coupling.slaveKeepsZone() return provider ~= nil and provider.slaveKeepsZone == true end

-- Coupling distance in tiles (the cable range unless an add-on sets another one).
function Coupling.range()
    local base = LiveWire.Config.get("LinkRange")
    if not provider or not provider.range then return base end
    local r = provider.range()
    if type(r) ~= "number" or r ~= r or r <= 0 then return base end
    return r
end

-- Inverters a coupling can reach from `sq`, nearest first ({ obj, dist, kind }).
function Coupling.inverters(sq)
    if provider and provider.inverters then return provider.inverters(sq) or {} end
    return LiveWire.Install.invertersInRange(sq)
end

-- Inverter object with device id `id` that a coupling can reach from `sq`, or nil.
function Coupling.inverterById(sq, id)
    if not id then return nil end
    local list = Coupling.inverters(sq)
    for i = 1, #list do
        local m = LiveWire.Marks.get(list[i].obj)
        if m and m.id == id then return list[i].obj end
    end
    return nil
end

-- Client: let the add-on add its options to an inverter's menu.
function Coupling.addMenu(menu, player, obj, mark, isSlave)
    if provider and provider.menu then provider.menu(menu, player, obj, mark, isSlave == true) end
end

Events.OnInitGlobalModData.Add(function() sealed = true end)
