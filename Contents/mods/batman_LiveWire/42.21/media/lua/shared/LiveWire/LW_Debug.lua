-- Live Wire: who may use the debug tools, and the list of debug actions (shared).
-- Single player: only when the game runs with -debug (isDebugEnabled = Core.debug,
-- knowledge/logs-and-tools.md:198). Multiplayer: administrators only, through a
-- capability that only the built-in admin role has (knowledge/multiplayer.md:131).
-- The server checks it again on every command: checkPermissions alone is true
-- when the connection is not found, so the role is checked too
-- (knowledge/logs-and-tools.md:159).

LiveWire = LiveWire or {}

local Debug = {}
LiveWire.Debug = Debug

Debug.RANGE = 30

-- Debug actions: name -> needs a device id.
Debug.ACTIONS = {
    spawnKit = false,     -- every placeable device, batteries, wire and tools
    removeRelays = false, -- every water relay of every pump (before removing the mod)
    dump = true,          -- network state in the console and on screen
    battery100 = true, battery50 = true, battery15 = true, battery0 = true,
    advance1 = true, advance12 = true, -- run the simulation 1 h / 12 h now
    repairAll = true,     -- every device of the network back to 100
    damageInverter = true,-- inverter condition to 10
    trip = true,          -- trip the inverter now
    refuel = true,        -- fill the linked backup generator
    reanchor = true,      -- rebuild the demand inventory and re-apply the anchor
}

local function capability()
    return Capability and Capability.ChangeAndReloadServerOptions
end

function Debug.allowed(player)
    if not player then return false end
    if isServer() then
        local cap = capability()
        if not cap then return false end
        local role = player:getRole()
        return checkPermissions(player, cap) and role ~= nil and role:hasCapability(cap)
    end
    if isClient() then
        -- Display only: the server decides.
        local cap = capability()
        local role = player:getRole()
        return cap ~= nil and role ~= nil and role:hasCapability(cap)
    end
    return isDebugEnabled() == true
end
