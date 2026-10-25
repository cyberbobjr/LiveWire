-- Live Wire: small service snapshots, stable object identity and bounded retries.
-- Never replace containers or items. Native inventory packets keep their owners.
LiveWire = LiveWire or {}
local S = { KEY = "LiveWireService", LIMIT = 512 }
LiveWire.ServiceSync = S
local function record(o)
    return o and o:hasModData() and o:getModData()[S.KEY] or nil
end
local function snapshot(o)
    local r, sq, sprite = record(o), o:getSquare(), o:getSprite()
    if not r or not sq or not sprite or o:getObjectIndex() == -1 then return nil end
    local out = { id = r.id, rev = r.rev, x = sq:getX(), y = sq:getY(), z = sq:getZ(),
        sprite = sprite:getName(), types = {}, media = r.media, request = 0 }
    for i in pairs(r.types or {}) do
        local c = o:getContainerByIndex(tonumber(i))
        if c then out.types[i] = c:getType() end
    end
    if r.media then out.on = o:getDeviceData():getIsTurnedOn() end
    return out
end
function S.publish(o, state)
    if not isServer() then return end
    local r = record(o)
    if not r then r = { id = LiveWire.Registry.newId("c"), rev = 0 }; o:getModData()[S.KEY] = r end
    r.rev, r.media, r.types = r.rev + 1, state.kind == "media", {}
    for i in pairs(state.types or {}) do r.types[i] = true end
    local args = snapshot(o)
    if not args then return end
    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if math.abs(p:getX() - args.x) <= 100 and math.abs(p:getY() - args.y) <= 100 then
            sendServerCommand(p, LiveWire.MODULE, LiveWire.Protocol.S_SERVICE, args)
        end
    end
end
local function resolve(a, strict)
    local sq = getCell():getGridSquare(a.x, a.y, a.z)
    local objects, fallback, matches = sq and sq:getObjects(), nil, 0
    for i = 0, objects and objects:size() - 1 or -1 do
        local o = objects:get(i)
        local r = record(o)
        if r and r.id == a.id then return o end
        local sprite = o:getSprite()
        if sprite and sprite:getName() == a.sprite then
            matches = matches + 1
            if not r then fallback = o end
        end
    end
    if not strict and matches == 1 then return fallback end
end
local function integer(v, lo, hi)
    return type(v) == "number" and v == v and v >= lo and v <= hi and v == math.floor(v)
