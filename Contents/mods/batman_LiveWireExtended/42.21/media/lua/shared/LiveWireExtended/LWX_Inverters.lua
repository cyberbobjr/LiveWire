-- LiveWire Extended: the inverters of Live Wire that own a zone, read through LiveWire.API
-- (D-47). One module for every caller. Authority only: there is no registry on a client.
require "LiveWire/LW_Coupling"
require "LiveWireExtended/LWX_Core"

local X = LiveWire.Extended
local Inv = {}
X.Inverters = Inv

-- Does an inverter whose coupling state is `coupled` (master id, true, or nil) own a zone?
-- An independent one does; a coupled one only while a coupling add-on keeps the zones of
-- coupled inverters (LiveWire.Coupling, D-45). Shared: also read from marks on a client.
function Inv.ownsZone(coupled)
    return not coupled or LiveWire.Coupling.slaveKeepsZone()
end

-- Live inverter `id` that owns a zone ({ id, x, y, z, ... }, a copy), or nil: unknown,
-- registry not ready, or coupled without an add-on keeping its zone.
function Inv.get(id)
    local dev = LiveWire.API.inverter(id)
    if not dev or not Inv.ownsZone(dev.coupled) then return nil end
    return dev
end

-- Same, for the placed Live Wire object `obj` standing on the square its inverter is registered on.
function Inv.ofObject(obj)
    local dev = LiveWire.API.inverterOfObject(obj)
    if not dev or not Inv.ownsZone(dev.coupled) then return nil end
    return dev
end
