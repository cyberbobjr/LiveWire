if isClient() then return end
-- LiveWire Extended: admin action before removing the sub-mod (E23). "Switch every
-- breaker back on": no breaker cuts anymore, the rule of D-37 stops, every loaded point
-- is restored at once (fridge container types, Functional Appliances 2 settings, terminal
-- zones) and Live Wire revisits the other appliances progressively. The state is saved:
-- areas loaded later are restored too, by Extended while it is there, and by Live Wire
-- (I21) once it is gone. The admin can resume.
require "LiveWireExtended/LWX_PointsServer"

local X = LiveWire.Extended
local PT, D = X.Points, X.Data
local RL = {}
X.Release = RL
RL.MODULE = "LiveWireExtended"

local previousBlockedKey = PT.blockedKey
PT.blockedKey = function(...)
    if D.table().released then return false end
    return previousBlockedKey(...)
end

local function applyAll()
    local n = 0
    for key, p in pairs(PT.table()) do
        for _, o in ipairs(PT.objectsOf(key, p)) do PT.apply(o); n = n + 1 end
    end
    PT.regionsChanged()
    if isServer() then ModData.transmit(X.DATA_KEY) end
    return n
end

function RL.run(character)
    if not X.isAdmin(character) then return false end
    D.table().released = true
    local n = applyAll()
    LiveWire.notify(character, "IGUI_LWX_Released", { tostring(n) })
    X.log("every breaker released by " .. tostring(character and character:getUsername()) .. ", " .. n .. " loaded points restored")
    return true
end

function RL.resume(character)
    if not X.isAdmin(character) then return false end
    D.table().released = nil
    applyAll()
    LiveWire.notify(character, "IGUI_LWX_Resumed", {})
    X.log("breakers resumed by " .. tostring(character and character:getUsername()))
    return true
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= RL.MODULE then return end
    if command == "release" then RL.run(player) elseif command == "resume" then RL.resume(player) end
end)
