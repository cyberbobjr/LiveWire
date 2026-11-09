-- LiveWire Extended: the circuit provider of this sub-mod (D-35, D-37), built complete
-- and registered ONCE with Live Wire's extension point (LW_CircuitProvider). Live Wire
-- asks it, for each native appliance and each device, whether a breaker of Extended cuts
-- it, and which estimated draws an inverter has to bill. Registration happens while the
-- Lua files load, before Live Wire seals the extension point at OnInitGlobalModData; the
-- adapters it reads (LWX_ModAdapters) are registered by the time it runs.
require "LiveWire/LW_CircuitProvider"
require "LiveWireExtended/LWX_Adapters"
require "LiveWireExtended/LWX_ModAdapters"

local X = LiveWire.Extended

local provider = {}

-- A native appliance: is it cut by a breaker of Extended?
provider.blocked = function(o) return X.Adapters.isCut(o) end

-- A Live Wire pump or management computer (registry device `dev`).
provider.deviceBlocked = function(dev)
    return X.Points.blockedKey("dev:" .. tostring(dev.id), dev.x, dev.y, dev.z)
end

-- Inverter `inv` bills the estimated draws of the points wired to its boards: the breaker
-- and the inverter count the same watts (one consistent bill). On the authority.
provider.extraWatts = function(inv)
    local PT = X.Points
    local boards = X.Data.table().panels or {}
    local estimated = {}
    for _, a in ipairs(X.Adapters.list) do
        if a.estimated then estimated[a.id] = a end
    end
    local w, n = 0, 0
    for key, p in pairs(PT.table()) do
        local a = estimated[p.adapter]
        local r = a and boards[p.board]
        if r and inv and r.inv == inv.id then
            local o = PT.objectsOf(key, p)[1]
            local d = o and a.watts(o) or 0
            if d > 0 then w, n = w + d, n + 1 end
        end
    end
    return w, n
end

X.circuitProvider = provider
X.circuitProviderRegistered = LiveWire.CircuitProvider.register(provider) == true
