-- Live Wire: core namespace, version and logging.
-- Every Live Wire file starts with `LiveWire = LiveWire or {}` because files load in
-- lower-case path order (knowledge/mod-loading.md:64-69).

LiveWire = LiveWire or {}

LiveWire.VERSION = "1.6.1"
LiveWire.MODULE = "LiveWire"          -- client/server command module
LiveWire.DATA_KEY = "LiveWire"        -- global ModData: authoritative registry (server only)
LiveWire.ANCHOR_KEY = "LiveWireAnchors" -- global ModData: public anchor table (all clients)
LiveWire.SCHEMA = 2                   -- registry schema version (see LW_Migration.lua)
LiveWire.STEP_HOURS = 1 / 6           -- nominal simulation step (EveryTenMinutes)

function LiveWire.log(msg)
    print("[LiveWire] " .. tostring(msg))
end

function LiveWire.warn(msg)
    print("[LiveWire] WARNING: " .. tostring(msg))
end

-- True on single player and on the server: the side that owns the state.
function LiveWire.isAuthority()
    return not isClient()
end

function LiveWire.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function LiveWire.posKey(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end
