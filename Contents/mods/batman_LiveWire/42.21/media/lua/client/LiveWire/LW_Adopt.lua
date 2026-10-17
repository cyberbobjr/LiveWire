-- Live Wire: a placed Live Wire tile that never got its registry mark (another mod
-- replaced the vanilla placement function, lost ModData...). LW_Visuals.lua calls
-- Adopt.check for every tracked tile once a second; after a grace period the client
-- asks the authority to register it (C_ADOPT), which re-checks everything.
if isServer() then return end

LiveWire = LiveWire or {}

local Adopt = {}
LiveWire.Adopt = Adopt

Adopt.GRACE_MS = 10000   -- the mark travels by transmitModData right after placement
Adopt.RETRY_MS = 60000   -- per square
Adopt.MIN_GAP_MS = 2000  -- between two requests (server rate limit: 4 commands/s)

local firstSeen = {}  -- object -> ms
local sent = {}       -- posKey -> ms
local lastSend = 0

local function unbound(obj)
    local sq = obj:getSquare()
    if not sq then return false end
    local m = LiveWire.Marks.get(obj)
    if not m then return true end
    if m.x ~= nil and (m.x ~= sq:getX() or m.y ~= sq:getY() or m.z ~= sq:getZ()) then return true end
    return false
end

function Adopt.check(obj, now)
    if not unbound(obj) then
        firstSeen[obj] = nil
        return
    end
    local t0 = firstSeen[obj]
    if not t0 then
        firstSeen[obj] = now
        return
    end
    if now - t0 < Adopt.GRACE_MS or now - lastSend < Adopt.MIN_GAP_MS then return end
    local sq = obj:getSquare()
    local key = LiveWire.posKey(sq:getX(), sq:getY(), sq:getZ())
    if sent[key] and now - sent[key] < Adopt.RETRY_MS then return end
    sent[key] = now
    lastSend = now
    LiveWire.Client.send(LiveWire.Protocol.C_ADOPT, { x = sq:getX(), y = sq:getY(), z = sq:getZ() })
end

function Adopt.forget(obj)
    firstSeen[obj] = nil
end
