-- LiveWire Extended, D-62 underground in multiplayer (pzdev, dedicated server + one client).
-- Server (authority), spawn on a map house with a vanilla cellar:
--   vanilla : the cellar counts with the house over it (same site); a board on a cellar square
--             against a north wall is accepted by the D-62 rule and the vanilla cursor, hung,
--             linked to an inverter placed in the cellar: it connects the house and serves both
--             the cellar and the ground floor.
--   modded  : Basement Building (optional mod, aparosa_BasementDig) digs a one-square cellar under
--             open ground (its own aparosa_BD_Basic.applyHole, run by the authority): a site of its
--             own, a board hung and linked serves it; a cellar dug under a map house counts with
--             that house.
-- Client: with its own copies, the same sites, the board records received, the cellar and the
-- ground floor served and powered (haveElectricity), and the D-62 rule accepting a cellar square.
-- Fixtures: objects added by script, inverter held on, cellars dug by the mod's function (no
-- shovel, no timed action), cursor checks by direct calls.
local H = { server = {}, client = {} }
local S = { lines = {}, ok = true }
local MODULE = "LWXBasementTest"
local function rec(ok, name, detail)
    if not ok then S.ok = false end
    S.lines[#S.lines + 1] = (ok and "PASS " or "FAIL ") .. name .. " - " .. tostring(detail or "")
end
local function info(name, detail) S.lines[#S.lines + 1] = "INFO " .. name .. " - " .. tostring(detail or "") end
local X = LiveWire.Extended

-- Test worlds without zombies (user request): removed at each poll, on the authority in MP.
local function clearZombies()
    local cell = getCell()
    local list = cell and cell:getZombieList()
    if not list then return end
    for i = list:size() - 1, 0, -1 do
        local z = list:get(i)
        z:removeFromWorld(); z:removeFromSquare()
    end
end
local function untouchable(p)
    if p then p:setGodMod(true); p:setInvisible(true) end
end

local BOARD, INVERTER = "batman_livewireext_01_8", "batman_livewire_01_12"
local function at(x, y, z) return getCell():getGridSquare(x, y, z) end
local function pos(sq) return sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ() end
local function xyz(sq) return { x = sq:getX(), y = sq:getY(), z = sq:getZ() } end
local function cursor() return ISMoveableSpriteProps.new(getSprite(BOARD)) end

local function freeOfWallObjects(sq)
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local spr = objs:get(i):getSprite()
        local props = spr and spr:getProperties()
        if props and props:has("MoveType") and props:get("MoveType") == "WallObject" then return false end
    end
    return true
end

-- ---------------------------------------------------------------- server
local function serverOnly()
    rec(X ~= nil and X.Sites ~= nil, "D-62 modules loaded on the dedicated server")
    info("Basement Building loaded on the server", tostring(aparosa_BD_Basic ~= nil))
    return true
end

local function send(command, args)
    for _, p in ipairs(S.ctx.players()) do sendServerCommand(p, MODULE, command, args) end
end

local function placeInverter(p, sq)
    local props = ISMoveableSpriteProps.new(getSprite(INVERTER))
    local invObj = props:placeMoveableInternal(p, sq, props:instanceItem(INVERTER), INVERTER)
    local m = invObj and LiveWire.Marks.get(invObj)
    local inv = m and LiveWire.Registry.device(m.id)
    if not inv then return nil end
    local orig = LiveWire.Sim.updateAnchor
    LiveWire.Sim.updateAnchor = function(dev, on) return orig(dev, (dev and dev.id == inv.id) or on) end
    inv.state = "on"
    LiveWire.Sim.updateAnchor(inv, true); LiveWire.Registry.grid(inv.grid).powered = true
    return inv, invObj
end

-- A free square nearest to (x0, y0) on floor z, accepted by `ok(sq)`.
local function freeSquare(x0, y0, z, ok)
    for r = 0, 15 do
        for dy = -r, r do
            for dx = -r, r do
                local sq = (math.abs(dx) == r or math.abs(dy) == r) and at(x0 + dx, y0 + dy, z)
                if sq and sq:getFloor() and sq:isFree(false) and freeOfWallObjects(sq) and ok(sq) then return sq end
            end
        end
    end
end

-- Board checked by the D-62 rule and the vanilla cursor on `sq`, hung, linked to a new inverter on `asq`.
local function hangAndLink(label, sq, asq)
    local p, c = S.player, cursor()
    rec(c:getWallForFacing(sq, "S") ~= nil, "server " .. label .. ": north wall on the board square", pos(sq))
    local okRule, why = LiveWire.Placement.checkRules(BOARD, sq, p)
    rec(okRule == true, "server " .. label .. ": the D-62 rule accepts the board", tostring(why))
    rec(c:canPlaceMoveable(p, sq, nil) and true or false, "server " .. label .. ": board accepted by the vanilla cursor", pos(sq))
    local board = c:placeMoveableInternal(p, sq, c:instanceItem(BOARD), BOARD)
    rec(X.Panel.isPanel(board), "server " .. label .. ": board hung", pos(sq))
    if not board or not asq then rec(false, "server " .. label .. ": free square for the inverter"); return end
    local inv, invObj = placeInverter(p, asq)
    if not inv then rec(false, "server " .. label .. ": inverter placed", pos(asq)); return end
    rec(X.Panels.link(p, board, invObj), "server " .. label .. ": board linked with wire", pos(asq))
    return X.Panel.recordAt(sq), inv
end

local function roomRect(def, want)
    local rooms = def:getRooms()
    for i = 0, rooms:size() - 1 do
        local r = rooms:get(i)
        if want(r:getZ()) then return r, r:getRects():get(0) end
    end
end

local function nearestVanillaCellar()
    local px, py = S.player:getX(), S.player:getY()
    local list = getWorld():getMetaGrid():getBuildings()
    local best, bestD
    for i = 0, list:size() - 1 do
        local def = list:get(i)
        if def:getMinLevel() < 0 and not def:isUserDefined() then
            local d = (def:getX() - px) ^ 2 + (def:getY() - py) ^ 2
            if not bestD or d < bestD then best, bestD = def, d end
        end
    end
    return best
end

local function vanillaScene()
    local def = S.vdef
    local room, rect = roomRect(def, function(z) return z < 0 end)
    local bz = room:getZ()
    info("server vanilla: cellar", string.format("b:%d,%d levels %d..%d room %s z=%d", def:getX(), def:getY(),
        def:getMinLevel(), def:getMaxLevel(), tostring(room:getName()), bz))
    local cx, cy = rect:getX(), rect:getY()
    local site = X.Sites.at(cx, cy, bz)
    local above
    for y = rect:getY(), rect:getY2() - 1 do
        for x = rect:getX(), rect:getX2() - 1 do above = above or X.Sites.at(x, y, 0) end
    end
    rec(site ~= nil and above ~= nil and X.Sites.same(site, above), "server vanilla: the cellar counts with the house over it",
        (site and X.Sites.key(site) or "nil") .. " / " .. (above and X.Sites.key(above) or "nil"))
    local c, boardSq = cursor()
    for y = rect:getY(), rect:getY2() - 1 do
        for x = rect:getX(), rect:getX2() - 1 do
            local sq = at(x, y, bz)
            -- a square the vanilla cursor accepts (a shelf or crate on it blocks placement)
            if not boardSq and sq and freeOfWallObjects(sq) and c:getWallForFacing(sq, "S")
                and c:canPlaceMoveable(S.player, sq, nil) then boardSq = sq end
        end
    end
    if not boardSq then rec(false, "server vanilla: a cellar square against a north wall"); return end
    local asq = freeSquare(boardSq:getX(), boardSq:getY(), bz, function(sq)
        return sq ~= boardSq and X.Sites.at(sq:getX(), sq:getY(), bz) ~= nil
    end)
    local r, inv = hangAndLink("vanilla", boardSq, asq)
    if not r then return end
    local key = site and X.Sites.key(site)
    rec(key ~= nil and X.Data.ownerOf(key) == tostring(inv.id), "server vanilla: the board connects the house", key)
    rec(X.Points.servedAt(cx, cy, bz), "server vanilla: the cellar is served", cx .. "," .. cy .. "," .. bz)
    local gx, gy
    X.Sites.eachSquare(above, function(x, y, z) if not gx and z == 0 then gx, gy = x, y end end)
    rec(gx ~= nil and X.Points.servedAt(gx, gy, 0), "server vanilla: the ground floor is served", tostring(gx) .. "," .. tostring(gy))
    -- another cellar square, free, for the client's D-62 verdict
    local other = freeSquare(cx, cy, bz, function(sq) return sq ~= boardSq and sq ~= asq and X.Sites.at(sq:getX(), sq:getY(), bz) ~= nil end)
    S.scene.vanilla = { key = key, board = xyz(boardSq), cellar = { x = cx, y = cy, z = bz },
        ground = gx and { x = gx, y = gy, z = 0 } or nil, other = other and xyz(other) or nil }
end

-- Basement Building reads its builder from aparosa_BD_Check.actor(): getSpecificPlayer(0), nil on
-- a dedicated server, unless its own dig action names the character (aparosa_BD_Entity.asBuilder).
local function asBuilder(fn, ...)
    return aparosa_BD_Entity.asBuilder(S.player, fn, ...)
end

local function openGround(cx, cy)
    for r = 6, 30, 3 do
        for _, d in ipairs({ { r, 0 }, { -r, 0 }, { 0, r }, { 0, -r }, { r, r }, { -r, -r }, { r, -r }, { -r, r } }) do
            local x0, y0, ok = cx + d[1], cy + d[2], true
            for y = y0 - 3, y0 + 3 do
                for x = x0 - 3, x0 + 3 do
                    local sq = at(x, y, 0)
                    if not sq or sq:getRoom() or not sq:isOutside() or sq:getObjects():size() ~= 1
                        or X.Sites.at(x, y, 0) or getWorld():getMetaGrid():getBuildingAt(x, y, 0) then ok = false end
                end
            end
            if ok then
                local hok, hwhy = asBuilder(aparosa_BD_Basic.validateHole, x0, y0, 0)
                if hok then return x0, y0 end
                S.holeWhy = tostring(hwhy) .. " at " .. x0 .. "," .. y0
            end
        end
    end
end

local function moddedScene()
    local x, y = openGround(math.floor(S.player:getX()), math.floor(S.player:getY()))
    if not x then rec(false, "server modded: open ground the mod accepts for a hole", S.holeWhy or "no open ground"); return end
    local ok, why = asBuilder(aparosa_BD_Basic.applyHole, x, y, 0, S.player)
    rec(ok == true, "server modded: the mod dug a cellar", x .. "," .. y .. ",-1 " .. tostring(why or ""))
    if not ok then return end
    local site = X.Sites.at(x, y, -1)
    rec(site ~= nil and site.kind == "building", "server modded: the cellar is a building site", site and X.Sites.key(site))
    local sq = at(x, y, -1)
    local asq = freeSquare(x, y, 0, function(s) return s:isOutside() and not (s:getX() == x and s:getY() == y) end)
    local r, inv = hangAndLink("modded", sq, asq)
    if not r then return end
    local key = site and X.Sites.key(site)
    rec(key ~= nil and X.Data.ownerOf(key) == tostring(inv.id), "server modded: the board connects the cellar", key)
    rec(X.Points.servedAt(x, y, -1), "server modded: the cellar is served")
    S.scene.modded = { key = key, board = { x = x, y = y, z = -1 } }
end

-- A map house near the player with no cellar, and a ground room square the mod accepts.
local function houseForAHole()
    local px, py = S.player:getX(), S.player:getY()
    local list = getWorld():getMetaGrid():getBuildings()
    local tried = 0
    for i = 0, list:size() - 1 do
        local def = list:get(i)
        if not def:isUserDefined() and def:getMinLevel() == 0 and #X.Buildings.group(def) == 1
            and (def:getX() - px) ^ 2 + (def:getY() - py) ^ 2 < 35 * 35 and tried < 6 then
            tried = tried + 1
            local rooms = def:getRooms()
            for j = 0, rooms:size() - 1 do
                local r = rooms:get(j)
                local rr = r:getZ() == 0 and r:getRects():get(0)
                if rr then
                    for y = rr:getY() + 1, rr:getY2() - 2 do
                        for x = rr:getX() + 1, rr:getX2() - 2 do
                            local sq = at(x, y, 0)
                            if sq and sq:getObjects():size() == 1 then
                                local ok, why = asBuilder(aparosa_BD_Basic.validateHole, x, y, 0)
                                if ok then return def, x, y end
                                S.houseHoleWhy = tostring(why) .. " at " .. x .. "," .. y
                            end
                        end
                    end
                end
            end
        end
    end
end

local function moddedUnderAHouse()
    local def, x, y = houseForAHole()
    if not def then rec(false, "server modded house: a room square the mod accepts for a hole", S.houseHoleWhy or "no house"); return end
    local ok, why = asBuilder(aparosa_BD_Basic.applyHole, x, y, 0, S.player)
    rec(ok == true, "server modded house: the mod dug a cellar under a map house", x .. "," .. y .. ",-1 " .. tostring(why or ""))
    if not ok then return end
    local key = X.Buildings.key(def)
    local site = X.Sites.at(x, y, -1)
    rec(site ~= nil and X.Sites.key(site) == key, "server modded house: the cellar counts with the house over it",
        site and (X.Sites.key(site) .. " / " .. key))
    S.scene.house = { key = key, cellar = { x = x, y = y, z = -1 } }
end

function H.server.start(ctx)
    S.ctx = ctx
    local players = ctx.players()
    S.player = players and players[1]
    clearZombies()
    if not S.player then return serverOnly() end
    untouchable(S.player)
    S.errors = getLuaDebuggerErrorCount()
    Events.OnClientCommand.Add(function(module, command, player, args)
        if module == MODULE and command == "checked" then S.checked = args end
    end)
    Events.EveryTenMinutes.Remove(LiveWire.Sim.tick)
    local p = S.player
    p:setPerkLevelDebug(Perks.Electricity, 10)
    p:getInventory():AddItem("Base.Screwdriver")
    p:getInventory():AddItem("Base.Crowbar")   -- Basement Building asks for it to break a built floor
    p:getInventory():AddItem("LiveWire.VoltageTester")
    p:getInventory():AddItems("Base.ElectricWire", 60)
    S.scene = {}
    S.vdef = nearestVanillaCellar()
    if S.vdef then vanillaScene() else rec(false, "server: a map building with a vanilla cellar") end
    info("Basement Building loaded on the server", tostring(aparosa_BD_Basic ~= nil))
    if aparosa_BD_Basic then
        moddedScene()
        moddedUnderAHouse()
    else
        rec(false, "server: Basement Building loaded (aparosa_BD_Basic)")
    end
    S.at = getTimestampMs()
    send("check", S.scene)
    return true
end

function H.server.done(ctx)
    clearZombies()
    if not S.at then return true end
    if S.checked then
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error on the server", getLuaDebuggerErrorCount() - S.errors)
        return true
    end
    if getTimestampMs() - S.at > 240000 then rec(false, "client checks received"); return true end
    return false
end

function H.server.result(ctx)
    local c = S.checked
    if c then info("client", tostring(c.ok) .. " " .. tostring(c.summary)) end
    return { ok = S.ok and (not S.player or (c ~= nil and c.ok)), lines = S.lines,
        summary = "LiveWire Extended D-62 basements server" .. (S.player and " + client" or " only") }
end

-- ---------------------------------------------------------------- client
local C = {}
function H.client.start(ctx)
    C.t0 = getTimestampMs()
    C.errors = getLuaDebuggerErrorCount()
    untouchable(getPlayer())
    getPlayer():getInventory():AddItem("Base.Screwdriver")   -- the cursor asks for the place tool
    Events.OnServerCommand.Add(function(module, command, args)
        if module == MODULE and command == "check" then C.scene, C.at = args, getTimestampMs() end
    end)
    return true
end

local function siteKey(e)
    local s = X.Sites.at(e.x, e.y, e.z)
    return s and X.Sites.key(s)
end

local function powered(e)
    local sq = at(e.x, e.y, e.z)
    return sq ~= nil and X.Points.servedAt(e.x, e.y, e.z) and sq:haveElectricity()
end

local function boardServes(label, e, key)
    local sq = at(e.x, e.y, e.z)
    local rb = sq and X.Panel.recordAt(sq)
    local site = rb and X.Panel.siteOf(rb)
    rec(site ~= nil and X.Sites.key(site) == key, "client " .. label .. ": board record received, serves the site",
        site and X.Sites.key(site))
end

function H.client.done(ctx)
    local now = getTimestampMs()
    if not C.scene then
        if now - C.t0 > 300000 then rec(false, "client: server scene received"); return true end
        return false
    end
    if now - C.at < 5000 then return false end
    local sc, p = C.scene, getPlayer()
    local v = sc.vanilla
    if v then
        rec(siteKey(v.cellar) == v.key, "client vanilla: the cellar is the house's site", siteKey(v.cellar))
        boardServes("vanilla", v.board, v.key)
        rec(powered(v.cellar), "client vanilla: the cellar is served and has power", v.cellar.x .. "," .. v.cellar.y .. "," .. v.cellar.z)
        rec(v.ground ~= nil and powered(v.ground), "client vanilla: the ground floor is served and has power")
        if v.other then
            local ok, why = LiveWire.Placement.checkRules(BOARD, at(v.other.x, v.other.y, v.other.z), p)
            rec(ok == true, "client vanilla: the D-62 rule accepts a cellar square", tostring(why))
        end
    else
        rec(false, "client: vanilla cellar scene received")
    end
    local m = sc.modded
    if m then
        rec(siteKey(m.board) == m.key, "client modded: the dug cellar is a site of its own", siteKey(m.board))
        boardServes("modded", m.board, m.key)
        rec(powered(m.board), "client modded: the dug cellar is served and has power")
    else
        rec(false, "client: Basement Building cellar scene received")
    end
    local h = sc.house
    if h then
        rec(siteKey(h.cellar) == h.key, "client modded house: the cellar dug under a house counts with it", siteKey(h.cellar))
    else
        rec(false, "client: cellar under a house scene received")
    end
    rec(getLuaDebuggerErrorCount() == C.errors, "client: no new Lua errors", getLuaDebuggerErrorCount() - C.errors)
    sendClientCommand(p, MODULE, "checked", { ok = S.ok, summary = #S.lines .. " lines" })
    return true
end

function H.client.result(ctx)
    return { ok = S.ok, summary = "LiveWire Extended D-62 basements client", lines = S.lines }
end
return H
