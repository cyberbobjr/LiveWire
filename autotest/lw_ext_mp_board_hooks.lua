-- LiveWire Extended, breaker boards in multiplayer (pzdev, E23). The server puts a
-- board in the spawn house, links it to an inverter it places, installs a breaker and wires
-- one two-tile fridge to it, and places a second, unwired fridge (D-37). The client
-- reports what ITS copies show: board record received, wired fridge cooling, unwired one
-- cut; then breaker off (wired fridge cut), on again, and the admin release (both cool).
-- server mode (no player): the sub-mod loads and registers its providers.
local H = { server = {}, client = {} }
local S = { lines = {}, ok = true }
local MODULE = "LWXBoardTest"
local function rec(ok, name, detail)
    if not ok then S.ok = false end
    S.lines[#S.lines + 1] = (ok and "PASS " or "FAIL ") .. name .. " - " .. tostring(detail or "")
end
local function info(name, detail) S.lines[#S.lines + 1] = "INFO " .. name .. " - " .. tostring(detail or "") end
local X = LiveWire.Extended

local function place(player, sq, name)
    local props = ISMoveableSpriteProps.new(getSprite(name))
    return props:placeMoveableInternal(player, sq, props:instanceItem(name), name)
end

local function roomSquares(def, inner)
    local out, cell = {}, getCell()
    local rooms = def:getRooms()
    for i = 0, rooms:size() - 1 do
        local room = rooms:get(i)
        if room:getZ() == 0 then
            local rects = room:getRects()
            for j = 0, rects:size() - 1 do
                local r = rects:get(j)
                local m = inner and 1 or 0
                for y = r:getY() + m, r:getY() + r:getH() - 1 - m do
                    for x = r:getX() + m, r:getX() + r:getW() - 1 - m do
                        local sq = cell:getGridSquare(x, y, 0)
                        if sq then out[#out + 1] = sq end
                    end
                end
            end
        end
    end
    return out
end

local function fridgeAt(player, a, b)
    local g = getSprite("appliances_refrigeration_01_18"):getSpriteGrid()
    local pieces = {}
    for gx = 0, 1 do
        local piece = g:getSprite(gx, 0)
        local sq = gx == 0 and a or b
        place(player, sq, piece:getName())
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local spr = objs:get(i):getSprite()
            if spr and spr:getName() == piece:getName() then pieces[#pieces + 1] = objs:get(i) end
        end
    end
    return pieces
end

-- ---------------------------------------------------------------- server
local function serverOnly()
    rec(X ~= nil and X.Data.registered == true, "sub-mod loaded, coverage provider registered on the dedicated server")
    rec(X.circuitProviderRegistered == true, "circuit provider registered")
    rec(X.HousesServer ~= nil and X.Release ~= nil and X.Protection ~= nil, "board modules loaded on the server")
    return true
end

local function send(command)
    for _, p in ipairs(S.ctx.players()) do sendServerCommand(p, MODULE, command, S.scene) end
end

function H.server.start(ctx)
    S.ctx = ctx
    local players = ctx.players()
    S.player = players and players[1]
    if not S.player then return serverOnly() end
    S.errors = getLuaDebuggerErrorCount()
    S.checked = {}
    Events.OnClientCommand.Add(function(module, command, player, args)
        if module == MODULE and command == "checked" then S.checked[args.phase] = args end
    end)
    Events.EveryTenMinutes.Remove(LiveWire.Sim.tick)
    local p = S.player
    p:setPerkLevelDebug(Perks.Electricity, 10)
    local def = getWorld():getMetaGrid():getBuildingAt(math.floor(p:getX()), math.floor(p:getY()), 0)
        or X.Buildings.find(math.floor(p:getX()), math.floor(p:getY()), 0, 30, 3)
    if not def then rec(false, "spawn house"); return true end
    local cell = getCell()
    local boardSq, inverterSq, pairs_ = nil, nil, {}
    for _, sq in ipairs(roomSquares(def, false)) do
        if not boardSq and sq:getWall(true) and sq:isFree(false) and not X.Panel.onSquare(sq) then boardSq = sq end
    end
    for _, sq in ipairs(roomSquares(def, true)) do
        if sq == boardSq then
        elseif sq:isFree(false) and not X.Panel.onSquare(sq) then
            local e = cell:getGridSquare(sq:getX() + 1, sq:getY(), 0)
            if e and e:isFree(false) and e:getRoom() and #pairs_ < 2 and sq ~= boardSq and e ~= boardSq then
                local clash = false
                for _, q in ipairs(pairs_) do
                    if math.abs(q[1]:getY() - sq:getY()) < 1 and math.abs(q[1]:getX() - sq:getX()) < 3 then clash = true end
                end
                if not clash then pairs_[#pairs_ + 1] = { sq, e } end
            elseif not inverterSq then inverterSq = sq end
        end
    end
    if not boardSq or #pairs_ < 2 or not inverterSq then
        rec(false, "free squares in the spawn house", tostring(boardSq) .. " " .. #pairs_ .. " " .. tostring(inverterSq))
        return true
    end
    local invObj = place(p, inverterSq, "batman_livewire_01_12")
    local m = invObj and LiveWire.Marks.get(invObj)
    local inv = m and LiveWire.Registry.device(m.id)
    if not inv then rec(false, "inverter placed"); return true end
    local orig = LiveWire.Sim.updateAnchor
    LiveWire.Sim.updateAnchor = function(dev, on) return orig(dev, (dev and dev.id == inv.id) or on) end
    inv.state = "on"
    LiveWire.Sim.updateAnchor(inv, true); LiveWire.Registry.grid(inv.grid).powered = true
    local board = place(p, boardSq, X.Terminal.SHEET .. "_8")
    p:getInventory():AddItems("Base.ElectricWire", 30)
    if p:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then p:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
    p:getInventory():AddItem("Base.Screwdriver")
    p:getInventory():AddItem("LiveWire.Breaker20")
    rec(X.Panels.link(p, board, invObj), "board linked to the inverter")
    rec(X.Panels.installBreaker(p, board, "LiveWire.Breaker20"), "20 A breaker installed")
    local wired = fridgeAt(p, pairs_[1][1], pairs_[1][2])
    local loose = fridgeAt(p, pairs_[2][1], pairs_[2][2])
    rec(#wired == 2 and #loose == 2, "two two-tile fridges placed")
    rec(X.Points.connect(p, wired[1], board, 1), "first fridge wired to module 1")
    S.board, S.wired, S.loose = board, wired, loose
    local function pos(o) local sq = o:getSquare(); return { x = sq:getX(), y = sq:getY(), z = sq:getZ(), spr = o:getSprite():getName() } end
    S.scene = { board = pos(board), wired = { pos(wired[1]), pos(wired[2]) }, loose = { pos(loose[1]), pos(loose[2]) } }
    S.step, S.at = "on", getTimestampMs()
    send("on")
    return true
end

local STEPS = { "on", "off", "released" }
function H.server.done(ctx)
    if not S.step then return true end
    if getTimestampMs() - S.at > 240000 then rec(false, "client checks received", S.step); return true end
    if not S.checked[S.step] then return false end
    if S.step == "on" then
        X.Panels.setBreaker(S.player, S.board, 1, true)
        S.step = "off"
    elseif S.step == "off" then
        X.Release.run(S.player)
        S.step = "released"
    else
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error on the server", getLuaDebuggerErrorCount() - S.errors)
        S.step = nil
        return true
    end
    S.at = getTimestampMs()
    send(S.step)
    return false
end

function H.server.result(ctx)
    for _, step in ipairs(STEPS) do
        local c = S.checked and S.checked[step]
        if c then
            info("client " .. step, string.format("record=%s wired=%s loose=%s", tostring(c.record), tostring(c.wired), tostring(c.loose)))
        end
    end
    return { ok = S.ok, summary = "LiveWire Extended boards server" .. (S.player and " + client" or " only"), lines = S.lines }
end

-- ---------------------------------------------------------------- client
local C = {}
local function find(e)
    local sq = getCell():getGridSquare(e.x, e.y, e.z)
    local objs = sq and sq:getObjects()
    for i = 0, objs and objs:size() - 1 or -1 do
        local spr = objs:get(i):getSprite()
        if spr and spr:getName() == e.spr then return objs:get(i) end
    end
end
local function cooling(list)
    local n = 0
    for _, e in ipairs(list) do
        local o = find(e)
        if o and o:getContainerByType("fridge") then n = n + 1 end
    end
    return n
end

function H.client.start(ctx)
    C.t0 = getTimestampMs()
    Events.OnServerCommand.Add(function(module, command, args)
        if module == MODULE then C.cmd, C.at = { step = command, scene = args }, getTimestampMs() end
    end)
    return true
end

local EXPECT = { on = { 2, 0 }, off = { 0, 0 }, released = { 2, 2 } }
function H.client.done(ctx)
    if not C.cmd then
        if getTimestampMs() - C.t0 > 300000 then rec(false, "server scene received"); return true end
        return false
    end
    if getTimestampMs() - C.at < 4000 then return false end
    local step, scene = C.cmd.step, C.cmd.scene
    local bsq = getCell():getGridSquare(scene.board.x, scene.board.y, scene.board.z)
    local record = bsq and X.Panel.recordAt(bsq)
    local w, l = cooling(scene.wired), cooling(scene.loose)
    local want = EXPECT[step]
    rec(record ~= nil and #record.slots == 1, "client " .. step .. ": board record received", record and #record.slots)
    rec(w == want[1] and l == want[2], "client " .. step .. ": wired fridge " .. want[1] .. "/2 cooling, unwired " .. want[2] .. "/2",
        w .. "/" .. l)
    sendClientCommand(getPlayer(), MODULE, "checked", { phase = step, record = record ~= nil, wired = w, loose = l })
    C.cmd = nil
    return step == "released"
end

function H.client.result(ctx)
    return { ok = S.ok, summary = "LiveWire Extended boards client", lines = S.lines }
end
return H
