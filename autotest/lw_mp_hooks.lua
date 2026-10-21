-- Live Wire in-game test, multiplayer (pz-autotest mp: dedicated server + client 1).
-- Server side: installs a network next to the connected player through the real
-- placement wrapper (ISMoveableSpriteProps:placeMoveableInternal) and the real link
-- action (LWLinkAction:complete on the authority), fills the power bank, steps the
-- simulation, then checks the commands of the management software (C02): refused
-- from more than 3 tiles without `via`, accepted with the position of a powered linked
-- computer, on the same floor and from another floor (SKIP when no floor is found).
-- Client side: sees the marks sent by the server, subscribes from the computer (real
-- sendClientCommand), receives a snapshot, switches the inverter off and on again
-- through the network and sees the new state in the mark.
-- The server waits for the client commands (parameter client=0: no wait).
local H = { server = {}, client = {} }

local SHEET = "batman_livewire_01_"
local COMPUTER_SPRITE = "appliances_com_01_72"

local function newReport()
    local r = { lines = {}, ok = true }
    function r.rec(ok, name, detail)
        if not ok then r.ok = false end
        r.lines[#r.lines + 1] = (ok and "PASS " or "FAIL ") .. name .. (detail and (" - " .. tostring(detail)) or "")
    end
    function r.check(name, fn)
        local ok, res, detail = pcall(fn)
        if not ok then return r.rec(false, name, "error: " .. tostring(res)) end
        r.rec(res == true, name, detail)
    end
    function r.skip(name, why) r.lines[#r.lines + 1] = "SKIP " .. name .. " - " .. tostring(why) end
    function r.result()
        local pass, total = 0, 0
        for i = 1, #r.lines do
            local head = r.lines[i]:sub(1, 4)
            if head == "PASS" then pass = pass + 1 end
            if head == "PASS" or head == "FAIL" then total = total + 1 end
        end
        return { ok = r.ok, summary = pass .. "/" .. total .. " PASS", lines = r.lines }
    end
    return r
end

local function ourObject(sq, spriteName)
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local s = o:getSprite()
        if s and s:getName() == spriteName then return o end
    end
    return nil
end

local function hasOtherObjects(sq)
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        if objs:get(i) ~= sq:getFloor() then return true end
    end
    return sq:getWorldObjects():size() > 0
end

-------------------------------------------------------------------------------
-- Server
-------------------------------------------------------------------------------
local S = { rep = newReport() }

-- Free floor square at Chebyshev distance dMin..dMax of (x0, y0) on floor z.
local function freeSquare(x0, y0, z, dMin, dMax)
    local cell = getCell()
    for d = dMin, dMax do
        for dx = -d, d do
            for dy = -d, d do
                if math.abs(dx) == d or math.abs(dy) == d then
                    local sq = cell:getGridSquare(x0 + dx, y0 + dy, z)
                    local k = tostring(x0 + dx) .. "," .. tostring(y0 + dy) .. "," .. tostring(z)
                    if sq and not S.used[k] and sq:isSolidFloor() and not sq:HasStairs()
                        and sq:isFree(false) and not hasOtherObjects(sq) then
                        S.used[k] = true
                        return sq
                    end
                end
            end
        end
    end
    return nil
end

-- Place a tile as a player would on the server (our wrapper registers the device).
local function placeTile(sq, spriteName)
    local props = ISMoveableSpriteProps.new(getSprite(spriteName))
    local item = props:instanceItem(spriteName)
    if not item then return nil end
    props:placeMoveableInternal(S.player, sq, item, spriteName)
    return ourObject(sq, spriteName)
end

local function devOf(obj)
    local m = obj and LiveWire.Marks.get(obj)
    return m and LiveWire.Registry.device(m.id)
end

local function command(cmd, args)
    LiveWire.Commands.handle(S.player, cmd, args)
end

local function viaOf(obj)
    local sq = obj:getSquare()
    return { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
end

-- One network: inverter on `invSq`, power bank and computer next to the player.
local function buildNetwork(tag, invSq)
    local rep = S.rep
    local px, py, pz = math.floor(S.player:getX()), math.floor(S.player:getY()), math.floor(S.player:getZ())
    local net = { tag = tag }
    net.inv = placeTile(invSq, SHEET .. "12")
    local bankSq = freeSquare(px, py, pz, 1, 2)
    local compSq = bankSq and freeSquare(px, py, pz, 1, 2)
    if not (net.inv and bankSq and compSq) then
        rep.rec(false, tag .. ": devices installed", "inverter " .. tostring(net.inv ~= nil) .. ", squares "
            .. tostring(bankSq ~= nil) .. "/" .. tostring(compSq ~= nil))
        return nil
    end
    net.bank = placeTile(bankSq, SHEET .. "16")
    net.comp = placeTile(compSq, COMPUTER_SPRITE)
    local inv = devOf(net.inv)
    rep.rec(inv ~= nil and inv.role == "inverter" and devOf(net.bank) ~= nil and net.comp ~= nil
        and LiveWire.Marks.get(net.inv).st == "on",
        tag .. ": inverter and power bank registered by the placement wrapper, computer placed",
        "inverter at " .. invSq:getX() .. "," .. invSq:getY() .. "," .. invSq:getZ())
    if not inv or not net.bank or not net.comp then return nil end
    net.id = inv.id
    local c = net.bank:getContainer()
    if c then
        for _ = 1, 4 do
            local b = c:AddItem("Base.CarBattery2")
            if b then sendAddItemToContainer(c, b) end
        end
    end
    local okBank = LWLinkAction:new(S.player, net.bank, net.inv):complete() == true
    local okComp = LWLinkAction:new(S.player, net.comp, net.inv):complete() == true
    local grid = LiveWire.Registry.grid(inv.grid)
    local _, banks, _, _, computers = LiveWire.Registry.members(grid)
    rep.rec(okBank and okComp and #banks == 1 and #computers == 1,
        tag .. ": power bank and computer linked by the real action on the server",
        "bank=" .. tostring(okBank) .. " computer=" .. tostring(okComp))
    command(LiveWire.Protocol.C_DEBUG, { action = "battery100", device = inv.id })
    LiveWire.Sim.refresh(grid)
    return net
end

local function setInverter(net, on, via)
    command(LiveWire.Protocol.C_SET_INVERTER, { inverter = net.id, on = on, via = via })
    return devOf(net.inv).state
end

-- C02 on the authority: from the player position, the inverter is out of ACT_RANGE.
local function checkCommands(net)
    local rep = S.rep
    local inv = devOf(net.inv)
    local grid = LiveWire.Registry.grid(inv.grid)
    local Computer = LiveWire.Computer
    local _, _, _, _, computers = LiveWire.Registry.members(grid)
    local cdev = computers[1]
    if not cdev or not Computer.powered(cdev, grid) then
        rep.rec(false, net.tag .. ": management computer powered", "grid powered=" .. tostring(grid.powered))
        return false
    end
    local refused = setInverter(net, false, nil) == "on"
    local off = setInverter(net, false, viaOf(net.comp)) == "off"
    local on = setInverter(net, true, viaOf(net.comp)) == "on"
    local fake = setInverter(net, false, { x = inv.x, y = inv.y, z = inv.z }) == "on"
    rep.rec(refused and off and on and fake,
        net.tag .. ": software commands accepted from the linked computer only",
        "refused without via=" .. tostring(refused) .. " off=" .. tostring(off) .. " on=" .. tostring(on)
            .. " refused with a wrong via=" .. tostring(fake))
    command(LiveWire.Protocol.C_SUBSCRIBE, { inverter = net.id, via = viaOf(net.comp) })
    local subs = LiveWire.Sim.subscribers[grid.id]
    rep.rec(subs ~= nil and subs[S.player:getUsername()] ~= nil, net.tag .. ": subscription from the computer")
    return true
end

function H.server.start(ctx)
    S.used = {}
    local list = ctx.players()
    S.player = list and list[1]
    local rep = S.rep
    if not S.player then return false, "no connected player" end
    local R = LiveWire.Registry
    rep.check("registry ready on the server (schema 2)", function()
        return R.ready and not R.readOnly and R.data.schema == 2
    end)
    S.player:setPerkLevelDebug(Perks.Electricity, 10)
    for _ = 1, 30 do LiveWire.Install.giveItem(S.player, "Base.ElectricWire") end
    local px, py, pz = math.floor(S.player:getX()), math.floor(S.player:getY()), math.floor(S.player:getZ())

    -- A: same floor, 5 tiles away (more than ACT_RANGE = 3, less than SOFTWARE_RANGE + link).
    local sqA = freeSquare(px, py, pz, 5, 6)
    if sqA then
        S.A = buildNetwork("A same floor", sqA)
    else
        rep.rec(false, "A same floor: free square 5 tiles away", "not found")
    end
    -- B: the floor above (or below), within link range of the computer.
    local sqB
    for _, dz in ipairs({ 1, -1 }) do
        sqB = sqB or freeSquare(px, py, pz + dz, 1, 8)
    end
    if sqB then
        S.B = buildNetwork("B other floor", sqB)
    else
        rep.skip("B other floor", "no free floor square one level up or down")
    end

    rep.check("simulation step on the server", function()
        LiveWire.Sim.tick()
        local grid = S.A and R.grid(devOf(S.A.inv).grid)
        local snap = grid and LiveWire.Sim.snapshot(grid)
        return snap ~= nil and grid.powered == true, "powered=" .. tostring(grid and grid.powered)
    end)
    S.waitMs = (tonumber(ctx.params.clientWaitSec) or 180) * 1000
    S.startedAt = getTimestampMs()
    S.phase = "commands"
    return true
end

-- Polled every 250 ms: the commands need the computer square powered by our anchor;
-- then wait for the client to switch inverter A off and on again.
function H.server.done(ctx)
    local rep = S.rep
    local now = getTimestampMs()
    if S.phase == "commands" then
        local ready = true
        for _, net in ipairs({ S.A, S.B }) do
            local inv = net and devOf(net.inv)
            local grid = inv and LiveWire.Registry.grid(inv.grid)
            local computers
            if grid then
                local _, _, _, _, list = LiveWire.Registry.members(grid)
                computers = list
            end
            if computers and computers[1] and not LiveWire.Computer.powered(computers[1], grid) then ready = false end
        end
        if not ready and now - S.startedAt < 20000 then return false end
        for _, net in ipairs({ S.A, S.B }) do
            if net then pcall(checkCommands, net) end
        end
        if ctx.params.client == "0" or not S.A then return true end
        S.phase = "client"
        S.sawOff = false
        return false
    end
    if S.phase == "client" then
        local inv = devOf(S.A.inv)
        if inv and inv.state == "off" then S.sawOff = true end
        if S.sawOff and inv and inv.state == "on" then
            rep.rec(true, "A: client switched the inverter off and on through the network")
            return true
        end
        if now - S.startedAt > S.waitMs then
            rep.rec(false, "A: client switched the inverter off and on through the network",
                "no client command after " .. math.floor(S.waitMs / 1000) .. " s (seen off=" .. tostring(S.sawOff) .. ")")
            return true
        end
        return false
    end
    return true
end

function H.server.result(ctx)
    S.rep.check("no Lua error recorded on the server", function()
        local n = getLuaDebuggerErrorCount and getLuaDebuggerErrorCount() or 0
        return n == 0, "errors=" .. tostring(n)
    end)
    return S.rep.result()
end

-------------------------------------------------------------------------------
-- Client (client 1, --client-run or mp.clientRun)
-------------------------------------------------------------------------------
local C = { rep = newReport() }

-- Computers near the player marked by the server, with their inverter object.
local function scan()
    local p = getPlayer()
    local cell = getCell()
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local found = {}
    local key = LiveWire.Defs.COMPUTER_KEY
    for z = pz - 1, pz + 1 do
        for x = px - 3, px + 3 do
            for y = py - 3, py + 3 do
                local sq = cell:getGridSquare(x, y, z)
                local objs = sq and sq:getObjects()
                if objs then
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        local m = o:getModData()[key]
                        if type(m) == "table" and type(m.inverter) == "string" then
                            found[#found + 1] = { comp = o, invId = m.inverter }
                        end
                    end
                end
            end
        end
    end
    for _, f in ipairs(found) do
        local cs = f.comp:getSquare()
        for z = cs:getZ() - 1, cs:getZ() + 1 do
            for x = cs:getX() - 12, cs:getX() + 12 do
                for y = cs:getY() - 12, cs:getY() + 12 do
                    local sq = not f.inv and cell:getGridSquare(x, y, z)
                    if sq then f.inv = LiveWire.Marks.findOnSquare(sq, f.invId) end
                end
            end
        end
    end
    return found
end

local function send(cmd, args)
    sendClientCommand(getPlayer(), LiveWire.MODULE, cmd, args)
end

local function via(f)
    local sq = f.comp:getSquare()
    return { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
end

function H.client.start(ctx)
    C.t0 = getTimestampMs()
    C.phase = "scan"
    return true
end

function H.client.done(ctx)
    local rep, P = C.rep, LiveWire.Protocol
    local now = getTimestampMs()
    if C.phase == "scan" then
        local list = scan()
        local ready = #list > 0
        for _, f in ipairs(list) do
            if not f.inv then ready = false end
        end
        if not ready then
            if now - C.t0 > 90000 then
                rep.rec(false, "client sees the network installed by the server", "computers=" .. #list)
                return true
            end
            return false
        end
        local pz = math.floor(getPlayer():getZ())
        for _, f in ipairs(list) do
            local m = LiveWire.Marks.get(f.inv)
            if m.z == pz then C.A = f else C.B = f end
        end
        rep.rec(C.A ~= nil, "client sees the marks of the network installed by the server",
            "networks=" .. #list .. (C.B and " (one on another floor)" or ""))
        if not C.A then return true end
        -- Subscribe from each computer (C02: the other floor is accepted).
        for _, f in ipairs({ C.A, C.B }) do
            if f then send(P.C_SUBSCRIBE, { inverter = f.invId, via = via(f) }) end
        end
        C.phase, C.t1 = "snapshot", now
        return false
    end
    if C.phase == "snapshot" then
        local snaps = LiveWire.Client.snapshots
        local all = snaps[C.A.invId] ~= nil and (not C.B or snaps[C.B.invId] ~= nil)
        if not all and now - C.t1 < 20000 then return false end
        rep.rec(snaps[C.A.invId] ~= nil, "A: snapshot received after subscribing from the computer")
        if C.B then
            rep.rec(snaps[C.B.invId] ~= nil, "B: snapshot received from a computer on another floor")
        end
        -- Inverter A is 5 tiles away: only the computer makes the command valid.
        send(P.C_SET_INVERTER, { inverter = C.A.invId, on = false, via = via(C.A) })
        C.phase, C.t1 = "off", now
        return false
    end
    if C.phase == "off" then
        local st = LiveWire.Marks.get(C.A.inv).st
        if st ~= "off" and now - C.t1 < 20000 then return false end
        rep.rec(st == "off", "A: inverter switched off from the computer (mark seen by the client)", "st=" .. tostring(st))
        send(P.C_SET_INVERTER, { inverter = C.A.invId, on = true, via = via(C.A) })
        C.phase, C.t1 = "on", now
        return false
    end
    if C.phase == "on" then
        local st = LiveWire.Marks.get(C.A.inv).st
        if st ~= "on" and now - C.t1 < 20000 then return false end
        rep.rec(st == "on", "A: inverter switched on again from the computer", "st=" .. tostring(st))
        return true
    end
    return true
end

function H.client.result(ctx)
    C.rep.check("no Lua error recorded on the client", function()
        local n = getLuaDebuggerErrorCount and getLuaDebuggerErrorCount() or 0
        return n == 0, "errors=" .. tostring(n)
    end)
    return C.rep.result()
end

return H
