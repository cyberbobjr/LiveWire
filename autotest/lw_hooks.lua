-- Live Wire in-game test (pz-autotest, single player).
-- 1. Checks through the vanilla furniture code paths (placeMoveable, pickUpMoveable,
--    rotateMoveable), the real timed action for linking, the real context menus,
--    and the client visuals (overlays), breaker, alarm, LCD panel, software, range.
-- 2. Then a staged scene with screenshots (Zomboid/Screenshots of the test cache,
--    collected by pz-autotest): lw_01_* to lw_08_*. Parameter shots=0 skips it.
local H = {}
local lines, okAll = {}, true

local function rec(ok, name, detail)
    if not ok then okAll = false end
    lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. name .. (detail and (" - " .. tostring(detail)) or "")
end

local function check(name, fn)
    local ok, res, detail = pcall(fn)
    if not ok then
        rec(false, name, "error: " .. tostring(res))
        return
    end
    rec(res == true, name, detail)
end

local SHEET = "batman_livewire_01_"
local p, cell, R
local S = {}   -- objects of the scene

local function hasOtherObjects(sq)
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        if objs:get(i) ~= sq:getFloor() then return true end
    end
    return sq:getWorldObjects():size() > 0
end

-- Free floor square near (cx, cy) matching `pred`, not yet used.
local used = {}
local function findSquare(pred, cx, cy, maxR, allowObjects)
    local px, py, pz = cx or math.floor(p:getX()), cy or math.floor(p:getY()), math.floor(p:getZ())
    for r = 1, maxR or 25 do
        for dx = -r, r do
            for dy = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local sq = cell:getGridSquare(px + dx, py + dy, pz)
                    local k = tostring(px + dx) .. "," .. tostring(py + dy)
                    if sq and not used[k] and sq:isSolidFloor() and not sq:HasStairs()
                        and (allowObjects or (sq:isFree(false) and not hasOtherObjects(sq))) and pred(sq) then
                        used[k] = true
                        return sq
                    end
                end
            end
        end
    end
    return nil
end

local function giveItem(t)
    return p:getInventory():AddItem(t)
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

local function place(item, spriteName, sq)
    giveItem(item)
    local props = ISMoveableSpriteProps.new(spriteName)
    local can = props:canPlaceMoveable(p, sq, nil)
    props:placeMoveable(p, sq, spriteName)
    return ourObject(sq, spriteName), can
end

local function standNear(sq)
    p:setX(sq:getX() + 1.5)
    p:setY(sq:getY() + 0.5)
end

