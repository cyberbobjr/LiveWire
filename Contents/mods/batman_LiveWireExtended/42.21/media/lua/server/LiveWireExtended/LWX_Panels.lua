if isClient() then return end
-- LiveWire Extended: breaker boards on the authority (D-35). Linked through LWX_Linked;
-- the record keeps the board size and its breakers:
--   panels["x,y,z"] = { x, y, z, inv = inverterId, size = 8|16|24, slots = { ... } }
require "LiveWireExtended/LWX_Linked"
require "LiveWireExtended/LWX_Panel"

local X = LiveWire.Extended
local P = X.Panel
local PS = {}
X.Panels = PS

P.kind.onLink = function(record, dev, key, obj)
    record.size = P.size(obj) or 8
    record.slots = {}
end

function PS.link(character, obj, invObj)
    if not P.isPanel(obj) then return false end
    return X.Linked.link(character, obj, invObj)
end

function PS.unlink(character, obj)
    if not P.isPanel(obj) then return false end
    return X.Linked.unlink(character, obj)
end
