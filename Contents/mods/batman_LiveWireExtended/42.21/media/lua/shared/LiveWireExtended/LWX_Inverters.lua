-- LiveWire Extended: the independent inverters of Live Wire, read through LiveWire.API
-- (D-47). One module for every caller. Authority only: there is no registry on a client.
require "LiveWireExtended/LWX_Core"

local X = LiveWire.Extended
local Inv = {}
X.Inverters = Inv

-- Live, independent inverter `id` ({ id, x, y, z, ... }, a copy), or nil: unknown, registry
-- not ready, or a coupled slave (it has no anchor of its own).
function Inv.get(id)
    local dev = LiveWire.API.inverter(id)
    if not dev or dev.coupled then return nil end
    return dev
end

-- Same, for the placed Live Wire object `obj` standing on the square its inverter is registered on.
function Inv.ofObject(obj)
    local dev = LiveWire.API.inverterOfObject(obj)
    if not dev or dev.coupled then return nil end
    return dev
end