local function overlays(obj)
    local out = {}
    local list = obj and obj:getAttachedAnimSprite()
    if list then
        for i = 0, list:size() - 1 do
            local spr = list:get(i):getParentSprite()
            out[#out + 1] = spr and spr:getName() or "?"
        end
    end
    return out
end

local function hasOverlay(obj, index)
    local name = SHEET .. tostring(index)
    for _, n in ipairs(overlays(obj)) do
        if n == name then return true end
    end
    return false
end

local function link(obj, inv)
    standNear(obj:getSquare())
    return LWLinkAction:new(p, obj, inv):complete()
end

local function gridOfInverter()
    local dev = R.device(LiveWire.Marks.get(S.inv).id)
    return R.grid(dev.grid), dev
end

local function refreshVisuals()
    for _, o in pairs(S) do
        if o and o.getSquare and o:getSquare() then
            LiveWire.Visuals.track(o)
            LiveWire.Visuals.apply(o, getTimestampMs())
        end
    end
end

local function menuOf(obj)
    local ctx = ISWorldObjectContextMenu.createMenu(0, { obj }, 420, 180)
    if not ctx then return nil, {} end
    local out = {}
    local function walk(menu, depth)
        for _, o in ipairs(menu.options) do
            if o.name then
                out[#out + 1] = string.rep("  ", depth) .. tostring(o.name) .. (o.notAvailable and " (x)" or "")
                if o.subOption then
                    local sub = menu:getSubMenu(o.subOption)
                    if sub then walk(sub, depth + 1) end
                end
            end
        end
    end
    local root = ctx:getOptionFromName(getText("ContextMenu_LW_Root"))
    if root and root.subOption then walk(ctx:getSubMenu(root.subOption), 0) end
    return ctx, out
end

local function contains(list, text)
    for i = 1, #list do
        if string.find(list[i], text, 1, true) then return true end
    end
    return false
end

-- Commands run at once on the authority (a client command waits for the next update).
local function command(cmd, args)
    LiveWire.Commands.handle(p, cmd, args)
end

local function debugAction(action)
    command(LiveWire.Protocol.C_DEBUG, { action = action, device = LiveWire.Marks.get(S.inv).id })
end

-------------------------------------------------------------------------------
-- 1. Checks
-------------------------------------------------------------------------------
local function runChecks()
    check("scripts: placeable items exist, heavy inverter removed", function()
        local sm = getScriptManager()
        return sm:FindItem("Base.Mov_LiveWire_Inverter") ~= nil and sm:FindItem("Base.Mov_LiveWire_WaterWheel") ~= nil
            and sm:FindItem("LiveWire.HeavyInverterKit") == nil and sm:FindItem("LiveWire.MonitorDisk") ~= nil
    end)
    check("tiles and overlays loaded", function()
        local s = getSprite(SHEET .. "16")
        local props = s and s:getProperties()
        return props ~= nil and props:get("container") == "livewirepowerbank" and getSprite(SHEET .. "48") ~= nil
            and getSprite(SHEET .. "24") ~= nil
    end)
    check("calculator dismantling gives a solar cell; panel needs 10 cells; loot lists", function()
        local sm = getScriptManager()
        local r = sm:getCraftRecipe("LiveWire.LWSalvageSolarCell") or sm:getCraftRecipe("LWSalvageSolarCell")
        local found = false
        local items = ProceduralDistributions.list.GarageTools.items
        for i = 1, #items do
            if items[i] == "LiveWire.SolarCell" then found = true end
        end
        local panelLoot = false
        items = ProceduralDistributions.list.ToolStoreMisc.items
        for i = 1, #items do
            if items[i] == "Base.Mov_LiveWire_SolarPanel" then panelLoot = true end
        end
        return r ~= nil and found and panelLoot, "recipe=" .. tostring(r ~= nil) .. " cells=" .. tostring(found)
            .. " panels=" .. tostring(panelLoot)
    end)
    check("registry ready (schema 2)", function()
        return R.ready and not R.readOnly and R.data.schema == 2
    end)

    -- Scene: inverter and power bank indoors, sources outdoors, wall devices.
    local inSq = findSquare(function(sq) return sq:getRoom() ~= nil end)
    local inSq2 = inSq and findSquare(function(sq) return sq:getRoom() ~= nil end, inSq:getX(), inSq:getY(), 4)
    local out1 = findSquare(function(sq) return sq:isOutside() end)
    local out2 = out1 and findSquare(function(sq) return sq:isOutside() end, out1:getX(), out1:getY(), 3)
    local out3 = out1 and findSquare(function(sq) return sq:isOutside() end, out1:getX(), out1:getY(), 4)
    local out4 = out1 and findSquare(function(sq) return sq:isOutside() end, out1:getX(), out1:getY(), 5)
    rec((inSq and inSq2 and out1 and out2 and out3 and out4) ~= nil, "test squares found")
    if not (inSq and inSq2 and out1 and out2 and out3 and out4) then return false end

    check("inverter placed indoors and registered", function()
        S.inv = place("Base.Mov_LiveWire_Inverter", SHEET .. "12", inSq)
        local m = S.inv and LiveWire.Marks.get(S.inv)
        return m ~= nil and R.device(m.id).role == "inverter" and S.inv:getContainer() == nil, "st=" .. tostring(m and m.st)
    end)
    check("power bank: empty container that accepts car batteries", function()
        S.bank = place("Base.Mov_LiveWire_PowerBank", SHEET .. "16", inSq2)
        local c = S.bank and S.bank:getContainer()
        if not c then return false, "no container" end
        local n = c:getItems():size()
        c:AddItem(instanceItem("Base.CarBattery2"))
        c:AddItem(instanceItem("Base.CarBattery2"))
        return c:getType() == "livewirepowerbank" and n == 0 and c:getItems():size() == 2
    end)
    check("solar panel refused indoors", function()
        local it = giveItem("Base.Mov_LiveWire_SolarPanel")
        local sq = findSquare(function(s) return s:getRoom() ~= nil end)
        local refused = sq ~= nil and ISMoveableSpriteProps.new(SHEET .. "0"):canPlaceMoveableInternal(p, sq, it) == false
        p:getInventory():Remove(it)
        return refused
    end)
    check("sources placed outdoors", function()
        S.solar1 = place("Base.Mov_LiveWire_SolarPanel", SHEET .. "0", out1)
        S.solar2 = place("Base.Mov_LiveWire_SolarPanel", SHEET .. "0", out2)
        S.wind = place("Base.Mov_LiveWire_WindTurbine", SHEET .. "4", out3)
        return S.solar1 ~= nil and S.solar2 ~= nil and S.wind ~= nil
    end)
    check("water wheel refused away from a river", function()
        local ok, why = LiveWire.Placement.check("WaterWheel", out4)
        return LiveWire.Placement.nextToRiver(out4) or (ok == false and why == "Tooltip_LW_NeedWaterSide")
    end)
    check("wall breaker and alarm placed with the vanilla cursor code", function()
        giveItem("Base.Mov_LiveWire_Breaker")
        giveItem("Base.Mov_LiveWire_BatteryAlarm")
        local props = ISMoveableSpriteProps.new(SHEET .. "20")
        local sq = findSquare(function(s)
            return s:getRoom() ~= nil and props:canPlaceMoveable(p, s, nil) and true or false
        end, inSq:getX(), inSq:getY(), 10, true)
        if not sq then return false, "no wall found" end
        props:placeMoveable(p, sq, SHEET .. "20")
        S.breaker = ourObject(sq, SHEET .. "20")
        local aprops = ISMoveableSpriteProps.new(SHEET .. "22")
        local sq2 = findSquare(function(s)
            return s:getRoom() ~= nil and aprops:canPlaceMoveable(p, s, nil) and true or false
        end, sq:getX(), sq:getY(), 10, true)
        if sq2 then
            aprops:placeMoveable(p, sq2, SHEET .. "22")
            S.alarm = ourObject(sq2, SHEET .. "22")
        end
        return S.breaker ~= nil and S.alarm ~= nil, "breaker " .. sq:getX() .. "," .. sq:getY()
    end)
    check("everything linked by the real timed action", function()
        for _ = 1, 30 do giveItem("Base.ElectricWire") end
        local all = { "solar1", "solar2", "wind", "bank", "breaker", "alarm" }
        local okAll2 = true
        for _, k in ipairs(all) do
            if not S[k] or link(S[k], S.inv) ~= true then okAll2 = false end
        end
        local g = gridOfInverter()
        local n = 0
        for _ in pairs(g.members) do n = n + 1 end
        return okAll2 and n == 6, "members=" .. n
    end)
    check("green lights on connected equipment, blades on the turbine", function()
        LiveWire.Sim.refresh(gridOfInverter())
        refreshVisuals()
        local ok = hasOverlay(S.solar1, 36) and hasOverlay(S.bank, 32) and hasOverlay(S.wind, 40)
        local blades = false
        for f = 0, 3 do
            if hasOverlay(S.wind, 48 + 4 * f) then blades = true end
        end
        return ok and blades, table.concat(overlays(S.wind), " ")
    end)
    check("inverter screen lit when on", function()
        local m = LiveWire.Marks.get(S.inv)
        return m.st == "on" and hasOverlay(S.inv, 24), "st=" .. tostring(m.st) .. " pw=" .. tostring(m.pw)
    end)
    check("overload trips the breaker, not the inverter; reset on the breaker", function()
        debugAction("trip")
        refreshVisuals()
        local g, inv = gridOfInverter()
        local bm = LiveWire.Marks.get(S.breaker)
        local tripped = bm.st == "tripped" and inv.state == "on" and not g.powered and hasOverlay(S.breaker, 64)
        local ctx, out = menuOf(S.breaker)
        if ctx then ctx:closeAll() end
        local hasReset = contains(out, getText("ContextMenu_LW_ResetBreaker"))
        standNear(S.breaker:getSquare())
        command(LiveWire.Protocol.C_RESET_BREAKER, { device = bm.id })
        refreshVisuals()
        local reset = LiveWire.Marks.get(S.breaker).st == "ok" and not hasOverlay(S.breaker, 64)
        return tripped and hasReset and reset, "tripped=" .. tostring(tripped) .. " menu=" .. tostring(hasReset)
            .. " reset=" .. tostring(reset)
    end)
    check("low battery: alarm rings, keeps its light after being silenced", function()
        standNear(S.inv:getSquare())
        debugAction("battery15")
        refreshVisuals()
        local m = LiveWire.Marks.get(S.alarm)
        local ringing = m.st == "ringing" and hasOverlay(S.alarm, 66)
        standNear(S.alarm:getSquare())
        command(LiveWire.Protocol.C_ACK_ALARM, { device = m.id })
        LiveWire.Sim.refresh(gridOfInverter())
        refreshVisuals()
        local g = gridOfInverter()
        local still = LiveWire.Marks.get(S.alarm).st == "ringing" and g.alarmAck == true and hasOverlay(S.alarm, 66)
        return ringing and still, "ringing=" .. tostring(ringing) .. " still=" .. tostring(still)
    end)
    check("inverter menu", function()
        standNear(S.inv:getSquare())
        local ctx, out = menuOf(S.inv)
        if ctx then ctx:closeAll() end
        for i = 1, #out do
            if not string.find(out[i], "Debug", 1, true) and string.sub(out[i], 1, 4) ~= "    " then
                lines[#lines + 1] = "    | " .. out[i]
            end
        end
        return contains(out, getText("ContextMenu_LW_Panel")) and contains(out, getText("ContextMenu_LW_ShowRange"))
    end)
    check("LCD panel and software open", function()
        local id = LiveWire.Marks.get(S.inv).id
        LiveWire.InverterPanel.open(p, id)
        LiveWire.SoftwareScreen.open(p, id, nil)
        local ok = LiveWire.InverterPanel.instance ~= nil and LiveWire.SoftwareScreen.instance ~= nil
        LiveWire.SoftwareScreen.instance:close()
        LiveWire.InverterPanel.instance:close()
        return ok
    end)
    check("powered area outline", function()
        local sq = S.inv:getSquare()
        LiveWire.RangeView.show(LiveWire.Marks.get(S.inv).id, sq:getX(), sq:getY(), sq:getZ())
        return LiveWire.RangeView.isShown(LiveWire.Marks.get(S.inv).id)
    end)
    check("rotating the inverter keeps its links", function()
        local id = LiveWire.Marks.get(S.inv).id
        local sq = S.inv:getSquare()
        standNear(sq)
        ISMoveableSpriteProps.new(SHEET .. "13"):rotateMoveable(p, sq, SHEET .. "12")
        S.inv = ourObject(sq, SHEET .. "13")
        local g = gridOfInverter()
        local n = 0
        for _ in pairs(g.members) do n = n + 1 end
        return S.inv ~= nil and LiveWire.Marks.get(S.inv).id == id and n == 6
    end)
    check("picking a panel up keeps its condition", function()
        local sq = S.solar2:getSquare()
        local id = LiveWire.Marks.get(S.solar2).id
        R.device(id).cond = 77
        standNear(sq)
        ISMoveableSpriteProps.new(SHEET .. "0"):pickUpMoveable(p, sq, true)
        local gone = ourObject(sq, SHEET .. "0") == nil and R.device(id) == nil
        ISMoveableSpriteProps.new(SHEET .. "0"):placeMoveable(p, sq, SHEET .. "0")
        S.solar2 = ourObject(sq, SHEET .. "0")
        local m = S.solar2 and LiveWire.Marks.get(S.solar2)
        local cond = m and R.device(m.id) and R.device(m.id).cond
        local relinked = S.solar2 ~= nil and link(S.solar2, S.inv) == true
        return gone and cond == 77 and relinked, "cond=" .. tostring(cond)
    end)
    check("simulation step runs", function()
        debugAction("battery100")
        LiveWire.Sim.tick()
        local snap = LiveWire.Sim.snapshot(gridOfInverter())
        return snap ~= nil and #snap.sources == 3 and snap.breaker ~= nil and snap.alarm ~= nil
    end)
    return true
end

-------------------------------------------------------------------------------
-- 2. Staged scene with screenshots (driven by H.done, polled every 250 ms)
-------------------------------------------------------------------------------
local steps = {}
local stepIndex, stepAt = 0, 0
local shots = 0

local function shot(name)
    local ok, err = pcall(takeScreenshot, name .. ".png")
    if ok then shots = shots + 1 else lines[#lines + 1] = "INFO screenshot failed: " .. tostring(err) end
end

local function hideWindows()
    if ISCharacterInfoWindow and ISCharacterInfoWindow.instance then ISCharacterInfoWindow.instance:setVisible(false) end
    if LiveWire.InverterPanel.instance then LiveWire.InverterPanel.instance:close() end
    if LiveWire.SoftwareScreen.instance then LiveWire.SoftwareScreen.instance:close() end
    local console = UIManager.getDebugConsole and UIManager.getDebugConsole()
    if console then console:setVisible(false) end
end

local function buildSteps()
    local function at(sq)
        p:setX(sq:getX() + 0.5)
        p:setY(sq:getY() + 2.5)
    end
    steps = {
        { wait = 500, fn = function()
            hideWindows()
            LiveWire.RangeView.hide()
            getGameTime():setTimeOfDay(13)
            at(S.solar1:getSquare())
            refreshVisuals()
        end },
        { wait = 2500, fn = function() shot("lw_01_sources") end },
        { wait = 200, fn = function()
            -- Inside the room (walls cut away), behind the inverter so as not to hide it.
            local isq = S.inv:getSquare()
            p:setX(isq:getX() - 0.5)
            p:setY(isq:getY() - 0.5)
            refreshVisuals()
        end },
        { wait = 2000, fn = function() shot("lw_02_inverter_bank") end },
        { wait = 200, fn = function()
            debugAction("trip")
            debugAction("battery15")
            refreshVisuals()
            at(S.breaker:getSquare())
        end },
        { wait = 2000, fn = function() shot("lw_03_breaker_alarm") end },
        { wait = 200, fn = function()
            standNear(S.breaker:getSquare())
            command(LiveWire.Protocol.C_RESET_BREAKER, { device = LiveWire.Marks.get(S.breaker).id })
            debugAction("battery100")
            at(S.inv:getSquare())
            LiveWire.InverterPanel.open(p, LiveWire.Marks.get(S.inv).id)
        end },
        { wait = 1500, fn = function() shot("lw_04_lcd_page1") end },
        { wait = 200, fn = function() LiveWire.InverterPanel.instance.page = 2 end },
        { wait = 800, fn = function() shot("lw_05_lcd_page2") end },
        { wait = 200, fn = function()
            LiveWire.InverterPanel.instance:close()
            LiveWire.SoftwareScreen.open(p, LiveWire.Marks.get(S.inv).id, nil)
        end },
        { wait = 2500, fn = function() shot("lw_06_software") end },
        { wait = 200, fn = function()
            LiveWire.SoftwareScreen.instance:close()
            local sq = S.inv:getSquare()
            LiveWire.RangeView.show(LiveWire.Marks.get(S.inv).id, sq:getX(), sq:getY(), sq:getZ())
            for _ = 1, 8 do getCore():doZoomScroll(0, 1) end
        end },
        { wait = 3500, fn = function() shot("lw_07_range") end },
        { wait = 200, fn = function()
            for _ = 1, 8 do getCore():doZoomScroll(0, -1) end
            LiveWire.RangeView.hide()
            at(S.solar1:getSquare())
            standNear(S.solar1:getSquare())
            menuOf(S.solar1)
        end },
        { wait = 1500, fn = function() shot("lw_08_menu") end },
    }
    -- Fridge while the player is away: fresh steak in a powered fridge, the player
    -- leaves (the area unloads), 10 game hours pass, the player comes back.
    local F = {}
    local function findFridge()
        local c = S.inv:getSquare()
        for r = 0, 15 do
            for dx = -r, r do
                for dy = -r, r do
                    local sq = cell:getGridSquare(c:getX() + dx, c:getY() + dy, c:getZ())
                    if sq then
                        local objs = sq:getObjects()
                        for i = 0, objs:size() - 1 do
                            local cont = objs:get(i):getContainerByType("fridge")
                            if cont then return cont, sq end
                        end
                    end
                end
            end
        end
        return nil
    end
    local function fridgeAt()
        local sq = cell:getGridSquare(F.sq.x, F.sq.y, F.sq.z)
        local objs = sq and sq:getObjects()
        if not objs then return nil end
        for i = 0, objs:size() - 1 do
            local cont = objs:get(i):getContainerByType("fridge")
            if cont then return cont end
        end
        return nil
    end
    local function findSteak()
        local cont = fridgeAt()
        if not cont then return nil end
        local items = cont:getItems()
        for i = 0, items:size() - 1 do
            if items:get(i):getID() == F.id then return items:get(i) end
        end
        return nil
    end
    local more = {
        { wait = 500, fn = function()
            menuOf(S.solar1):closeAll()
            debugAction("battery100")
            local cont, sq = findFridge()
            if not cont then
                rec(true, "fridge while away", "SKIP no fridge in the house")
                F.skip = true
                return
            end
            F.sq = { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
            local steak = cont:AddItem("Base.Steak")
            steak:updateAge()
            F.id, F.age0 = steak:getID(), steak:getAge()
            F.powered0 = sq:haveElectricity()
            F.home = { x = p:getX(), y = p:getY() }
            p:setX(p:getX() + 300)
            p:setLastX(p:getX())
        end },
        { wait = 6000, fn = function()
            if F.skip then return end
            F.loadedAway = cell:getGridSquare(F.sq.x, F.sq.y, F.sq.z) ~= nil
            getGameTime():setTimeOfDay(23)
            LiveWire.Sim.tick()
            local g = gridOfInverter()
            F.poweredSim = g and g.powered
        end },
        { wait = 1500, fn = function()
            if F.skip then return end
            p:setX(F.home.x)
            p:setY(F.home.y)
            p:setLastX(p:getX())
            p:setLastY(p:getY())
        end },
        { wait = 3000, fn = function()
            if F.skip then return end
            local sq = cell:getGridSquare(F.sq.x, F.sq.y, F.sq.z)
            local steak = sq and findSteak()
            F.tries = (F.tries or 0) + 1
            if (not sq or not steak) and F.tries < 8 then
                stepIndex = stepIndex - 1   -- try again in 3 s
                return
            end
            if not sq or not steak then
                local cont = sq and fridgeAt()
                local list = {}
                if cont then
                    local items = cont:getItems()
                    for i = 0, items:size() - 1 do list[#list + 1] = items:get(i):getFullType() .. "#" .. items:get(i):getID() end
                end
                rec(false, "fridge while away", "square " .. tostring(sq ~= nil) .. ", fridge " .. tostring(cont ~= nil)
                    .. ", wanted #" .. tostring(F.id) .. ", in fridge: " .. table.concat(list, " ")
                    .. ", player " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()))
                return
            end
            local powered = sq:haveElectricity()
            steak:updateAge()
            local delta = steak:getAge() - F.age0
            -- 10 h at room speed = 0.417 day; in a powered fridge x FridgeFactor (0.2 by default).
            rec(powered and delta < 0.2 and not F.loadedAway,
                "fridge keeps food cold while the player is away (area unloaded, 10 h)",
                string.format("aged %.3f d (warm would be 0.417), powered now %s, before %s, sim %s, unloaded %s",
                    delta, tostring(powered), tostring(F.powered0), tostring(F.poweredSim), tostring(not F.loadedAway)))
        end },
    }
    for i = 1, #more do steps[#steps + 1] = more[i] end
end

function H.start(ctx)
    p = getPlayer()
    cell = getCell()
    R = LiveWire.Registry
    p:setPerkLevelDebug(Perks.Electricity, 10)
    giveItem("Base.Screwdriver")
    local ok, res = pcall(runChecks)
    if not ok then rec(false, "checks aborted", res) end
    if ok and res and ctx.params.shots ~= "0" then buildSteps() end
    stepIndex, stepAt = 0, getTimestampMs()
    return true
end

function H.done(ctx)
    if stepIndex >= #steps then return true end
    local now = getTimestampMs()
    local nextStep = steps[stepIndex + 1]
    if now - stepAt < nextStep.wait then return false end
    stepIndex = stepIndex + 1
    stepAt = now
    local ok, err = pcall(nextStep.fn)
    if not ok then lines[#lines + 1] = "INFO scene step " .. stepIndex .. " failed: " .. tostring(err) end
    return stepIndex >= #steps
end

function H.result(ctx)
    check("no Lua error recorded", function()
        local n = getLuaDebuggerErrorCount and getLuaDebuggerErrorCount() or 0
        return n == 0, "errors=" .. tostring(n)
    end)
    local pass, total = 0, 0
    for i = 1, #lines do
        local head = lines[i]:sub(1, 4)
        if head == "PASS" then pass = pass + 1 end
        if head == "PASS" or head == "FAIL" then total = total + 1 end
    end
    lines[#lines + 1] = "INFO screenshots: " .. tostring(shots)
    return { ok = okAll, summary = tostring(pass) .. "/" .. tostring(total) .. " PASS", lines = lines }
end

return H
