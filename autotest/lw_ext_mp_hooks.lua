-- LiveWire Extended, dedicated server and multiplayer scenarios (pzdev).
-- server mode (no player): the sub-mod loads on a dedicated server, registers its
--   coverage provider, reads map buildings and computes a footprint without any loaded
--   square; E0 measure 3: no user-defined BuildingDef exists on a dedicated server.
-- mp mode: the server connects the spawn house to an inverter it places; the client
--   checks that ITS copy of every loaded room square has power (positions declared by
--   the client on receipt of the public table), and again after a real reconnection.
local H = { server = {}, client = {} }
local S = { lines = {}, ok = true, reports = {} }
local function rec(ok, name, detail)
    if not ok then S.ok = false end
    S.lines[#S.lines + 1] = (ok and "PASS " or "FAIL ") .. name .. " - " .. tostring(detail or "")
end
local function info(name, detail) S.lines[#S.lines + 1] = "INFO " .. name .. " - " .. tostring(detail or "") end
local X = LiveWire.Extended
local MODULE = "LWXTest"

local function buildingNear(x, y, z)
    local meta = getWorld():getMetaGrid()
    local def = meta:getBuildingAt(x, y, z)
    if def then return def end
    return X.Buildings.find(x, y, z, 30, 3)
end

local function roomSquares(def)
    local out, cell = {}, getCell()
    local rooms = def:getRooms()
    for i = 0, rooms:size() - 1 do
        local room = rooms:get(i)
        local rects = room:getRects()
        for j = 0, rects:size() - 1 do
            local r = rects:get(j)
            for y = r:getY(), r:getY() + r:getH() - 1 do
                for x = r:getX(), r:getX() + r:getW() - 1 do
                    local sq = cell:getGridSquare(x, y, room:getZ())
                    if sq then out[#out + 1] = sq end
                end
            end
        end
    end
    return out
end

local function unpowered(list)
    local n = 0
    for _, sq in ipairs(list) do if not sq:haveElectricity() then n = n + 1 end end
    return n
end

local function freeIndoor(def, z)
    local cell = getCell()
    local rooms = def:getRooms()
    for i = 0, rooms:size() - 1 do
        local room = rooms:get(i)
        if room:getZ() == z then
            local rects = room:getRects()
            for j = 0, rects:size() - 1 do
                local r = rects:get(j)
                for y = r:getY() + 1, r:getY() + r:getH() - 2 do
                    for x = r:getX() + 1, r:getX() + r:getW() - 2 do
                        local sq = cell:getGridSquare(x, y, z)
                        if sq and sq:isFree(false) and sq:isSolidFloor() and not LiveWire.Marks.firstOnSquare(sq) then
                            return sq
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- ---------------------------------------------------------------- server
local function serverOnly(ctx)
    rec(X ~= nil and X.Data and X.Data.registered == true, "sub-mod loaded, provider registered on the dedicated server")
    local list = getWorld():getMetaGrid():getBuildings()
    local userDefined = 0
    for i = 0, list:size() - 1 do
        if list:get(i):isUserDefined() then userDefined = userDefined + 1 end
    end
    info("E0 measure 3", string.format("%d map buildings, %d user-defined BuildingDef on the dedicated server",
        list:size(), userDefined))
    rec(userDefined == 0, "no user-defined BuildingDef on a dedicated server (IsoRegions.java:217)", userDefined)
    local def = getWorld():getMetaGrid():getBuildingAt(10656, 10137, 0) or X.Buildings.find(10656, 10137, 0, 30, 3)
    rec(def ~= nil, "spawn building read from the map metadata without loaded squares")
    if def then
        local area = X.Buildings.area(def, "d1")
        rec(area ~= nil and #area.positions > 0, "footprint computed on the server", area and (#area.positions .. " positions"))
    end
    return true
end

function H.server.start(ctx)
    local players = ctx.players()
    S.player = players and players[1]
    if not S.player then return serverOnly(ctx) end
    S.expected = tonumber(ctx.params.reports or S.expected) or 1
    Events.OnClientCommand.Add(function(module, command, player, args)
        if module == MODULE and command == "report" then S.reports[#S.reports + 1] = args end
    end)
    Events.EveryTenMinutes.Remove(LiveWire.Sim.tick)
    S.player:setPerkLevelDebug(Perks.Electricity, 10)
    local p = S.player
    local def = buildingNear(math.floor(p:getX()), math.floor(p:getY()), 0)
    if not def then rec(false, "spawn house"); return true end
    S.def = def
    local sq = freeIndoor(def, 0)
    if not sq then rec(false, "free indoor square for the inverter"); return true end
    local name = "batman_livewire_01_12"
    local props = ISMoveableSpriteProps.new(getSprite(name))
    local obj = props:placeMoveableInternal(p, sq, props:instanceItem(name), name)
    local m = obj and LiveWire.Marks.get(obj)
    local inv = m and LiveWire.Registry.device(m.id)
    if not inv then rec(false, "inverter placed on the server"); return true end
    S.inv = inv
    LiveWire.Sim.updateAnchor(inv, true); LiveWire.Registry.grid(inv.grid).powered = true
    -- connecting a building needs a screwdriver since D-59 (2026-11-10)
    local tool = p:getInventory():AddItem("Base.Screwdriver")
    if tool then sendAddItemToContainer(p:getInventory(), tool) end
    rec(X.Connect.connectBuilding(p, inv, inv.x, inv.y, inv.z, LiveWire.Config.tileRange(), nil),
        "server connected the spawn house", X.Buildings.key(def))
    S.at = getTimestampMs()
    return true
end

function H.server.done(ctx)
    if not S.player then return true end
    if #S.reports >= (S.expected or 1) then return true end
    return getTimestampMs() - (S.at or 0) > 240000
end

function H.server.result(ctx)
    if S.player and S.def then
        local squares = roomSquares(S.def)
        rec(unpowered(squares) == 0, "server: every loaded room square powered", unpowered(squares) .. "/" .. #squares)
        for i, r in ipairs(S.reports) do
            rec(r.unpowered == 0 and r.total > 0, "client report " .. i .. (r.reconnect == "1" and " (after reconnection)" or ""),
                r.unpowered .. " unpowered of " .. r.total)
        end
        rec(#S.reports >= (S.expected or 1), "client reports received", #S.reports .. "/" .. tostring(S.expected))
    end
    return { ok = S.ok, summary = "LiveWire Extended server" .. (S.player and " + client" or " only"), lines = S.lines }
end

-- ---------------------------------------------------------------- client
local C = {}
function H.client.start(ctx)
    C.t0, C.reconnect = getTimestampMs(), ctx.params.reconnect
    return true
end

function H.client.done(ctx)
    local now = getTimestampMs()
    if not C.def then
        for _, e in pairs(X.Data.table().inverters) do
            for key, a in pairs(e.areas or {}) do
                if a.kind == "building" then
                    C.def = getWorld():getMetaGrid():getBuildingAt(a.label.x, a.label.y)
                        or buildingNear(math.floor(getPlayer():getX()), math.floor(getPlayer():getY()), 0)
                    C.at = now
                end
            end
        end
        if not C.def then
            if now - C.t0 > 180000 then rec(false, "client received the connected building"); return true end
            return false
        end
        rec(true, "client received the public table of connected areas")
        return false
    end
    if now - C.at < 3000 then return false end
    local squares = roomSquares(C.def)
    local n = unpowered(squares)
    rec(n == 0 and #squares > 0, "client: every loaded room square of the house powered", n .. " unpowered of " .. #squares)
    sendClientCommand(getPlayer(), MODULE, "report", { unpowered = n, total = #squares, reconnect = tostring(C.reconnect) })
    return true
end

function H.client.result(ctx)
    return { ok = S.ok, summary = "LiveWire Extended client" .. (C.reconnect == "1" and " (reconnected)" or ""),
        lines = S.lines }
end
return H
