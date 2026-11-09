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
-- Registration happens while Lua files load, before OnInitGlobalModData, like API v1.
LiveWire = LiveWire or {}

local CP = { version = 1 }
LiveWire.CircuitProvider = CP

local provider, sealed = nil, false

function CP.register(p)
    if sealed then return false, "registration_closed" end
    if provider then return false, "already_registered" end
    if type(p) ~= "table" or type(p.blocked) ~= "function" then return false, "invalid_provider" end
    provider = p
    return true
end

function CP.active() return provider ~= nil end

function CP.blocked(o, kind, grid)
    return provider ~= nil and provider.blocked(o, kind, grid) == true
end

function CP.deviceBlocked(dev)
    return provider ~= nil and provider.deviceBlocked ~= nil and provider.deviceBlocked(dev) == true
end

Events.OnInitGlobalModData.Add(function() sealed = true end)
