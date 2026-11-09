-- Live Wire: circuit extension point (D-35, D-37). An optional sub-mod may register ONE
-- provider that cuts MORE native appliances than the panel circuits of I21: its own
-- breakers, or the rule that an unconnected appliance has no current where its panel
-- serves (D-37). It can never cut fewer: the base panel stays the main breaker.
-- Without a provider nothing changes.
--
-- Provider contract:
--   blocked(o, kind, grid) -> true to cut the appliance `o` (I21 family `kind`, owned by
--                             the panel `grid`, which may be nil); false or nil otherwise.
--                             Called on the authority by LiveWire.Circuits only.
--   deviceBlocked(dev)     -> optional: true to cut a Live Wire pump or management
--                             computer (registry device), on the authority.
--   extraWatts(inv)        -> optional: watts, count of appliances the engine does not
--                             bill (appliances of other mods) served by inverter `inv`;
--                             added to its demand as "other" (one consistent bill).
-- Registration happens while Lua files load, before OnInitGlobalModData, like API v1
-- (LiveWire.Extension.single: one provider, sealed at OnInitGlobalModData).
require "LiveWire/LW_Extension"
LiveWire = LiveWire or {}

local CP = { version = 1 }
LiveWire.CircuitProvider = CP

local extension = LiveWire.Extension.single("circuitProvider", {
    blocked = "function", deviceBlocked = "function?", extraWatts = "function?",
})
CP.register = extension.register

function CP.blocked(o, kind, grid)
    local provider = extension.get()
    return provider ~= nil and provider.blocked(o, kind, grid) == true
end

function CP.deviceBlocked(dev)
    local provider = extension.get()
    return provider ~= nil and provider.deviceBlocked ~= nil and provider.deviceBlocked(dev) == true
end

function CP.extraWatts(inv)
    local provider = extension.get()
    if not provider or not provider.extraWatts then return 0, 0 end
    local w, n = provider.extraWatts(inv)
    return tonumber(w) or 0, tonumber(n) or 0
end