end
function S.reply(player, args)
    if isClient() or not player or player:isDead() or not integer(args.seq, 1, 1000000000)
        or type(args.services) ~= "table" or #args.services > 16 then return end
    local out = {}
    for _, a in ipairs(args.services) do
        if type(a) == "table" and LiveWire.Protocol.isId(a.id, "c")
            and integer(a.x, -1000000, 1000000) and integer(a.y, -1000000, 1000000)
            and integer(a.z, -32, 31) and math.abs(player:getX() - a.x) <= 100
            and math.abs(player:getY() - a.y) <= 100 then
            local o = resolve(a, true)
            local s = o and snapshot(o)
            if s then s.request = args.seq; out[#out + 1] = s end
        end
    end
    if #out > 0 and isServer() then
        sendServerCommand(player, LiveWire.MODULE, LiveWire.Protocol.S_SERVICES, { services = out })
    end
end
if not isClient() then return end

local pending, order, cursor, applied, seen = {}, {}, 1, {}, {}
local sequence, nextTick, nextRequest, lastClock = 0, 0, 0, nil
function S.clear()
    pending, order, cursor, applied, seen = {}, {}, 1, {}, {}
    sequence, nextTick, nextRequest, lastClock = 0, 0, 0, nil
end
local function remove(i)
    pending[order[i].id] = nil
    order[i] = order[#order]; order[#order] = nil
    if cursor > #order then cursor = 1 end
end
local function remember(a)
    if not applied[a.id] then
        if #seen == S.LIMIT then applied[table.remove(seen, 1)] = nil end
        seen[#seen + 1] = a.id
    end
    applied[a.id] = { rev = a.rev, request = a.request or 0 }
end
local function apply(a)
    local o = resolve(a, false)
    if not o then return false end
    local r, old = record(o), applied[a.id]
    if old and (old.rev > a.rev
        or (old.rev == a.rev and old.request >= (a.request or 0))) then return true end
    -- Newer ModData alone does not prove the native container was mirrored.
    -- Keep the read pending until a snapshot of that revision is available.
    if r and r.rev > a.rev then return false end
    local changed = false
    for i, name in pairs(a.types or {}) do
        local c = o:getContainerByIndex(tonumber(i))
        if c and c:getType() ~= name then c:setType(name); changed = true end
    end
    if changed then
        local chunk = o:getChunk()
        if chunk then
            if o:couldBePoweredByGenerator() then chunk:addObjectPoweredByGenerator(o)
            else chunk:removeObjectPoweredByGenerator(o) end
        end
        o:checkHaveElectricity()
    end
    if a.media and (instanceof(o, "IsoRadio") or instanceof(o, "IsoTelevision")) then
        o:getDeviceData():setTurnedOnRaw(a.on == true)
    end
    remember(a)
    return true
end
local function queue(a)
    local e = pending[a.id]
    if e then
        if not e.args or a.rev > e.args.rev or (a.rev == e.args.rev
            and (a.request or 0) >= (e.args.request or 0)) then e.args = a end
        e.expires = getTimestampMs() + 60000
        return
    end
    if #order == S.LIMIT then remove(1) end
    e = { id = a.id, args = a, expires = getTimestampMs() + 60000, retryAt = 0 }
    pending[a.id], order[#order + 1] = e, e
end
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= LiveWire.MODULE then return end
    local P = LiveWire.Protocol
    local services = command == P.S_SERVICE and { args } or command == P.S_SERVICES and args.services
    for _, a in ipairs(services or {}) do
        if type(a.id) == "string" and type(a.rev) == "number" then
            local done = apply(a)
            if not done then queue(a)
            elseif pending[a.id] and (a.request or 0) > 0 then
                -- A later queued broadcast must not be erased by an older reply.
                local e = pending[a.id]
                if not e.args or a.rev >= e.args.rev then
                    for i, v in ipairs(order) do if v == e then remove(i); break end end
                end
            end
        end
    end
end)
local function discover(o)
    local r, sq, sprite = record(o), o:getSquare(), o:getSprite()
    if r and sq and sprite then
        -- Read actual server state after chunk load; do not replay an old radio
        -- ON choice that another player may have changed since the last cut.
        queue({ id = r.id, rev = r.rev, x = sq:getX(), y = sq:getY(), z = sq:getZ(), sprite = sprite:getName() })
    end
end
Events.OnObjectAdded.Add(discover)
Events.LoadChunk.Add(function(chunk)
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for i = 0, 63 do
            local sq = chunk:getGridSquare(i % 8, math.floor(i / 8), z)
            local objects = sq and sq:getObjects()
            for j = 0, objects and objects:size() - 1 or -1 do discover(objects:get(j)) end
        end
    end
end)
Events.OnTick.Add(function()
    local now = getTimestampMs()
    if lastClock and now < lastClock then
        nextTick, nextRequest = now, now
        for _, e in ipairs(order) do e.expires, e.retryAt = now + 60000, now end
    end
    lastClock = now
    if now < nextTick or #order == 0 then return end
    nextTick = now + 250
    local player = getPlayer()
    if not player or player:getOnlineID() < 0 or not player:getCurrentSquare() then return end
    local requests, budget = {}, math.min(16, #order)
    while budget > 0 and #order > 0 do
        local e = order[cursor]
        if now >= e.expires then remove(cursor)
        else
            local a = e.args
            if a.types then apply(a) end
            if now >= nextRequest and now >= e.retryAt and resolve(a, false) then
                requests[#requests + 1] = { id = a.id, x = a.x, y = a.y, z = a.z }
                e.retryAt = now + 2000
            end
            cursor = cursor % #order + 1
        end
        budget = budget - 1
    end
    if #requests > 0 then
        sequence = sequence % 1000000000 + 1
        nextRequest = now + 500
        sendClientCommand(player, LiveWire.MODULE, LiveWire.Protocol.C_READ_SERVICES,
            { seq = sequence, services = requests })
    end
end)
Events.OnDisconnect.Add(S.clear)
Events.OnMainMenuEnter.Add(S.clear)
