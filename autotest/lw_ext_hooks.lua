-- LiveWire Extended, in-game scenarios (pzdev, solo). Parameter `case`:
--   building : an inverter placed outside a house with an upper floor, at the edge of
--              its range, so its disc covers only part of the house; connecting the
--              building powers every loaded room square of every floor; disconnecting
--              brings the disc back. Real world, real map buildings, real engine power.
--   zone     : an inverter and a power terminal 11 squares apart, linked with wire; the
--              zone tool previews 2 x 2 blocks reaching beyond the inverter's disc (left
--              open for the final capture); the outdoor squares of the zone get power.
--   keep     : like building, without disconnecting; the scene is written to ModData
--              LWXTestScene for run_ext_removed.py (same save reloaded without the sub-mod).
--   gridlight: public grid on; a room light wired to a breaker goes off when it opens, stays
--              off when the switch is flipped, comes back when it closes; placing a board
--              and wiring need a screwdriver (run with appliances42.json: 42.22 save).
--   relay    : a building whose far side lies beyond the inverter's disc; a terminal
--              placed against its wall and linked to the inverter connects it: every
--              loaded room square gets power.
local H = {}
local S = { lines = {}, ok = true }
local function rec(ok, name, detail)
    if not ok then S.ok = false end
    S.lines[#S.lines + 1] = (ok and "PASS " or "FAIL ") .. name .. " - " .. tostring(detail or "")
end
local function info(name, detail) S.lines[#S.lines + 1] = "INFO " .. name .. " - " .. tostring(detail or "") end

local X = LiveWire.Extended

local function place(sq, n)
    local name = "batman_livewire_01_" .. n
    local props = ISMoveableSpriteProps.new(getSprite(name))
    local obj = props:placeMoveableInternal(S.player, sq, props:instanceItem(name), name)
    if S.suite and obj then S.suite.placed[#S.suite.placed + 1] = obj end
    local m = LiveWire.Marks.get(obj)
    return m and LiveWire.Registry.device(m.id), obj
end

-- Loaded room squares of a building, by floor.
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
    local n, floors = 0, {}
    for _, sq in ipairs(list) do
        floors[sq:getZ()] = true
        if not sq:haveElectricity() then n = n + 1 end
    end
    local fl = {}
    for z in pairs(floors) do fl[#fl + 1] = z end
    table.sort(fl)
    return n, table.concat(fl, ",")
end

-- The nearest house with rooms on floors 0 and 1 (the save's player may stand far from one).
local function findHouse()
    local p = S.player
    local px, py = p:getX(), p:getY()
    local list = getWorld():getMetaGrid():getBuildings()
    local best, bestD
    for i = 0, list:size() - 1 do
        local def = list:get(i)
        local d = (def:getX() + def:getW() / 2 - px) ^ 2 + (def:getY() + def:getH() / 2 - py) ^ 2
        if d < 600 * 600 and (not bestD or d < bestD) then
            local up, ground = false, false
            local rooms = def:getRooms()
            for k = 0, rooms:size() - 1 do
                local z = rooms:get(k):getZ()
                if z >= 1 then up = true end
                if z == 0 then ground = true end
            end
            if up and ground and def:getW() >= 6 and def:getH() >= 6 then best, bestD = def, d end
        end
    end
    return best
end

-- Every room square of every floor of `def` loaded, and its surroundings?
local function loaded(def, margin)
    local cell = getCell()
    for _, c in ipairs({ { def:getX() - margin, def:getY() - margin }, { def:getX2() + margin, def:getY() - margin },
        { def:getX() - margin, def:getY2() + margin }, { def:getX2() + margin, def:getY2() + margin } }) do
        if not cell:getGridSquare(c[1], c[2], 0) then return false end
    end
    return true
end

-- Test scaffolding: the simulation switches off an inverter that has no energy source.
-- The coverage, not the energy balance, is under test: keep the test inverter on.
local function holdPower(inv)
    local orig = LiveWire.Sim.updateAnchor
    LiveWire.Sim.updateAnchor = function(dev, on)
        if dev and dev.id == inv.id then on = true end
        return orig(dev, on)
    end
    inv.state = "on"
    LiveWire.Sim.updateAnchor(inv, true); LiveWire.Registry.grid(inv.grid).powered = true
end

-- A free outdoor ground square at distance R - 2 from the house centre line: the disc
-- reaches only the near part of the house.
local function inverterSquare(def, R)
    local cell = getCell()
    local cy = def:getY() + math.floor(def:getH() / 2)
    for _, dir in ipairs({ -1, 1 }) do
        local x = dir < 0 and def:getX() - (R - 2) or def:getX() + def:getW() - 1 + (R - 2)
        for dy = 0, 6 do
            for _, s in ipairs({ 1, -1 }) do
                local sq = cell:getGridSquare(x, cy + dy * s, 0)
                if sq and sq:isFree(false) and not sq:getRoom() then return sq end
            end
        end
    end
    return nil
end

local START, DONE = {}, {}

local function setupBuilding(def)
    local R = LiveWire.Config.tileRange()
    S.def = def
    info("house", string.format("%d,%d %dx%d", def:getX(), def:getY(), def:getW(), def:getH()))
    local sq = inverterSquare(def, R)
    if not sq then rec(false, "free square for the inverter"); S.phase = "end"; return end
    local inv, obj = place(sq, 12)
    if not inv then rec(false, "inverter placed"); S.phase = "end"; return end
    S.inv, S.obj = inv, obj
    S.grid = LiveWire.Registry.grid(inv.grid)
    holdPower(inv)
    S.squares = roomSquares(def)
    local before, floors = unpowered(S.squares)
    info("before connection", string.format("%d of %d room squares unpowered (floors %s)", before, #S.squares, floors))
    rec(before > 0, "the disc alone leaves part of the house dark", before)
    local ok = X.Connect.connectBuilding(S.player, inv, inv.x, inv.y, inv.z, R, nil)
    rec(ok, "building connected by the authority")
    S.phase, S.at = "connected", getTimestampMs()
end

-- Walk (teleport) to the house first when it is not loaded around the player.
function START.building()
    local def = findHouse()
    if not def then rec(false, "two-floor house within 600 squares"); return true end
    if loaded(def, 24) then setupBuilding(def); return true end
    local p = S.player
    p:setX(def:getX() - 4); p:setY(def:getY() + math.floor(def:getH() / 2))
    p:setLastX(p:getX()); p:setLastY(p:getY())
    S.travel, S.phase, S.at = def, "travel", getTimestampMs()
    return true
end

local function travelled()
    if S.phase ~= "travel" then return true end
    if loaded(S.travel, 24) and getTimestampMs() - S.at > 1500 then
        info("player moved next to the house", string.format("%d ms", getTimestampMs() - S.at))
        local def = S.travel
        S.travel, S.phase = nil, nil
        setupBuilding(def)
        if S.onArrive then S.onArrive() end
        return true
    end
    if getTimestampMs() - S.at > 60000 then rec(false, "house squares loaded after moving"); S.phase = "end" end
    return false
end

function DONE.building()
    if not travelled() then return S.phase == "end" end
    if S.phase == "connected" and getTimestampMs() - S.at > 1500 then
        local after, floors = unpowered(S.squares)
        rec(after == 0, "every loaded room square of every floor powered", string.format("%d unpowered of %d (floors %s)",
            after, #S.squares, floors))
        local key = X.Buildings.key(S.def)
        rec(X.Connect.disconnect(S.player, S.inv, key), "building disconnected")
        S.phase, S.at = "disconnected", getTimestampMs()
        return false
    end
    if S.phase == "disconnected" and getTimestampMs() - S.at > 1500 then
        local back = unpowered(S.squares)
        rec(back > 0, "after disconnection, only the disc stays powered", back)
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase = "end"
    end
    return S.phase == "end" or not S.phase
end

-- ---------------------------------------------------------------- keep
local function saveScene()
    if S.inv and S.def then
        local scene = ModData.getOrCreate("LWXTestScene")
        scene.inv, scene.bx, scene.by = S.inv.id, S.def:getX(), S.def:getY()
    end
end

function START.keep()
    S.onArrive = saveScene
    START.building()
    if S.phase ~= "travel" then saveScene() end
end

function DONE.keep()
    if not travelled() then return S.phase == "end" end
    if S.phase == "connected" and getTimestampMs() - S.at > 1500 then
        local after = unpowered(S.squares)
        rec(after == 0, "every loaded room square powered before saving", after .. "/" .. #S.squares)
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase = "end"
    end
    return S.phase == "end" or not S.phase
end

-- ---------------------------------------------------------------- zone
local function freeGround(x, y)
    local cell = getCell()
    for r = 0, 6 do
        for dy = -r, r do
            for dx = -r, r do
                local sq = cell:getGridSquare(x + dx, y + dy, 0)
                if sq and sq:isFree(false) and not sq:getRoom() and not LiveWire.Marks.firstOnSquare(sq) then return sq end
            end
        end
    end
    return nil
end

function START.zone()
    local R = LiveWire.Config.tileRange()
    local p = S.player
    local asq = freeGround(math.floor(p:getX()) + 2, math.floor(p:getY()))
    if not asq then rec(false, "free ground for the inverter"); return end
    local inv, invObj = place(asq, 12)
    if not inv then rec(false, "inverter placed"); return end
    S.inv, S.grid = inv, LiveWire.Registry.grid(inv.grid)
    holdPower(inv)
    local tsq = freeGround(inv.x + 11, inv.y)
    if not tsq then rec(false, "free ground for the terminal"); return end
    local name = X.Terminal.SHEET .. "_0"
    local props = ISMoveableSpriteProps.new(getSprite(name))
    local term = props:placeMoveableInternal(p, tsq, props:instanceItem(name), name)
    rec(X.Terminal.isTerminal(term), "terminal placed with the furniture cursor code", tsq:getX() .. "," .. tsq:getY())
    p:getInventory():AddItems("Base.ElectricWire", 20)
    if p:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then p:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
    rec(X.Terminals.link(p, term, invObj), "terminal linked with wire")
    S.term = term
    -- 2 x 2 blocks from the terminal's block, away from the inverter.
    local tcx, tcy = X.Zone.chunkOf(tsq:getX(), tsq:getY())
    local dir = tsq:getX() >= inv.x and 1 or -1
    local cx0, cx1 = math.min(tcx, tcx + dir), math.max(tcx, tcx + dir)
    local x0, y0, x1, y1 = cx0 * 8, tcy * 8, cx1 * 8 + 7, tcy * 8 + 15
    S.tool = X.ZoneTool.open(p, term)
    S.tool:setRect(x0 + 1, y0 + 2, x1 - 1, y1 - 3)
    rec(S.tool.valid == true and #S.tool.lit > 0, "preview: allowed, outline drawn", #S.tool.lit .. " outlined squares")
    rec(X.Terminals.setZone(p, term, x0, y0, x1, y1), "zone recorded by the authority")
    S.zone = { x0 = x0, y0 = y0, x1 = x1, y1 = y1 }
    -- E10: the range view outlines the added blocks next to the disc (final capture).
    LiveWire.RangeView.show(inv.id, inv.x, inv.y, inv.z)
    local outlines = LiveWire.RangeView.extraOutlines(inv.id, LiveWire.Registry.anchors[inv.id], inv.z)
    rec(#outlines == 4, "range view outlines the 4 blocks of the zone", #outlines)
    S.R = R
    -- Clean final capture: no character window or console, daylight, the player
    -- standing south of the terminal so that the preview outline is in view.
    if ISCharacterInfoWindow and ISCharacterInfoWindow.instance then ISCharacterInfoWindow.instance:setVisible(false) end
    local console = UIManager.getDebugConsole and UIManager.getDebugConsole()
    if console then console:setVisible(false) end
    getGameTime():setTimeOfDay(13)
    p:setX(tsq:getX() + 0.5); p:setY(tsq:getY() + 3.5)
    S.phase, S.at = "zoned", getTimestampMs()
end

function DONE.zone()
    if S.phase == "zoned" and getTimestampMs() - S.at > 1500 then
        local cell, inv, z = getCell(), S.inv, S.zone
        local far, powered, ext = 0, 0, 0
        for y = z.y0, z.y1 do
            for x = z.x0, z.x1 do
                local sq = cell:getGridSquare(x, y, 0)
                if sq and (x - inv.x) ^ 2 + (y - inv.y) ^ 2 > S.R * S.R then
                    far = far + 1
                    if sq:haveElectricity() then powered = powered + 1 end
                    if sq:getProperties():has(IsoFlagType.exterior) then ext = ext + 1 end
                end
            end
        end
        local exteriorOk = getSandboxOptions():getOptionByName("AllowExteriorGenerator"):getValue()
        info("zone squares beyond the disc", string.format("%d loaded, %d powered, %d exterior, AllowExteriorGenerator=%s",
            far, powered, ext, tostring(exteriorOk)))
        rec(far > 0, "the zone reaches beyond the inverter's disc", far)
        rec(powered == (exteriorOk and far or far - ext), "every square of the zone beyond the disc is powered",
            powered .. "/" .. far)
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase = "end"
    end
    return S.phase == "end" or not S.phase
end

-- ---------------------------------------------------------------- relay
local function findWide()
    local p = S.player
    local px, py = p:getX(), p:getY()
    local list = getWorld():getMetaGrid():getBuildings()
    local best, bestD
    for i = 0, list:size() - 1 do
        local def = list:get(i)
        local d = (def:getX() + def:getW() / 2 - px) ^ 2 + (def:getY() + def:getH() / 2 - py) ^ 2
        if d < 50 * 50 and def:getW() >= 10 and def:getRooms():size() > 0 and (not bestD or d < bestD) then
            best, bestD = def, d
        end
    end
    return best
end

function START.relay()
    local R = LiveWire.Config.tileRange()
    local def = findWide()
    if not def then rec(false, "wide building near the player"); return end
    S.def = def
    info("building", string.format("%d,%d %dx%d", def:getX(), def:getY(), def:getW(), def:getH()))
    local cy = def:getY() + math.floor(def:getH() / 2)
    local tsq = freeGround(def:getX() - 1, cy)
    local asq = tsq and freeGround(tsq:getX() - 11, tsq:getY())
    if not tsq or not asq then rec(false, "free ground for the terminal and the inverter"); return end
    local inv, invObj = place(asq, 12)
    if not inv then rec(false, "inverter placed"); return end
    S.inv, S.grid = inv, LiveWire.Registry.grid(inv.grid)
    holdPower(inv)
    local name = X.Terminal.SHEET .. "_0"
    local props = ISMoveableSpriteProps.new(getSprite(name))
    local term = props:placeMoveableInternal(S.player, tsq, props:instanceItem(name), name)
    S.player:getInventory():AddItems("Base.ElectricWire", 20)
    if S.player:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then S.player:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
    rec(X.Terminals.link(S.player, term, invObj), "terminal linked with wire")
    S.squares = roomSquares(def)
    local before = unpowered(S.squares)
    info("before the relay", string.format("%d of %d room squares unpowered", before, #S.squares))
    rec(before > 0, "the inverter's disc alone leaves the building partly dark", before)
    rec(X.Terminals.connectBuilding(S.player, term), "building connected through the terminal")
    S.phase, S.at = "relayed", getTimestampMs()
end

function DONE.relay()
    if S.phase == "relayed" and getTimestampMs() - S.at > 1500 then
        local after, floors = unpowered(S.squares)
        rec(after == 0, "every loaded room square of the distant building powered",
            string.format("%d unpowered of %d (floors %s)", after, #S.squares, floors))
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase = "end"
    end
    return S.phase == "end" or not S.phase
end

-- ---------------------------------------------------------------- board (E15, E16)
-- A breaker board on a north wall near an inverter: linked with wire, breakers
-- installed by the authority and by the real timed action, one removed.
local function boardSquare(inv)
    local cell = getCell()
    local best, bestD
    for dy = -12, 12 do
        for dx = -12, 12 do
            local sq = cell:getGridSquare(inv.x + dx, inv.y + dy, inv.z)
            if sq and sq:getRoom() and sq:getWall(true) and sq:isFree(false) and not X.Panel.onSquare(sq) then
                local d = dx * dx + dy * dy
                if not bestD or d < bestD then best, bestD = sq, d end
            end
        end
    end
    return best
end

local function setupBoard()
    local p = S.player
    local asq = freeGround(math.floor(p:getX()) + 2, math.floor(p:getY()))
    if not asq then rec(false, "free ground for the inverter"); return end
    local inv, invObj = place(asq, 12)
    if not inv then rec(false, "inverter placed"); return end
    S.inv = inv
    holdPower(inv)
    local bsq = boardSquare(inv)
    if not bsq then rec(false, "indoor square against a north wall"); return end
    local index = S.boardIndex or 8
    local name = X.Terminal.SHEET .. "_" .. index
    local props = ISMoveableSpriteProps.new(getSprite(name))
    local board = props:placeMoveableInternal(p, bsq, props:instanceItem(name), name)
    rec(X.Panel.isPanel(board) and X.Panel.size(board) == X.Panel.SIZES[index], "board placed on the north wall",
        bsq:getX() .. "," .. bsq:getY())
    p:getInventory():AddItems("Base.ElectricWire", 20)
    if p:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then p:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
    p:getInventory():AddItem("Base.Screwdriver")
    rec(X.Panels.link(p, board, invObj), "board linked with wire")
    local r = X.Panel.recordAt(bsq)
    rec(r ~= nil and r.inv == inv.id and r.size == X.Panel.SIZES[index], "board record", r and (tostring(r.inv) .. " " .. tostring(r.size)))
    local e, served = X.Data.entry(inv.id), 0
    for _, a in pairs(e and e.areas or {}) do if a.via then served = served + 1 end end
    rec(served == 1, "the linked board connects its building (D-44)", served)
    for _, t in ipairs({ "LiveWire.Breaker15", "LiveWire.Breaker30", "LiveWire.Breaker20" }) do p:getInventory():AddItem(t) end
    rec(X.Panels.installBreaker(p, board, "LiveWire.Breaker15"), "15 A breaker installed by the authority")
    rec(X.Panels.installBreaker(p, board, "LiveWire.Breaker30"), "30 A breaker installed")
    rec(X.Breakers.usedModules(r) == 2, "two modules used", X.Breakers.usedModules(r))
    rec(p:getInventory():getCountTypeRecurse("LiveWire.Breaker15") == 0, "breaker item consumed")
    rec(X.Panels.removeBreaker(p, board, 1), "15 A breaker removed")
    rec(p:getInventory():getCountTypeRecurse("LiveWire.Breaker15") == 1, "breaker item given back")
    S.board, S.record, S.bsq = board, r, bsq
    return board, r, bsq
end

function START.board()
    local board, r, bsq = setupBoard()
    if not board then return end
    local p = S.player
    -- The real timed action, as the context menu queues it.
    p:setX(bsq:getX() + 0.5); p:setY(bsq:getY() + 1.5); p:setLastX(p:getX()); p:setLastY(p:getY())
    getGameTime():setTimeOfDay(13)
    ISTimedActionQueue.add(LWXBreakerAction:new(p, board, "LiveWire.Breaker20", nil, nil))
    S.phase, S.at = "action", getTimestampMs()
end

-- ---------------------------------------------------------------- points (E17)
-- A two-tile fridge in the board's building: cut while unwired (D-37), back once wired,
-- cut again when its breaker is switched off.
local function fridgePieces(bsq)
    local cell, def = getCell(), getWorld():getMetaGrid():getBuildingAt(bsq:getX(), bsq:getY(), bsq:getZ())
    if not def then return nil end
    for dy = -8, 8 do
        for dx = -8, 8 do
            local a = cell:getGridSquare(bsq:getX() + dx, bsq:getY() + dy, bsq:getZ())
            local b = cell:getGridSquare(bsq:getX() + dx + 1, bsq:getY() + dy, bsq:getZ())
            if a and b and a:getRoom() and b:getRoom() and a:isFree(false) and b:isFree(false)
                and getWorld():getMetaGrid():getBuildingAt(a:getX(), a:getY(), a:getZ()) == def
                and not X.Panel.onSquare(a) and not X.Panel.onSquare(b) then
                local g = getSprite("appliances_refrigeration_01_18"):getSpriteGrid()
                local pieces = {}
                for gx = 0, 1 do
                    local piece = g:getSprite(gx, 0)
                    local sq = gx == 0 and a or b
                    local props = ISMoveableSpriteProps.new(piece)
                    props:placeMoveableInternal(S.player, sq, props:instanceItem(piece:getName()), piece:getName())
                    local objs = sq:getObjects()
                    for i = 0, objs:size() - 1 do
                        local spr = objs:get(i):getSprite()
                        if spr and spr:getName() == piece:getName() then pieces[#pieces + 1] = objs:get(i) end
                    end
                end
                return pieces
            end
        end
    end
    return nil
end

local function cooling(pieces)
    local n = 0
    for _, o in ipairs(pieces) do if o:getContainerByType("fridge") then n = n + 1 end end
    return n
end

function START.points()
    local board, r, bsq = setupBoard()
    if not board then return end
    rec(X.Panels.installBreaker(S.player, board, "LiveWire.Breaker20"), "20 A breaker in module 1")
    rec(X.Points.regionOf(r) ~= nil, "the board serves its building", tostring(X.Points.regionOf(r)))
    local pieces = fridgePieces(bsq)
    if not pieces or #pieces ~= 2 then rec(false, "two-tile fridge placed in the building", pieces and #pieces); return end
    S.pieces = pieces
    LiveWire.Demand.invalidate(S.inv.id)
    X.Points.regionsChanged()
    S.phase, S.at = "unwired", getTimestampMs()
end

function DONE.points()
    local now = getTimestampMs()
    if S.phase == "unwired" then
        if cooling(S.pieces) == 0 or now - S.at > 30000 then
            rec(cooling(S.pieces) == 0, "unwired fridge in a served building has no current (D-37, both pieces)",
                cooling(S.pieces) .. " pieces cooling after " .. (now - S.at) .. " ms")
            S.player:getInventory():AddItems("Base.ElectricWire", 10)
            if S.player:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then S.player:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
            rec(X.Points.connect(S.player, S.pieces[2], S.board, 1), "fridge wired to module 1 from its second piece")
            rec(cooling(S.pieces) == 2, "wired fridge cools again (both pieces)", cooling(S.pieces))
            rec(X.Panels.setBreaker(S.player, S.board, 1, true), "module 1 switched off")
            rec(cooling(S.pieces) == 0, "open breaker cuts the fridge", cooling(S.pieces))
            rec(X.Panels.setBreaker(S.player, S.board, 1, false), "module 1 switched on")
            rec(cooling(S.pieces) == 2, "closed breaker restores the fridge", cooling(S.pieces))
            rec(X.Points.disconnect(S.player, S.pieces[1]), "fridge unwired")
            rec(cooling(S.pieces) == 0, "unwired again: no current", cooling(S.pieces))
            rec(X.Panels.unlink(S.player, S.board), "board unlinked")
            S.phase, S.at = "released", now
        end
        return false
    end
    if S.phase == "released" then
        if cooling(S.pieces) == 2 or now - S.at > 30000 then
            rec(cooling(S.pieces) == 2, "without a board the fridge is powered as before",
                cooling(S.pieces) .. " after " .. (now - S.at) .. " ms")
            rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
            S.phase = "end"
            return true
        end
        return false
    end
    return true
end

-- ---------------------------------------------------------------- gridlight
-- Public grid ON (vanilla power still running): the lights of a room wired to a breaker
-- go off when the breaker opens, stay off when the player flips the wall switch, and
-- come back when it closes. Also: placing a board needs a screwdriver (tile PlaceTool).
local function lightRoomNear(bsq)
    local cell = getCell()
    local def = getWorld():getMetaGrid():getBuildingAt(bsq:getX(), bsq:getY(), bsq:getZ())
    for r = 0, 12 do
        for dy = -r, r do
            for dx = -r, r do
                local sq = cell:getGridSquare(bsq:getX() + dx, bsq:getY() + dy, bsq:getZ())
                local objs = sq and sq:getRoom() and sq:getObjects()
                for i = 0, objs and objs:size() - 1 or -1 do
                    local o = objs:get(i)
                    if instanceof(o, "IsoLightSwitch") and not o:getCanBeModified()
                        and getWorld():getMetaGrid():getBuildingAt(sq:getX(), sq:getY(), sq:getZ()) == def then
                        return o
                    end
                end
            end
        end
    end
end

function START.gridlight()
    getSandboxOptions():getOptionByName("ElecShutModifier"):setValue(9999)
    local board, r, bsq = setupBoard()
    if not board then return end
    local p = S.player
    rec(bsq:hasGridPower(), "public grid powers the board's building", tostring(bsq:hasGridPower()))
    -- placing: the board tile asks for a screwdriver, no level
    local name = X.Terminal.SHEET .. "_8"
    local props = ISMoveableSpriteProps.new(getSprite(name))
    rec(props.placeTool == "Electrician" and props.pickUpLevel == 0, "board tile: PlaceTool Electrician, no level",
        tostring(props.placeTool) .. " " .. tostring(props.pickUpLevel))
    rec(props:hasTool(p, "place") ~= nil, "screwdriver carried: placing allowed")
    local inv = p:getInventory()
    local drivers = {}
    local items = inv:getItems()
    for i = items:size() - 1, 0, -1 do
        local it = items:get(i)
        if it:hasTag(ItemTag.SCREWDRIVER) then drivers[#drivers + 1] = it; inv:Remove(it) end
    end
    rec(props:hasTool(p, "place") == nil, "no screwdriver: placing refused")
    local sw = lightRoomNear(bsq)
    if not sw then rec(false, "a room with a wall switch in the building"); return end
    rec(not X.Points.connect(p, sw, board, 3), "no screwdriver: wiring refused")
    for _, it in ipairs(drivers) do inv:AddItem(it) end
    rec(X.Panels.installBreaker(p, board, "LiveWire.Breaker20"), "20 A breaker in module 1")
    S.sw = sw
    info("switch", sw:getSquare():getX() .. "," .. sw:getSquare():getY() .. " room " .. tostring(sw:getSquare():getRoom():getName()))
    inv:AddItems("Base.ElectricWire", 10)
    rec(X.Points.connect(p, sw, board, 1), "room light wired to module 1")
    sw:setActive(true, false, true)
    LiveWire.API.applyCircuits(sw)
    rec(sw:isActivated(), "wired light switched on under the public grid", tostring(sw:isActivated()))
    rec(X.Panels.setBreaker(p, board, 1, true), "module 1 switched off")
    rec(not sw:isActivated(), "open breaker turns the room light off", tostring(sw:isActivated()))
    sw:setActive(true)   -- the player flips the switch while the breaker is open
    info("after flip", tostring(sw:isActivated()))
    S.phase, S.at = "flipped", getTimestampMs()
end

function DONE.gridlight()
    if S.phase ~= "flipped" then return true end
    local now = getTimestampMs()
    if now - S.at < 3000 then return false end
    rec(not S.sw:isActivated(), "flipped switch is cut again while the breaker is open", tostring(S.sw:isActivated()))
    rec(X.Panels.setBreaker(S.player, S.board, 1, false), "module 1 switched on")
    rec(S.sw:isActivated(), "closed breaker restores the light", tostring(S.sw:isActivated()))
    rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
    S.phase = "end"
    return true
end

-- ---------------------------------------------------------------- tint
-- The real board window tints the room light of its building: red unwired, green once wired
-- to this board, blue with its breaker open; a second board of the same building sees it
-- grey; closing the window removes the tint. Each step waits for the window's next frames.
local function tintOf(o, idx)
    if not o:isHighlighted(idx) then return "none" end
    local c = o:getHighlightColor(idx)
    for kind, v in pairs(X.BoardTint.COLORS) do
        if math.abs(c:getR() - v[1]) < 0.01 and math.abs(c:getG() - v[2]) < 0.01 and math.abs(c:getB() - v[3]) < 0.01 then
            return kind
        end
    end
    return "other colour"
end

function START.tint()
    local board, r, bsq = setupBoard()
    if not board then return end
    local p = S.player
    rec(X.Points.regionOf(r) ~= nil, "the board serves its building", tostring(X.Points.regionOf(r)))
    rec(X.Panels.installBreaker(p, board, "LiveWire.Breaker20"), "20 A breaker in module 1")
    local sw = lightRoomNear(bsq)
    if not sw then rec(false, "a room with a wall switch in the building"); return end
    S.sw, S.idx = sw, p:getPlayerNum()
    p:setX(bsq:getX() + 0.5); p:setY(bsq:getY() + 1.5); p:setLastX(p:getX()); p:setLastY(p:getY())
    S.win = X.BoardWindow.open(p, board)
    S.phase, S.at = "red", getTimestampMs()
end

function DONE.tint()
    local now = getTimestampMs()
    if now - S.at < 1000 then return false end
    local p, sw = S.player, S.sw
    if S.phase == "red" then
        rec(tintOf(sw, S.idx) == "unwired", "unwired room light tinted red", tintOf(sw, S.idx))
        p:getInventory():AddItems("Base.ElectricWire", 10)
        rec(X.Points.connect(p, sw, S.board, 1), "room light wired to module 1")
        S.phase, S.at = "green", now
    elseif S.phase == "green" then
        rec(tintOf(sw, S.idx) == "on", "wired to this board: green", tintOf(sw, S.idx))
        rec(X.Panels.setBreaker(p, S.board, 1, true), "module 1 switched off")
        S.phase, S.at = "blue", now
    elseif S.phase == "blue" then
        rec(tintOf(sw, S.idx) == "off", "breaker open: blue", tintOf(sw, S.idx))
        S.win:close()
        S.phase, S.at = "closed", now
    elseif S.phase == "closed" then
        rec(tintOf(sw, S.idx) == "none", "closing the window removes the tint", tintOf(sw, S.idx))
        -- a second board in the same building sees the light grey
        local cell, b2 = getCell(), nil
        for dx = -12, 12 do
            local sq = cell:getGridSquare(S.bsq:getX() + dx, S.bsq:getY(), S.bsq:getZ())
            if sq and sq ~= S.bsq and sq:getRoom() and sq:getWall(true) and sq:isFree(false) and not X.Panel.onSquare(sq)
                and getWorld():getMetaGrid():getBuildingAt(sq:getX(), sq:getY(), sq:getZ())
                    == getWorld():getMetaGrid():getBuildingAt(S.bsq:getX(), S.bsq:getY(), S.bsq:getZ()) then
                local name = X.Terminal.SHEET .. "_8"
                local props = ISMoveableSpriteProps.new(getSprite(name))
                b2 = props:placeMoveableInternal(p, sq, props:instanceItem(name), name)
                break
            end
        end
        if not b2 then
            info("second board", "no free north wall in the same building: grey case not checked")
            rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
            S.phase = "end"
            return true
        end
        local invObj
        local objs = getCell():getGridSquare(S.inv.x, S.inv.y, S.inv.z):getObjects()
        for i = 0, objs:size() - 1 do
            local m = LiveWire.Marks.get(objs:get(i))
            if m and m.id == S.inv.id then invObj = objs:get(i) end
        end
        rec(invObj ~= nil and X.Panels.link(p, b2, invObj), "second board linked in the same building")
        S.win = X.BoardWindow.open(p, b2)
        S.phase, S.at = "grey", now
    elseif S.phase == "grey" then
        rec(tintOf(sw, S.idx) == "other", "light wired to the first board: grey from the second", tintOf(sw, S.idx))
        S.win:close()
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase = "end"
        return true
    end
    return false
end

function DONE.board()
    if S.phase ~= "action" then return true end
    local slot = X.Breakers.slotAt(S.record, 1)
    if slot or getTimestampMs() - S.at > 20000 then
        rec(slot ~= nil and slot.amps == 20, "20 A breaker installed by the timed action in the free module 1",
            slot and slot.type)
        local console = UIManager.getDebugConsole and UIManager.getDebugConsole()
        if console then console:setVisible(false) end
        if ISCharacterInfoWindow and ISCharacterInfoWindow.instance then ISCharacterInfoWindow.instance:setVisible(false) end
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase = "end"
        return true
    end
    return false
end

-- ---------------------------------------------------------------- protection (E18)
-- A switched-on stove (2000-3000 W) wired to a 15 A breaker (1800 W): Live Wire
-- measures it, the breaker trips on its own and the stove stops; moved to the
-- 30 A breaker (3600 W) and reset, it runs without tripping.
local function freeRoomSquare(bsq)
    local cell = getCell()
    local def = getWorld():getMetaGrid():getBuildingAt(bsq:getX(), bsq:getY(), bsq:getZ())
    for r = 1, 8 do
        for dy = -r, r do
            for dx = -r, r do
                local sq = cell:getGridSquare(bsq:getX() + dx, bsq:getY() + dy, bsq:getZ())
                if sq and sq:getRoom() and sq:isFree(false) and not X.Panel.onSquare(sq)
                    and getWorld():getMetaGrid():getBuildingAt(sq:getX(), sq:getY(), sq:getZ()) == def then
                    return sq
                end
            end
        end
    end
end

function START.protection()
    -- Public grid off: Live Wire only bills appliances the grid does not power (I21 tests).
    getSandboxOptions():getOptionByName("ElecShutModifier"):setValue(0)
    -- Realistic draws (profile 1: stove 3000 W). The default profile copies the engine
    -- values (stove 90 W), with which a breaker almost never trips.
    getSandboxOptions():getOptionByName("LiveWire.ConsumptionProfile"):setValue(1)
    local board, r, bsq = setupBoard()
    if not board then return end
    S.player:getInventory():AddItem("LiveWire.Breaker15")
    rec(X.Panels.installBreaker(S.player, board, "LiveWire.Breaker15"), "15 A breaker in module 1")
    local sq = freeRoomSquare(bsq)
    if not sq then rec(false, "free room square for the stove"); return end
    local stove = IsoStove.new(getCell(), sq, getSprite("appliances_cooking_01_0"))
    stove:setContainer(ItemContainer.new("stove", sq, stove))
    sq:transmitAddObjectToSquare(stove, -1)
    S.player:getInventory():AddItems("Base.ElectricWire", 10)
    if S.player:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then S.player:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
    rec(X.Points.connect(S.player, stove, board, 1), "stove wired to the 15 A breaker")
    stove:setActivated(true)
    S.stove = stove
    LiveWire.Demand.invalidate(S.inv.id)
    S.phase, S.at = "measure15", getTimestampMs()
end

local function measured()
    if not LiveWire.Demand.ready(S.inv) then
        LiveWire.Demand.measure(S.inv, true)
        return false
    end
    LiveWire.Demand.measure(S.inv, true)
    return true
end

function DONE.protection()
    local now = getTimestampMs()
    if S.phase == "measure15" then
        if not measured() and now - S.at < 30000 then return false end
        local load = X.Protection.loads()[X.Points.point(X.Adapters.identity(S.stove)).board .. "#1"] or 0
        local listed = false
        for _, o in ipairs((LiveWire.Demand.inventories[S.inv.id] or {}).objects or {}) do
            if o == S.stove then listed = true end
        end
        info("stove in Live Wire's inventory", string.format("%s, grid powered=%s, square powered=%s, watts=%s",
            tostring(listed), tostring(ItemContainer.isObjectPowered(S.stove, false)),
            tostring(S.stove:getSquare():haveElectricity()), tostring(LiveWire.Consumption.watts(S.stove))))
        info("measured load of module 1", math.floor(load + 0.5) .. " W, rating 1800 W")
        X.Protection.check()
        local slot = X.Breakers.slotAt(S.record, 1)
        rec(load > 1800 and slot.tripped == true, "15 A breaker tripped on its own", tostring(slot.tripped))
        rec(not S.stove:Activated(), "the stove stopped", tostring(S.stove:Activated()))
        rec(X.Points.disconnect(S.player, S.stove), "stove unwired")
        rec(X.Points.connect(S.player, S.stove, S.board, 2), "stove wired to the 30 A breaker (3600 W)")
        rec(X.Panels.setBreaker(S.player, S.board, 1, false) and not slot.tripped, "15 A breaker reset on the board")
        S.stove:setActivated(true)
        LiveWire.Demand.invalidate(S.inv.id)
        S.phase, S.at = "measure30", now
        return false
    end
    if S.phase == "measure30" then
        if not measured() and now - S.at < 30000 then return false end
        X.Protection.check()
        local slot = X.Breakers.slotAt(S.record, 2)
        rec(slot.tripped == false and S.stove:Activated(), "stove runs on the 30 A breaker",
            tostring(slot.tripped) .. "/" .. tostring(S.stove:Activated()))
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase = "end"
        return true
    end
    return true
end

-- ---------------------------------------------------------------- window (E19)
-- The board window with a wired fridge: label written by the real action (pencil),
-- "Locate" lights the fridge, final capture with the window open.
function START.window()
    getSandboxOptions():getOptionByName("ElecShutModifier"):setValue(0)
    local board, r, bsq = setupBoard()
    if not board then return end
    S.player:getInventory():AddItem("LiveWire.Breaker20")
    rec(X.Panels.installBreaker(S.player, board, "LiveWire.Breaker20"), "20 A breaker in module 1")
    local pieces = fridgePieces(bsq)
    if not pieces or #pieces ~= 2 then rec(false, "two-tile fridge placed", pieces and #pieces); return end
    S.pieces = pieces
    S.player:getInventory():AddItems("Base.ElectricWire", 10)
    if S.player:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then S.player:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
    rec(X.Points.connect(S.player, pieces[1], board, 1), "fridge wired to module 1")
    S.player:getInventory():AddItem("Base.Pencil")
    S.player:setX(bsq:getX() + 0.5); S.player:setY(bsq:getY() + 1.5)
    S.player:setLastX(S.player:getX()); S.player:setLastY(S.player:getY())
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, board, nil, 1, "label", "  Kitchen\tfridge  "))
    S.phase, S.at = "label", getTimestampMs()
end

function DONE.window()
    local now = getTimestampMs()
    if S.phase == "label" then
        local slot = X.Breakers.slotAt(S.record, 1)
        if slot.label == "" and now - S.at < 20000 then return false end
        rec(slot.label == "Kitchen fridge", "label written with a pencil and cleaned by the server", slot.label)
        LiveWire.Demand.invalidate(S.inv.id)
        S.phase, S.at = "measure", now
        return false
    end
    if S.phase == "measure" then
        if not LiveWire.Demand.ready(S.inv) and now - S.at < 30000 then LiveWire.Demand.measure(S.inv, true); return false end
        LiveWire.Demand.measure(S.inv, true)
        X.Protection.check()
        local slot = X.Breakers.slotAt(S.record, 1)
        rec((slot.load or 0) > 0, "load of module 1 published for the window", tostring(slot.load) .. " W")
        rec(slot.meter ~= nil, "energy meter started on module 1 (E24)", slot.meter and string.format("%.3f kWh", slot.meter.kwh))
        local lines = LiveWire.API.softwareLines(S.inv.id)
        rec(#lines >= 2, "inverter software, House tab: one meter line per breaker", lines[1])
        local win = X.BoardWindow.open(S.player, S.board)
        win:prerender()
        -- module 1 (the fridge's breaker): click its body, not its lever
        local mx, my = win:moduleRect(1)
        win:onMouseDown((mx + 10) * win.lwK, (my + 90) * win.lwK)
        win:prerender()
        rec(win.selected == 1 and win.btn.locate:isVisible(), "clicking module 1 selects its breaker", tostring(win.selected))
        local empty = nil
        for pos = 1, S.record.size do if not X.Breakers.slotAt(S.record, pos) then empty = pos; break end end
        local menu = empty and win:installMenu(empty)
        rec(menu ~= nil and menu.numOptions >= 4, "an empty module offers the breakers to install there", empty)
        if menu then menu:setVisible(false) end
        win:onLocate()
        rec(#win.lit == 2 and S.pieces[1]:isHighlighted(), "Locate lights both pieces of the fridge", #win.lit)
        S.win = win
        local console = UIManager.getDebugConsole and UIManager.getDebugConsole()
        if console then console:setVisible(false) end
        if ISCharacterInfoWindow and ISCharacterInfoWindow.instance then ISCharacterInfoWindow.instance:setVisible(false) end
        getGameTime():setTimeOfDay(13)
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase, S.at = "shot", now
        return false
    end
    if S.phase == "shot" then return now - S.at > 1500 end
    return true
end

-- ---------------------------------------------------------------- mtir (E20)
-- My Tailor Is Rich loaded with Live Wire and LiveWire Extended: the electric sewing
-- machine in a served building has no current while unwired, gets it once wired, loses
-- it when its breaker is switched off (MTIR.getSewingMachineProblem, the mod's own test).
function START.mtir()
    if not MTIR or not MTIR.getSewingMachineProblem then rec(false, "My Tailor Is Rich loaded"); return end
    local board, r, bsq = setupBoard()
    if not board then return end
    S.player:getInventory():AddItem("LiveWire.Breaker15")
    rec(X.Panels.installBreaker(S.player, board, "LiveWire.Breaker15"), "15 A breaker in module 1")
    local sq = freeRoomSquare(bsq)
    if not sq then rec(false, "free room square for the machine"); return end
    local name = "mtir_sewing_01_0"
    local props = ISMoveableSpriteProps.new(getSprite(name))
    local m = props:placeMoveableInternal(S.player, sq, props:instanceItem(name), name)
    rec(m ~= nil and MTIR.getMachineKindName(m) == "electric", "electric sewing machine placed in the building",
        sq:getX() .. "," .. sq:getY())
    if not m then return end
    rec(sq:haveElectricity(), "its square has current from the inverter")
    local problem = MTIR.getSewingMachineProblem(nil, m)
    rec(problem == "IGUI_MTIR_Machine_NoPower", "unwired in a served building: MTIR reports no power", tostring(problem))
    S.player:getInventory():AddItems("Base.ElectricWire", 10)
    if S.player:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then S.player:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
    rec(X.Points.connect(S.player, m, board, 1), "machine wired to module 1")
    problem = MTIR.getSewingMachineProblem(nil, m)
    rec(problem ~= "IGUI_MTIR_Machine_NoPower", "wired: MTIR sees power", tostring(problem))
    -- one consistent bill: the inverter pays what the breaker counts for the machine
    local inv = r and LiveWire.Registry.device(r.inv)
    local expected = X.Adapters.find(m).watts(m)
    local billed = inv and LiveWire.CircuitProvider.extraWatts(inv) or -1
    rec(expected > 0 and math.abs(billed - expected) < 0.5, "the inverter bills the machine", billed .. " W of " .. expected .. " W")
    rec(X.Panels.setBreaker(S.player, board, 1, true), "module 1 switched off")
    problem = MTIR.getSewingMachineProblem(nil, m)
    rec(problem == "IGUI_MTIR_Machine_NoPower", "breaker off: MTIR reports no power", tostring(problem))
    billed = inv and LiveWire.CircuitProvider.extraWatts(inv) or -1
    rec(billed == 0, "breaker off: nothing billed", billed .. " W")
    rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
end

-- ---------------------------------------------------------------- fa2 (E20)
-- Functional Appliances 2 loaded: a temperature-controlled container set to "Warm" by
-- the mod's ModData; its breaker switched off keeps the setting and stops the heat, on
-- puts it back through the mod's own FA.updateMachineTemp.
function START.fa2()
    if not FA then rec(false, "Functional Appliances 2 loaded"); return end
    local board, r, bsq = setupBoard()
    if not board then return end
    S.player:getInventory():AddItem("LiveWire.Breaker15")
    rec(X.Panels.installBreaker(S.player, board, "LiveWire.Breaker15"), "15 A breaker in module 1")
    local sq = freeRoomSquare(bsq)
    if not sq then rec(false, "free room square for the machine"); return end
    local o = IsoObject.new(getCell(), sq, getSprite("location_shop_accessories_01_10"))
    o:setContainer(ItemContainer.new("counter", sq, o))
    sq:transmitAddObjectToSquare(o, -1)
    o:getModData().CustomTemp = "Warm"
    o:getContainer():setCustomTemperature(1.5)
    rec(X.Adapters.find(o) and X.Adapters.find(o).id == "fa2", "machine recognised by the fa2 adapter")
    S.player:getInventory():AddItems("Base.ElectricWire", 10)
    if S.player:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then S.player:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
    rec(X.Points.connect(S.player, o, board, 1), "machine wired to module 1")
    rec(X.Panels.setBreaker(S.player, board, 1, true), "module 1 switched off")
    rec(o:getModData().CustomTemp == "Off" and o:getContainer():getCustomTemperature() == 1,
        "breaker off: setting kept aside, room temperature", tostring(o:getModData().CustomTemp) .. " "
        .. tostring(o:getContainer():getCustomTemperature()))
    rec(X.Panels.setBreaker(S.player, board, 1, false), "module 1 switched on")
    rec(o:getModData().CustomTemp == "Warm" and o:getContainer():getCustomTemperature() == 1.5,
        "breaker on: FA2 puts its warm setting back", tostring(o:getModData().CustomTemp) .. " "
        .. tostring(o:getContainer():getCustomTemperature()))
    rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
end

-- ---------------------------------------------------------------- twilight (E21)
-- A fridge on a breaker with a twilight switch: cut at noon, powered at 22:00 (the
-- ten-minute tick), cut again at 7:00; the engine's season dusk and dawn decide.
function START.twilight()
    local board, r, bsq = setupBoard()
    if not board then return end
    S.player:getInventory():AddItem("LiveWire.Breaker20")
    rec(X.Panels.installBreaker(S.player, board, "LiveWire.Breaker20"), "20 A breaker in module 1")
    local pieces = fridgePieces(bsq)
    if not pieces or #pieces ~= 2 then rec(false, "two-tile fridge placed", pieces and #pieces); return end
    S.player:getInventory():AddItems("Base.ElectricWire", 10)
    if S.player:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then S.player:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
    rec(X.Points.connect(S.player, pieces[1], board, 1), "fridge wired to module 1")
    local season = getClimateManager():getSeason()
    info("season dawn and dusk", string.format("%.2f / %.2f", season:getDawn(), season:getDusk()))
    getGameTime():setTimeOfDay(12)
    S.player:getInventory():AddItem("LiveWire.TwilightSwitch")
    rec(X.Panels.setTwilight(S.player, board, 1, true), "twilight switch fitted")
    rec(cooling(pieces) == 0, "noon: the circuit is open", cooling(pieces))
    getGameTime():setTimeOfDay(22)
    X.Twilight.tick()
    rec(cooling(pieces) == 2, "22:00: the circuit is closed", cooling(pieces))
    getGameTime():setTimeOfDay(9)
    X.Twilight.tick()
    rec(cooling(pieces) == 0, "9:00, after dawn: open again", cooling(pieces))
    rec(X.Panels.setTwilight(S.player, board, 1, false), "twilight switch removed")
    rec(cooling(pieces) == 2 and S.player:getInventory():getCountTypeRecurse("LiveWire.TwilightSwitch") == 1,
        "removed: always closed, item given back", cooling(pieces))
    rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
end

-- ---------------------------------------------------------------- houses (E22)
-- HouseBoardPercent = 100, then the player walks (teleport) to a house not loaded yet:
-- when its rooms load, it gets a house board (its vanilla box or an Extended board). An
-- inverter outside, the board linked: prewired breakers per room, no label; switching
-- one off cuts exactly its points.
local function houseBoard(def)
    local found
    local rooms = def:getRooms()
    for i = 0, rooms:size() - 1 do
        local room = rooms:get(i)
        local rects = room:getRects()
        for j = 0, rects:size() - 1 do
            local r = rects:get(j)
            for y = r:getY(), r:getY() + r:getH() - 1 do
                for x = r:getX(), r:getX() + r:getW() - 1 do
                    local sq = getCell():getGridSquare(x, y, room:getZ())
                    local o = sq and X.Panel.onSquare(sq)
                    if o and o:getModData().LWXHouse then found = o end
                end
            end
        end
    end
    return found
end

function START.houses()
    getSandboxOptions():getOptionByName("LiveWireExtended.HouseBoardPercent"):setValue(100)
    getSandboxOptions():getOptionByName("ElecShutModifier"):setValue(0)
    local def = findHouse()
    if not def then rec(false, "house within 600 squares"); return end
    if loaded(def, 2) then info("house already loaded before the option", "a farther one is not searched") end
    local p = S.player
    p:setX(def:getX() - 4); p:setY(def:getY() + math.floor(def:getH() / 2))
    p:setLastX(p:getX()); p:setLastY(p:getY())
    S.house, S.phase, S.at = def, "travel", getTimestampMs()
end

function DONE.houses()
    local now = getTimestampMs()
    if S.phase == "travel" then
        if not loaded(S.house, 24) and now - S.at < 60000 then return false end
        if now - S.at < 3000 then return false end
        local key = X.Buildings.key(S.house)
        local board = houseBoard(S.house)
        rec(board ~= nil, "the house got a board when it loaded", key)
        if not board then S.phase = "end"; return true end
        local name = board:getSprite():getName()
        info("house board", name .. " at " .. board:getSquare():getX() .. "," .. board:getSquare():getY()
            .. "," .. board:getSquare():getZ())
        rec(X.Panel.recordAt(board:getSquare()) == nil, "inert: no record before the first use")
        -- An inverter outside, within cable reach of the board.
        local bsq = board:getSquare()
        local asq = freeGround(bsq:getX(), bsq:getY() - 6) or freeGround(bsq:getX() - 6, bsq:getY())
        local inv, invObj
        if asq then inv, invObj = place(asq, 12) end
        if not inv then rec(false, "inverter placed near the board"); S.phase = "end"; return true end
        S.inv = inv
        holdPower(inv)
        S.player:getInventory():AddItems("Base.ElectricWire", 20)
        if S.player:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then S.player:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
        S.player:getInventory():AddItem("Base.Screwdriver")
        local ok, why, a1, a2 = X.Link.check(S.player, board, invObj)
        info("link check", tostring(ok) .. " " .. tostring(why) .. " " .. tostring(a1) .. " " .. tostring(a2)
            .. " inverter at " .. inv.x .. "," .. inv.y)
        rec(X.Panels.link(S.player, board, invObj), "house board linked: first use")
        local r = X.Panel.recordAt(bsq)
        if not r then S.phase = "end"; return true end
        rec(r and r.prewired and #r.slots > 0, "prewired breakers", r and #r.slots)
        local labelled, points = 0, 0
        for _, slot in ipairs(r and r.slots or {}) do
            if slot.label ~= "" then labelled = labelled + 1 end
            points = points + #X.Breakers.pointList(slot)
        end
        rec(labelled == 0, "no label: circuits to discover", labelled)
        rec(points > 0, "points of the house wired to its breakers", points)
        -- Switch the first breaker off: exactly its points are cut.
        local slot = r.slots[1]
        local keys = X.Breakers.pointList(slot)
        rec(X.Panels.setBreaker(S.player, board, slot.pos, true), "first breaker switched off")
        local cut, total = 0, 0
        for _, k in ipairs(keys) do
            for _, o in ipairs(X.Points.objectsOf(k, X.Points.point(k))) do
                total = total + 1
                if X.Points.blocked(o) then cut = cut + 1 end
            end
        end
        rec(total > 0 and cut == total, "its points are cut", cut .. "/" .. total)
        local other = r.slots[2] and X.Breakers.pointList(r.slots[2])[1]
        if other then
            local objs = X.Points.objectsOf(other, X.Points.point(other))
            rec(objs[1] and not X.Points.blocked(objs[1]), "a point of another breaker keeps its current")
        end
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase = "end"
        return true
    end
    return true
end

-- ---------------------------------------------------------------- release (E23)
-- Admin release before removal: the unwired fridge of a served building cools again,
-- the board stops cutting; resume brings the rule back.
function START.release()
    local board, r, bsq = setupBoard()
    if not board then return end
    local pieces = fridgePieces(bsq)
    if not pieces or #pieces ~= 2 then rec(false, "two-tile fridge placed", pieces and #pieces); return end
    rec(cooling(pieces) == 0, "unwired fridge cut (D-37)", cooling(pieces))
    rec(X.Release.run(S.player), "admin release")
    rec(not X.Points.blocked(pieces[1]), "released: no breaker rule anymore")
    S.pieces, S.phase, S.at = pieces, "released", getTimestampMs()
end

-- Unwired appliances come back through Live Wire's progressive revisit (Circuits queue).
function DONE.release()
    local now = getTimestampMs()
    if S.phase == "released" then
        if cooling(S.pieces) < 2 and now - S.at < 20000 then return false end
        rec(cooling(S.pieces) == 2, "released: the fridge cools again", cooling(S.pieces) .. " after " .. (now - S.at) .. " ms")
        rec(X.Release.resume(S.player), "resume")
        S.phase, S.at = "resumed", now
        return false
    end
    if S.phase == "resumed" then
        if cooling(S.pieces) > 0 and now - S.at < 20000 then return false end
        rec(cooling(S.pieces) == 0, "resumed: cut again", cooling(S.pieces))
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase = "end"
    end
    return true
end

-- ---------------------------------------------------------------- showcase (sneak peek)
-- Screenshots for a preview: a board with labelled breakers and its window, Locate on a
-- fridge, the board on its wall. takeScreenshot files are copied to the run folder.
local function shot(name)
    local ok, err = pcall(takeScreenshot, name .. ".png")
    if not ok then info("screenshot failed", tostring(err)) end
end

local function hideUI()
    local console = UIManager.getDebugConsole and UIManager.getDebugConsole()
    if console then console:setVisible(false) end
    if ISCharacterInfoWindow and ISCharacterInfoWindow.instance then ISCharacterInfoWindow.instance:setVisible(false) end
end

function START.showcase()
    S.boardIndex = tonumber(S.ctx.params.board) or 8
    getSandboxOptions():getOptionByName("ElecShutModifier"):setValue(0)
    getSandboxOptions():getOptionByName("LiveWire.ConsumptionProfile"):setValue(1)
    local board, r, bsq = setupBoard()
    if not board then return end
    local p = S.player
    for _, t in ipairs({ "LiveWire.Breaker20", "LiveWire.Breaker15", "LiveWire.Breaker20" }) do p:getInventory():AddItem(t) end
    X.Panels.installBreaker(p, board, "LiveWire.Breaker20")
    X.Panels.installBreaker(p, board, "LiveWire.Breaker15")
    X.Panels.installBreaker(p, board, "LiveWire.Breaker20")
    p:getInventory():AddItem("Base.Pencil")
    local labels = { [1] = "Kitchen", [2] = "Oven", [4] = "Lights", [5] = "Garage" }
    for pos, text in pairs(labels) do X.Panels.setLabel(p, board, pos, text) end
    local pieces = fridgePieces(bsq)
    S.pieces = pieces
    p:getInventory():AddItems("Base.ElectricWire", 20)
    if p:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") == 0 then p:getInventory():AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
    if pieces then X.Points.connect(p, pieces[1], board, 1) end
    p:getInventory():AddItem("LiveWire.TwilightSwitch")
    X.Panels.setTwilight(p, board, 5, true)
    X.Panels.setBreaker(p, board, 4, true)
    LiveWire.Demand.invalidate(S.inv.id)
    p:setX(bsq:getX() + 0.5); p:setY(bsq:getY() + 2.5); p:setLastX(p:getX()); p:setLastY(p:getY())
    getGameTime():setTimeOfDay(13)
    S.phase, S.at = "measure", getTimestampMs()
end

function DONE.showcase()
    local now = getTimestampMs()
    if S.phase == "measure" then
        if not LiveWire.Demand.ready(S.inv) and now - S.at < 30000 then LiveWire.Demand.measure(S.inv, true); return false end
        LiveWire.Demand.measure(S.inv, true)
        X.Protection.check()
        hideUI()
        S.win = X.BoardWindow.open(S.player, S.board)
        S.phase, S.at = "window", now
        return false
    end
    if S.phase == "window" and now - S.at > 2000 then
        shot("lwx_peek_board_window")
        -- a breaker dragged from the inventory: the free modules light up, then it is dropped
        local item = S.player:getInventory():AddItem("LiveWire.Breaker30")
        ISMouseDrag.dragging = { item }
        S.dragItem = item
        S.phase, S.at = "drag", now
        return false
    end
    if S.phase == "drag" and now - S.at > 1000 then
        shot("lwx_peek_drag")
        local free
        for pos = 1, S.record.size do if X.Breakers.moduleFree(S.record, pos) then free = pos; break end end
        local mx, my = S.win:moduleRect(free)
        S.win:onMouseUp((mx + 10) * S.win.lwK, (my + 40) * S.win.lwK)
        ISMouseDrag.dragging = nil
        S.dropped, S.phase, S.at = free, "dropped", now
        return false
    end
    if S.phase == "dropped" then
        local slot = X.Breakers.slotAt(S.record, S.dropped)
        if not slot and now - S.at < 15000 then return false end
        rec(slot ~= nil and slot.amps == 30, "breaker dropped on module " .. tostring(S.dropped) .. " installed there",
            slot and slot.type)
        -- a twilight switch dragged from the inventory onto that breaker (window's drop handler)
        local tw = S.player:getInventory():AddItem(X.Breakers.TWILIGHT_ITEM)
        ISMouseDrag.dragging = { tw }
        local mx, my = S.win:moduleRect(S.dropped)
        S.win:onMouseUp((mx + 10) * S.win.lwK, (my + 40) * S.win.lwK)
        ISMouseDrag.dragging = nil
        S.phase, S.at = "twilight", now
        return false
    end
    if S.phase == "twilight" then
        local slot = X.Breakers.slotAt(S.record, S.dropped)
        if not (slot and slot.twilight) and now - S.at < 15000 then return false end
        rec(slot ~= nil and slot.twilight == true, "twilight switch dropped on module " .. tostring(S.dropped) .. " fitted",
            slot and tostring(slot.twilight))
        S.win.selected = 1
        S.win:prerender()
        S.win:onLocate()
        S.phase, S.at = "locate", now
        return false
    end
    if S.phase == "locate" and now - S.at > 1500 then
        shot("lwx_peek_locate")
        S.win:setVisible(false)
        S.phase, S.at = "wall", now
        return false
    end
    if S.phase == "wall" and now - S.at > 1500 then
        shot("lwx_peek_locate_no_window")
        S.win:close()
        -- unlinking the board gives back the breaker and the twilight switch fitted on it (direct call)
        -- every slot of the board: its breaker item, plus a twilight switch where one is fitted
        local inv, want = S.player:getInventory(), {}
        for _, slot in ipairs(S.record.slots or {}) do
            if not slot.prewired then want[slot.type] = (want[slot.type] or 0) + 1 end
            if slot.twilight then want["LiveWire.TwilightSwitch"] = (want["LiveWire.TwilightSwitch"] or 0) + 1 end
        end
        local before = {}
        for t in pairs(want) do before[t] = inv:getCountTypeRecurse(t) end
        rec(X.Panels.unlink(S.player, S.board), "board unlinked")
        local bad, got = {}, {}
        for t, n in pairs(want) do
            local d = inv:getCountTypeRecurse(t) - before[t]
            got[#got + 1] = t .. " +" .. d
            if d ~= n then bad[#bad + 1] = t .. " +" .. d .. " (want +" .. n .. ")" end
        end
        rec(#bad == 0 and #got > 0, "unlinking gives every fitted breaker and twilight switch back",
            table.concat(#bad > 0 and bad or got, ", "))
        S.phase = "end"
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        return true
    end
    return S.phase == "end"
end

-- ---------------------------------------------------------------- film (YouTube preview)
-- A scripted one-minute tour of the breaker board, recorded by a screen capture started
-- when the run starts (subtitles added afterwards from FILM_STEPS times). Night, room
-- lights on a breaker so that switching it off is visible. Debug overlays hidden.
-- Each step runs at its time (seconds after start); the log line [LWXFILM] t=... marks it.
local FILM = {}

local function filmQuiet()
    if WaterMarkUI then WaterMarkUI.render = function() end; WaterMarkUI.prerender = function() end end
    local console = UIManager.getDebugConsole and UIManager.getDebugConsole()
    if console then console:setVisible(false) end
    if ISCharacterInfoWindow and ISCharacterInfoWindow.instance then ISCharacterInfoWindow.instance:setVisible(false) end
    -- the version watermark (its own panel, created by the game) and the inventory windows
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local t = ui:get(i):getTable()
        if t and t.Type == "WaterMarkUI" then t:setVisible(false) end
    end
    if getPlayerInventory(0) then getPlayerInventory(0):setVisible(false) end
    if getPlayerLoot(0) then getPlayerLoot(0):setVisible(false) end
    local p = S.player
    for _, f in ipairs({ "setGodMod", "setInvisible", "setNoClip", "setUnlimitedCarry", "setUnlimitedEndurance" }) do
        if p[f] then p[f](p, false) end
    end
end

local function roomSwitchOf(sq)
    local room = sq:getRoom()
    local sw = room and room:getLightSwitches()
    for i = 0, sw and sw:size() - 1 or -1 do
        local o = sw:get(i)
        if o:getObjectIndex() ~= -1 then return o end
    end
end

FILM.steps = {
    { t = 0.5, fn = function()
        filmQuiet()
        getGameTime():setTimeOfDay(21.5)
    end },
    { t = 4.0, fn = function() X.Panels.link(S.player, S.board, S.invObj) end },
    { t = 7.0, fn = function()
        filmQuiet()
        S.win = X.BoardWindow.open(S.player, S.board)
        S.win:setX(12); S.win:setY(40)
    end },
    { t = 9.0, fn = function()
        S.dragItem = S.player:getInventory():FindAndReturn("LiveWire.Breaker20")
        ISMouseDrag.dragging = { S.dragItem }
    end },
    { t = 11.5, fn = function()
        ISMouseDrag.dragging = nil
        X.Panels.installBreaker(S.player, S.board, "LiveWire.Breaker20", 1)
    end },
    { t = 12.5, fn = function() X.Panels.installBreaker(S.player, S.board, "LiveWire.Breaker15", 2) end },
    { t = 13.5, fn = function() X.Panels.installBreaker(S.player, S.board, "LiveWire.Breaker30", 3) end },
    { t = 14.5, fn = function() X.Panels.installBreaker(S.player, S.board, "LiveWire.Breaker15", 4) end },
    { t = 16.0, fn = function()
        X.Panels.setLabel(S.player, S.board, 1, "Kitchen")
        X.Panels.setLabel(S.player, S.board, 2, "Lights")
        X.Panels.setLabel(S.player, S.board, 3, "Oven")
        X.Panels.setLabel(S.player, S.board, 4, "Garden")
    end },
    { t = 18.0, fn = function()
        if S.pieces then X.Points.connect(S.player, S.pieces[1], S.board, 1) end
        if S.switch then X.Points.connect(S.player, S.switch, S.board, 2) end
        X.Points.connect(S.player, S.stove, S.board, 1)
        S.win.selected = 2
    end },
    { t = 22.0, fn = function() X.Panels.setBreaker(S.player, S.board, 2, true) end },
    { t = 25.5, fn = function() X.Panels.setBreaker(S.player, S.board, 2, false) end },
    { t = 28.0, fn = function()
        S.win.selected = 1
        S.stove:setActivated(true)
        LiveWire.Demand.invalidate(S.inv.id)
    end },
    { t = 29.0, until_ = function() return LiveWire.Demand.ready(S.inv) end, fn = function()
        LiveWire.Demand.measure(S.inv, true)
        X.Protection.check()
    end },
    { t = 34.0, fn = function()
        X.Points.disconnect(S.player, S.stove)
        X.Points.connect(S.player, S.stove, S.board, 3)
        X.Panels.setBreaker(S.player, S.board, 1, false)
    end },
    { t = 38.0, fn = function() S.win:locate(1) end },
    { t = 43.0, fn = function()
        S.win:clearLocate()
        S.player:getInventory():AddItem("LiveWire.TwilightSwitch")
        X.Panels.setTwilight(S.player, S.board, 4, true)
        S.win.selected = 4
    end },
    { t = 48.0, fn = function()
        LiveWire.Demand.measure(S.inv, true)
        X.Protection.check()
        S.win.selected = 3
    end },
    { t = 55.0, fn = function() if S.win then S.win:close() end end },
    { t = 58.0, fn = function() S.phase = "end" end },
}

function START.film()
    getSandboxOptions():getOptionByName("ElecShutModifier"):setValue(0)
    getSandboxOptions():getOptionByName("LiveWire.ConsumptionProfile"):setValue(1)
    local p = S.player
    local asq = freeGround(math.floor(p:getX()) + 2, math.floor(p:getY()))
    local inv, invObj = place(asq, 12)
    S.inv, S.invObj = inv, invObj
    holdPower(inv)
    local bsq = boardSquare(inv)
    local name = X.Terminal.SHEET .. "_10"
    local props = ISMoveableSpriteProps.new(getSprite(name))
    S.board = props:placeMoveableInternal(p, bsq, props:instanceItem(name), name)
    S.bsq = bsq
    S.pieces = fridgePieces(bsq)
    local ssq = freeRoomSquare(bsq)
    S.stove = IsoStove.new(getCell(), ssq, getSprite("appliances_cooking_01_0"))
    S.stove:setContainer(ItemContainer.new("stove", ssq, S.stove))
    ssq:transmitAddObjectToSquare(S.stove, -1)
    S.switch = roomSwitchOf(bsq)
    if S.switch then S.switch:setActive(true, false, true) end
    local inv2 = p:getInventory()
    inv2:AddItems("Base.ElectricWire", 40)
    inv2:AddItem("Base.Screwdriver")
    inv2:AddItem("Base.Pencil")
    for _, t in ipairs({ "LiveWire.Breaker20", "LiveWire.Breaker15", "LiveWire.Breaker30", "LiveWire.Breaker15" }) do
        inv2:AddItem(t)
    end
    p:setX(bsq:getX() - 2.5); p:setY(bsq:getY() + 3.5); p:setLastX(p:getX()); p:setLastY(p:getY())
    S.filmAt, S.filmStep, S.phase = getTimestampMs(), 1, "film"
    print("[LWXFILM] start")
end

function DONE.film()
    if S.phase == "end" then
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        return true
    end
    local t = (getTimestampMs() - S.filmAt) / 1000
    -- Frames taken by the game itself (only the game window, never the desktop): 5 per
    -- second, named by their time in tenths of a second, assembled into a video afterwards.
    local frame = math.floor(t * 5)
    if frame ~= S.filmFrame then
        S.filmFrame = frame
        pcall(takeScreenshot, string.format("film_%05d.png", math.floor(t * 10 + 0.5)))
    end
    local step = FILM.steps[S.filmStep]
    if step and t >= step.t and (not step.until_ or step.until_() or t > step.t + 4) then
        step.fn()
        print(string.format("[LWXFILM] t=%.1f step %d", t, S.filmStep))
        S.filmStep = S.filmStep + 1
    end
    return false
end

-- ---------------------------------------------------------------- suite
-- Every solo scenario in ONE game session: before each one the player is moved next to
-- another house of the map (its own inverter, board and appliances, nothing shared), the
-- sandbox options the previous one changed are put back, and its result lines are
-- prefixed with its name. Saves a game launch per scenario. The cases that need a fresh
-- session (houses: first load of a building; removal: restart without the sub-mod), other
-- mods (mtir, fa2), the dedicated server and multiplayer keep their own launches.
local SUITE = { "board", "points", "protection", "window", "twilight", "release", "zone", "relay", "building" }
local KEEP = { lines = true, ok = true, player = true, errors = true, ctx = true, case = true, suite = true }
local SUITE_ITEMS = { "LiveWire.Breaker15", "LiveWire.Breaker20", "LiveWire.Breaker30", "LiveWire.TwilightSwitch",
    "Base.ElectricWire", "Base.Pencil", "Base.Screwdriver" }

-- Undo what a scenario left in the world: boards and terminals forgotten and removed,
-- connected areas dropped, the inverters it placed removed (Live Wire forgets them),
-- the sub-mod's items taken out of the inventory.
local function suiteCleanup()
    local L = X.Link
    for _, kind in ipairs(L.kinds) do
        local keys = {}
        for key, r in pairs(L.records(kind)) do keys[#keys + 1] = { key, r } end
        for _, kr in ipairs(keys) do
            local r = kr[2]
            X.Linked.forget(kind, kr[1])
            local sq = getCell():getGridSquare(r.x, r.y, r.z)
            local o = sq and L.objectOn(kind, sq)
            if o then sq:transmitRemoveItemFromSquare(o) end
        end
    end
    for id in pairs(X.Data.table().inverters) do X.Connect.commit(id, function(e) e.areas = {} end) end
    for _, o in ipairs(S.suite.placed) do
        local sq = o:getSquare()
        if sq and o:getObjectIndex() ~= -1 then sq:transmitRemoveItemFromSquare(o) end
    end
    S.suite.placed = {}
    local inv = S.player:getInventory()
    for _, t in ipairs(SUITE_ITEMS) do
        local items = inv:getAllTypeRecurse(t)
        for i = items:size() - 1, 0, -1 do
            local it = items:get(i)
            if it:getContainer() then it:getContainer():DoRemoveItem(it) end
        end
    end
end
local OPTIONS = { "ElecShutModifier", "LiveWire.ConsumptionProfile", "LiveWireExtended.HouseBoardPercent" }

local function suiteHouses(n)
    local p = S.player
    local px, py = p:getX(), p:getY()
    local list, out = getWorld():getMetaGrid():getBuildings(), {}
    for i = 0, list:size() - 1 do
        local def = list:get(i)
        local d = (def:getX() - px) ^ 2 + (def:getY() - py) ^ 2
        if d < 500 * 500 and def:getW() >= 6 and def:getH() >= 6 and def:getRooms():size() >= 2 then
            out[#out + 1] = { def = def, d = d }
        end
    end
    table.sort(out, function(a, b) return a.d < b.d end)
    local picked = {}
    for _, h in ipairs(out) do
        local far = true
        for _, q in ipairs(picked) do
            if math.abs(q:getX() - h.def:getX()) < 40 and math.abs(q:getY() - h.def:getY()) < 40 then far = false end
        end
        if far then picked[#picked + 1] = h.def end
        if #picked >= n then break end
    end
    return picked
end

local function suiteNext()
    local su = S.suite
    -- prefix the lines of the case that just ended
    for i = su.mark + 1, #S.lines do S.lines[i] = S.lines[i]:gsub("^(%u+ )", "%1[" .. tostring(su.current) .. "] ") end
    su.mark = #S.lines
    if X.BoardWindow and X.BoardWindow.instance then X.BoardWindow.instance:close() end
    if su.current then suiteCleanup() end
    for name, value in pairs(su.options) do getSandboxOptions():getOptionByName(name):setValue(value) end
    for k in pairs(S) do if not KEEP[k] then S[k] = nil end end
    su.i = su.i + 1
    su.current = SUITE[su.i]
    if not su.current then su.done = true; return end
    local def = su.houses[su.i]
    if su.i > 1 and def then
        local p = S.player
        p:setX(def:getX() - 3); p:setY(def:getY() + math.floor(def:getH() / 2))
        p:setLastX(p:getX()); p:setLastY(p:getY())
    end
    su.house, su.phase, su.at = def, "travel", getTimestampMs()
end

function START.suite()
    local su = { i = 0, mark = #S.lines, options = {}, placed = {} }
    for _, name in ipairs(OPTIONS) do
        local o = getSandboxOptions():getOptionByName(name)
        if o then su.options[name] = o:getValue() end
    end
    S.suite = su
    su.houses = suiteHouses(#SUITE)
    info("suite", #su.houses .. " houses for " .. #SUITE .. " scenarios")
    suiteNext()
end

function DONE.suite()
    local su = S.suite
    if not su then return true end
    if su.done then return true end
    local now = getTimestampMs()
    if su.phase == "travel" then
        local ready = not su.house or loaded(su.house, 24)
        if (ready and now - su.at > 1500) or now - su.at > 60000 then
            info("== " .. su.current, su.house and (su.house:getX() .. "," .. su.house:getY()) or "start")
            S.errors = getLuaDebuggerErrorCount()
            START[su.current]()
            su.phase, su.at = "run", now
        end
        return false
    end
    local done = DONE[su.current]   -- scenarios without a DONE step finish in START
    if not done or done() or now - su.at > 120000 then
        if now - su.at > 120000 then rec(false, "scenario finished in time", su.current) end
        suiteNext()
    end
    return su.done == true
end

-- H6 (D-55): a board of 8 placed, wired and labelled, its window opened at 8 modules, then
-- enlarged in place through the timed action (the menu's path) to 16 and to 24, the window
-- reopened and captured after each step. The breakers, labels and the wiring must stay.
local function h6Window(now)
    S.win = X.BoardWindow.open(S.player, S.board)
    S.phase, S.at = "shot", now
end

local function h6Queue(now, size)
    local p = S.player
    p:getInventory():AddItems("Base.SmallSheetMetal", 1)
    p:getInventory():AddItems("Base.Screws", 4)
    ISTimedActionQueue.add(LWXEnlargeAction:new(p, S.board))
    S.want, S.phase, S.at = size, "enlarge", now
end

function START.h6board()
    S.boardIndex = 8
    getSandboxOptions():getOptionByName("ElecShutModifier"):setValue(0)
    getSandboxOptions():getOptionByName("LiveWire.ConsumptionProfile"):setValue(1)
    local board, r, bsq = setupBoard()
    if not board then return end
    local p = S.player
    for _, t in ipairs({ "LiveWire.Breaker20", "LiveWire.Breaker15", "LiveWire.Breaker20" }) do p:getInventory():AddItem(t) end
    X.Panels.installBreaker(p, board, "LiveWire.Breaker20")
    X.Panels.installBreaker(p, board, "LiveWire.Breaker15")
    X.Panels.installBreaker(p, board, "LiveWire.Breaker20")
    p:getInventory():AddItem("Base.Pencil")
    X.Panels.setLabel(p, board, 1, "Kitchen")
    X.Panels.setLabel(p, board, 4, "Lights")
    p:getInventory():AddItems("Base.ElectricWire", 20)
    p:getInventory():AddItem("Base.Screwdriver")
    p:setX(bsq:getX() + 0.5); p:setY(bsq:getY() + 2.5); p:setLastX(p:getX()); p:setLastY(p:getY())
    getGameTime():setTimeOfDay(13)
    S.phase, S.at, S.steps = "measure", getTimestampMs(), 0
end

function DONE.h6board()
    local now = getTimestampMs()
    if S.phase == "measure" then
        if not LiveWire.Demand.ready(S.inv) and now - S.at < 30000 then LiveWire.Demand.measure(S.inv, true); return false end
        LiveWire.Demand.measure(S.inv, true)
        hideUI()
        h6Window(now)
        return false
    end
    if S.phase == "shot" and now - S.at > 2000 then
        shot("h6_board_" .. S.record.size)
        rec(S.record.size == S.want or S.record.size == 8, "board window at " .. S.record.size .. " modules")
        if X.BoardWindow.instance then X.BoardWindow.instance:close() end
        if S.record.size == 8 then h6Queue(now, 16) elseif S.record.size == 16 then h6Queue(now, 24) else return true end
        return false
    end
    if S.phase == "enlarge" then
        if S.record.size ~= S.want and now - S.at < 40000 then return false end
        rec(S.record.size == S.want, "enlarged in place to " .. S.want .. " modules", S.record.size)
        local slot = X.Breakers.slotAt(S.record, 1)
        rec(slot ~= nil and slot.label == "Kitchen", "label kept after enlargement")
        rec(X.Breakers.usedModules(S.record) == 4, "breakers kept after enlargement", X.Breakers.usedModules(S.record))
        rec(S.board:getSprite():getName() == X.Terminal.SHEET .. "_" .. (S.want == 16 and 10 or 12), "tile of " .. S.want .. " modules")
        h6Window(now)
        return false
    end
    return false
end

-- Test worlds without zombies (user request, 2026-11-09): every zombie of the loaded cell is
-- removed at each poll, and the player is invisible and invulnerable.
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

-- LCD (D-56, plan lcd-commun L6): every LCD screen opened through its real open(), one capture
-- each (two for the scrolling line, 2.5 s apart): bank, solar panel, pump, inverter lit with a
-- long network name and its gauges, inverter off, Live Wire breaker, Extended board at 8 then
-- 24 modules (enlarged in place). Fixtures: power held on (holdPower), player moved next to the pump.
local LCD_NAME = "Garage and workshop network of the north house"
local function lcdSteps()
    local p = S.player
    local P = LiveWire
    return {
        { "lcd_bank", function() P.BankPanel.open(p, S.lcd.bankObj) end, P.BankPanel },
        { "lcd_solar", function() P.DevicePanel.open(p, S.lcd.solarObj) end, P.DevicePanel },
        { "lcd_pump", function()
            -- The device window closes beyond 3.5 tiles: stand next to the pump for this step.
            local sq = S.lcd.pumpObj:getSquare()
            S.lcd.home = { p:getX(), p:getY() }
            p:setX(sq:getX() + 1.5); p:setY(sq:getY() + 0.5); p:setLastX(p:getX()); p:setLastY(p:getY())
            P.DevicePanel.open(p, S.lcd.pumpObj)
        end, P.DevicePanel },
        { "lcd_inverter_on", function()
            local h = S.lcd.home
            if h then p:setX(h[1]); p:setY(h[2]); p:setLastX(h[1]); p:setLastY(h[2]) end
            P.InverterPanel.open(p, S.inv.id)
            -- Spy on the real drawing: x of the long network name at each frame (scrolling proof).
            local inst = P.InverterPanel.instance
            if inst then
                local orig = inst.drawText
                inst.drawText = function(self, str, x, ...)
                    if str == LCD_NAME then
                        S.xmin = math.min(S.xmin or x, x); S.xmax = math.max(S.xmax or x, x)
                    end
                    return orig(self, str, x, ...)
                end
            end
        end, P.InverterPanel, true },
        -- The inverter switched off through the I/O button's command (C_SET_INVERTER), then on again.
        { "lcd_inverter_off", function()
            P.Client.send(P.Protocol.C_SET_INVERTER, { inverter = S.inv.id, on = false })
            P.InverterPanel.open(p, S.inv.id)
        end, P.InverterPanel },
        { "lcd_breaker", function()
            local snap = P.Client.snapshot(S.inv.id)
            rec(snap and snap.inverter.state == "off", "inverter shown off after its command",
                snap and snap.inverter.state)
            P.Client.send(P.Protocol.C_SET_INVERTER, { inverter = S.inv.id, on = true })
            P.BreakerPanel.open(p, S.lcd.brObj)
        end, P.BreakerPanel },
        { "lcd_board_8", function() X.BoardWindow.open(p, S.board) end, X.BoardWindow },
    }
end

function START.lcd()
    untouchable(S.player); clearZombies()
    S.boardIndex = 8
    getSandboxOptions():getOptionByName("ElecShutModifier"):setValue(0)
    local board, r, bsq = setupBoard()
    if not board then return end
    local p, R = S.player, LiveWire.Registry
    R.grid(S.inv.grid).name = LCD_NAME
    S.lcd = {}
    local function near(n)
        local sq = freeGround(S.inv.x + 1, S.inv.y + 1)
        local d, o = place(sq, n)
        if d and d.role ~= "inverter" and d.role ~= "bank" then R.link(d, R.grid(S.inv.grid)) end
        if d then LiveWire.Devices.syncMark(d) end
        return d, o
    end
    local _
    _, S.lcd.bankObj = near(16)
    _, S.lcd.solarObj = near(0)
    _, S.lcd.pumpObj = near(72)
    _, S.lcd.brObj = near(20)
    rec(S.lcd.bankObj and S.lcd.solarObj and S.lcd.pumpObj and S.lcd.brObj, "bank, solar panel, pump and breaker placed")
    LiveWire.Sim.refresh(R.grid(S.inv.grid))
    p:setX(bsq:getX() + 0.5); p:setY(bsq:getY() + 2.5); p:setLastX(p:getX()); p:setLastY(p:getY())
    getGameTime():setTimeOfDay(13)
    S.steps, S.step, S.phase, S.at = lcdSteps(), 0, "next", getTimestampMs()
    info("fonts", "Small " .. getTextManager():getFontHeight(UIFont.Small) .. " px, LCD "
        .. getTextManager():getFontHeight(LiveWire.Lcd.font()) .. " px, language " .. tostring(Translator.getLanguage()))
end

function DONE.lcd()
    clearZombies()
    local now = getTimestampMs()
    if not S.steps then return true end
    if S.phase == "next" then
        S.step = S.step + 1
        local st = S.steps[S.step]
        if not st then
            -- Board 24: enlarged in place twice (the menu's timed action), then captured.
            h6Queue(now, 16); S.phase = "enlarge"
            return false
        end
        hideUI()
        local errors = getLuaDebuggerErrorCount()
        st[2]()
        rec(st[3].instance ~= nil and getLuaDebuggerErrorCount() == errors, st[1] .. " opens without Lua error")
        S.phase, S.at = "shot", now
        return false
    end
    if S.phase == "shot" and now - S.at > (S.second and 4000 or 2500) then
        local st = S.steps[S.step]
        shot(st[1])
        if st[4] and not S.second then S.second, S.at = true, now; return false end
        if st[4] then
            shot(st[1] .. "_later")
            local inst, L = LiveWire.InverterPanel.instance, LiveWire.InverterPanel.instance.L
            local width = getTextManager():MeasureStringX(LiveWire.Lcd.font(), LCD_NAME)
            local avail = L.lcdW - 2 * L.pad - L.reserve
            local moved = S.xmin ~= nil and S.xmin < S.xmax
            rec(S.xmin ~= nil and (width > avail) == moved, "long LCD line scrolls only when wider than the screen",
                "width " .. width .. " / " .. avail .. ", x from " .. tostring(S.xmin) .. " to " .. tostring(S.xmax))
        end
        S.second = nil
        if st[3].instance then st[3].instance:close() end
        S.phase = "next"
        return false
    end
    if S.phase == "enlarge" then
        if S.record.size ~= S.want and now - S.at < 40000 then return false end
        if S.record.size == 16 and S.want == 16 then h6Queue(now, 24); return false end
        rec(S.record.size == 24, "board enlarged to 24 modules", S.record.size)
        hideUI()
        X.BoardWindow.open(S.player, S.board)
        S.phase, S.at = "board24", now
        return false
    end
    if S.phase == "board24" and now - S.at > 2500 then
        shot("lcd_board_24")
        rec(getLuaDebuggerErrorCount() == S.errors, "no new Lua errors", getLuaDebuggerErrorCount() - S.errors)
        return true
    end
    return false
end

-- 42.22 (user request 2026-11-10): toasters and coffee machines need power (ISEntityUI.CanOpenWindowFor
-- reads square:haveElectricity() or hasGridPower()). A toaster and a coffee machine placed in the
-- building powered by Live Wire must open; after the inverter's real off command they must not.
-- Fixtures: grid power off (ElecShutModifier 0), power held on (holdPower) until the off command.
local function placeSprite(sq, name)
    local props = ISMoveableSpriteProps.new(getSprite(name))
    return props:placeMoveableInternal(S.player, sq, props:instanceItem(name), name)
end

local function appliancesState(tag)
    for _, a in ipairs(S.app or {}) do
        local sq = a.obj:getSquare()
        local can = ISEntityUI.CanOpenWindowFor(S.player, a.obj) and true or false
        a[tag] = { elec = sq:haveElectricity(), grid = sq:hasGridPower(), can = can }
        info(a.name .. " " .. tag, "haveElectricity=" .. tostring(a[tag].elec) .. " hasGridPower=" .. tostring(a[tag].grid)
            .. " CanOpenWindowFor=" .. tostring(can))
    end
end

-- Open appliance window of `obj` (ISEntityUI registry), or nil.
local function entityWindow(obj)
    for _, p in pairs(ISEntityUI.players or {}) do
        for _, w in pairs(p.windows or {}) do
            if w.instance and w.entityObj == obj then return w.instance end
        end
    end
end

function START.appliances42()
    untouchable(S.player); clearZombies()
    S.elecEvents = 0
    if Events.OnElectricityChanged then
        Events.OnElectricityChanged.Add(function() S.elecEvents = S.elecEvents + 1 end)
    end
    getSandboxOptions():getOptionByName("ElecShutModifier"):setValue(0)
    S.realAnchor = LiveWire.Sim.updateAnchor
    local board, r, bsq = setupBoard()
    if not board then return end
    S.app = {}
    local cell = getCell()
    for _, def in ipairs({ { "toaster", "appliances_cooking_01_32" }, { "coffee machine", "appliances_cooking_01_56" } }) do
        local sq
        for dx = -4, 4 do
            for dy = 1, 5 do
                local c = not sq and cell:getGridSquare(bsq:getX() + dx, bsq:getY() + dy, bsq:getZ())
                if c and c:getRoom() and c:isFree(false) and not c:getObjects():isEmpty() and c:getObjects():size() == 1 then sq = c end
            end
        end
        local obj = sq and placeSprite(sq, def[2])
        rec(obj ~= nil, def[1] .. " placed indoors", sq and (sq:getX() .. "," .. sq:getY()))
        if obj then S.app[#S.app + 1] = { name = def[1], obj = obj } end
    end
    S.player:setX(bsq:getX() + 0.5); S.player:setY(bsq:getY() + 2.5)
    S.player:setLastX(S.player:getX()); S.player:setLastY(S.player:getY())
    S.phase, S.at = "on", getTimestampMs()
end

function DONE.appliances42()
    clearZombies()
    local now = getTimestampMs()
    if not S.app then return true end
    if S.phase == "on" and now - S.at > 2000 then
        appliancesState("on")
        for _, a in ipairs(S.app) do
            rec(a.on.elec and not a.on.grid and a.on.can, a.name .. " opens on Live Wire power (no grid power)")
        end
        local g = LiveWire.Registry.grid(S.inv.grid)
        info("grid", "powered=" .. tostring(g.powered) .. " inverter=" .. tostring(S.inv.state)
            .. " board square haveElectricity=" .. tostring(S.bsq:haveElectricity()))
        -- Vanilla opening path (direct call, not a click): the toaster's crafting window.
        ISEntityUI.OpenWindow(S.player, S.app[1].obj)
        S.window = entityWindow(S.app[1].obj)
        rec(S.window ~= nil, S.app[1].name .. " window open on Live Wire power")
        S.eventsBefore = S.elecEvents
        LiveWire.Sim.updateAnchor = S.realAnchor   -- holdPower removed: the off command takes effect
        LiveWire.Client.send(LiveWire.Protocol.C_SET_INVERTER, { inverter = S.inv.id, on = false })
        S.phase, S.at = "off", now
        return false
    end
    if S.phase == "off" then
        local sq = S.app[1] and S.app[1].obj:getSquare()
        if sq and sq:haveElectricity() and now - S.at < 15000 then return false end
        appliancesState("off")
        for _, a in ipairs(S.app) do
            rec(not a.off.elec and not a.off.can, a.name .. " refused once the inverter is off")
        end
        if Events.OnElectricityChanged then
            rec(S.elecEvents > S.eventsBefore, "OnElectricityChanged fired when the inverter stopped",
                S.elecEvents - S.eventsBefore)
            rec(S.window ~= nil and entityWindow(S.app[1].obj) == nil and not S.window:isVisible(),
                S.app[1].name .. " window closed by vanilla when Live Wire power dropped")
        else
            info("OnElectricityChanged", "absent (42.21): no event, window left to the player")
        end
        rec(getLuaDebuggerErrorCount() == S.errors, "no new Lua errors", getLuaDebuggerErrorCount() - S.errors)
        return true
    end
    return false
end

-- ---------------------------------------------------------------- consumers
-- A connected building, no board: the inverter's "Show consumers" view lists its appliances.
function START.consumers()
    untouchable(S.player); clearZombies()
    if S.ctx.params.grid == "off" then getSandboxOptions():getOptionByName("ElecShutModifier"):setValue(0) end
    START.building()
end

function DONE.consumers()
    clearZombies()
    if not travelled() then return S.phase == "end" end
    local now = getTimestampMs()
    if S.phase == "connected" and now - S.at > 1500 then
        LiveWire.NetworkView.show(S.inv.id, "consumers")
        S.phase, S.at = "viewing", now
        return false
    end
    -- end soon after the rows arrive: the final screenshot still shows the floating text
    local ready = S.phase == "viewing" and #((LiveWire.Client.snapshot(S.inv.id) or {}).consumers or {}) > 0
    if S.phase == "viewing" and ((ready and now - S.at > 2500) or now - S.at > 15000) then
        rec(LiveWire.NetworkView.legend ~= nil, "the consumers legend is a window")
        local entry = LiveWire.Demand.entry(S.inv.id)
        local nObj, nRead = entry and #entry.objects or -1, 0
        for _ in pairs(entry and entry.readings or {}) do nRead = nRead + 1 end
        info("demand entry", string.format("objects=%d readings=%d measured=%s dirty=%s queued=%s",
            nObj, nRead, tostring(entry and entry.measured), tostring(entry and entry.dirty), tostring(entry and entry.queued)))
        local cut, powered = 0, 0
        for _, o in ipairs(entry and entry.objects or {}) do
            if ItemContainer.isObjectPowered(o, false) then powered = powered + 1 end
            if LiveWire.Appliances and LiveWire.Appliances.blocked(o) then cut = cut + 1 end
        end
        info("objects", string.format("on public grid=%d cut by a circuit=%d", powered, cut))
        local server = LiveWire.Demand.consumers(S.inv)
        local snap = LiveWire.Client.snapshot(S.inv.id)
        local client = snap and snap.consumers or {}
        local lit = 0
        for _ in pairs(LiveWire.NetworkView.highlights) do lit = lit + 1 end
        info("consumers", string.format("server=%d snapshot=%s highlighted=%d", #server,
            snap and tostring(#client) or "none", lit))
        for i = 1, math.min(5, #client) do
            local d = client[i]
            info("row " .. i, string.format("%s %d,%d,%d w=%s served=%s", tostring(d.sprite), d.x, d.y, d.z,
                tostring(d.w), tostring(d.served)))
        end
        rec(nObj > 0, "the connected building's appliances are in the inverter's list", nObj)
        rec(#client > 0, "the consumers view receives rows", #client)
        rec(lit > 0, "the consumers view highlights appliances", lit)
        local onGrid = 0
        for _, d in ipairs(client) do if d.grid then onGrid = onGrid + 1 end end
        local gridOn = S.ctx.params.grid ~= "off"
        info("public grid", tostring(gridOn) .. ", rows on it " .. onGrid)
        rec(gridOn == (onGrid > 0) and gridOn == LiveWire.NetworkView.gridActive(snap),
            "rows on the public grid flagged and the view's grid line shown only then", onGrid)
        -- the view stays open for the final screenshot
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase = "end"
    end
    return S.phase == "end" or not S.phase
end

-- ---------------------------------------------------------------- pickup (B4)
-- Every facing of the terminal and the boards gives its own moveable item (tile CustomItem),
-- then a terminal facing east is placed and picked up by the vanilla moveable code (direct
-- calls of placeMoveableInternal / pickUpMoveableInternal, not the furniture cursor).
local PICKUP = { { "Base.Mov_LiveWire_Terminal", { 0, 1, 2, 3 } }, { "Base.Mov_LiveWire_Panel8", { 8, 9 } },
    { "Base.Mov_LiveWire_Panel16", { 10, 11 } }, { "Base.Mov_LiveWire_Panel24", { 12, 13 } } }
function START.pickup()
    untouchable(S.player); clearZombies()
    for _, e in ipairs(PICKUP) do
        for _, i in ipairs(e[2]) do
            local name = "batman_livewireext_01_" .. i
            local props = ISMoveableSpriteProps.new(getSprite(name))
            local item = props:instanceItem(name)
            rec(props.customItem == e[1] and item and item:getFullType() == e[1], "tile " .. i .. " gives " .. e[1],
                tostring(props.customItem) .. " / " .. tostring(item and item:getFullType()))
        end
    end
    local sq = freeGround(math.floor(S.player:getX()) + 3, math.floor(S.player:getY()))
    if not sq then rec(false, "free square for the terminal"); return end
    local name = "batman_livewireext_01_1"
    local props = ISMoveableSpriteProps.new(getSprite(name))
    local obj = props:placeMoveableInternal(S.player, sq, props:instanceItem(name), name)
    rec(obj ~= nil, "terminal facing east placed", name)
    if not obj then return end
    local inv = S.player:getInventory()
    local before = inv:getCountTypeRecurse("Base.Mov_LiveWire_Terminal")
    props:pickUpMoveableInternal(S.player, sq, obj, nil, name, true, false)
    rec(inv:getCountTypeRecurse("Base.Mov_LiveWire_Terminal") == before + 1, "picked up as Power Terminal",
        before .. " -> " .. inv:getCountTypeRecurse("Base.Mov_LiveWire_Terminal"))
    rec(inv:getCountTypeRecurse("Moveables.batman_livewireext_01_1") == 0, "no generic moveable item")
    rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
end
function DONE.pickup() return true end

-- ---------------------------------------------------------------- adopt (C9, D-65)
-- An inverter inside a two-floor house, with no area: the first-start adoption (re-armed here,
-- as the world already ran it on its first minute) connects the house; every loaded room
-- square of every floor gets power.
local function setupAdopt(def)
    S.def = def
    local spot
    for _, sq in ipairs(roomSquares(def)) do
        if sq:getZ() == 0 and sq:isFree(false) and not LiveWire.Marks.firstOnSquare(sq) then spot = sq; break end
    end
    if not spot then rec(false, "free room square for the inverter"); S.phase = "end"; return end
    local inv = place(spot, 12)
    if not inv then rec(false, "inverter placed"); S.phase = "end"; return end
    S.inv = inv
    holdPower(inv)
    S.squares = roomSquares(def)
    rec(X.Data.entry(inv.id) == nil, "the new inverter has no area yet")
    X.Data.table().adopted = nil
    Events.EveryOneMinute.Remove(X.Adopt.tick)
    Events.EveryOneMinute.Add(X.Adopt.tick)
    S.phase, S.at = "waiting", getTimestampMs()
end

function START.adopt()
    untouchable(S.player); clearZombies()
    local def = findHouse()
    if not def then rec(false, "two-floor house within 600 squares"); S.phase = "end"; return end
    if loaded(def, 24) then setupAdopt(def); return end
    local p = S.player
    p:setX(def:getX() - 4); p:setY(def:getY() + math.floor(def:getH() / 2))
    p:setLastX(p:getX()); p:setLastY(p:getY())
    S.adoptDef, S.phase, S.at = def, "travel", getTimestampMs()
end

function DONE.adopt()
    clearZombies()
    local now = getTimestampMs()
    if S.phase == "travel" then
        if loaded(S.adoptDef, 24) and now - S.at > 1500 then setupAdopt(S.adoptDef)
        elseif now - S.at > 60000 then rec(false, "house squares loaded after moving"); S.phase = "end" end
        return S.phase == "end"
    end
    if S.phase == "waiting" then
        if X.Data.entry(S.inv.id) then
            rec(X.Data.table().adopted == true, "adoption ran once and was recorded", now - S.at .. " ms")
            S.phase, S.at = "adopted", now
        elseif now - S.at > 60000 then
            rec(false, "the house of the inverter was connected within 60 s"); S.phase = "end"
        end
        return S.phase == "end"
    end
    if S.phase == "adopted" and now - S.at > 1500 then
        local after, floors = unpowered(S.squares)
        rec(after == 0, "every loaded room square of every floor powered", string.format("%d unpowered of %d (floors %s)",
            after, #S.squares, floors))
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        S.phase = "end"
    end
    return S.phase == "end"
end

function H.start(ctx)
    S.player, S.case, S.ctx = getPlayer(), ctx.params.case or "building", ctx
    S.errors = getLuaDebuggerErrorCount()
    Events.EveryTenMinutes.Remove(LiveWire.Sim.tick)
    rec(X ~= nil and X.Data and X.Data.registered == true, "sub-mod loaded and provider registered")
    S.player:setPerkLevelDebug(Perks.Electricity, 10)
    local fn = START[S.case]
    if not fn then rec(false, "known case", S.case); return true end
    fn()
    return true
end

function H.done(ctx)
    local fn = DONE[S.case]
    if not fn then return true end
    return fn()
end

function H.result(ctx)
    return { ok = S.ok, summary = "LiveWire Extended " .. tostring(S.case), lines = S.lines }
end
return H
