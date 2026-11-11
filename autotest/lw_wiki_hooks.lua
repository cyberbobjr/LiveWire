-- LiveWire wiki screenshots (pzdev, solo). Scenarios autotest/scenarios/wiki_shots_base.json
-- (LiveWire alone) and wiki_shots_ext.json (with LiveWire Extended); see below.
local H = {}
local S = { lines = {}, ok = true }
local function rec(ok, name, detail)
    if not ok then S.ok = false end
    S.lines[#S.lines + 1] = (ok and "PASS " or "FAIL ") .. name .. " - " .. tostring(detail or "")
end

local X = LiveWire.Extended

-- A LiveWire device placed by the furniture code (sheet batman_livewire_01, tile n).
local function place(sq, n)
    local name = "batman_livewire_01_" .. n
    local props = ISMoveableSpriteProps.new(getSprite(name))
    local obj = props:placeMoveableInternal(S.player, sq, props:instanceItem(name), name)
    local m = LiveWire.Marks.get(obj)
    return m and LiveWire.Registry.device(m.id), obj
end

-- The coverage, not the energy balance, is shown: keep the inverter on.
local function holdPower(inv)
    local orig = LiveWire.Sim.updateAnchor
    LiveWire.Sim.updateAnchor = function(dev, on)
        if dev and dev.id == inv.id then on = true end
        return orig(dev, on)
    end
    inv.state = "on"
    LiveWire.Sim.updateAnchor(inv, true); LiveWire.Registry.grid(inv.grid).powered = true
end

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

local function clearZombies()
    local list = getCell() and getCell():getZombieList()
    if not list then return end
    for i = list:size() - 1, 0, -1 do
        local z = list:get(i)
        z:removeFromWorld(); z:removeFromSquare()
    end
end

local function untouchable(p)
    if p then p:setGodMod(true); p:setInvisible(true) end
end

local START, DONE = {}, {}

-- Screenshots of the wiki (docs/images/screenshots), one run per language: scenarios
-- wiki_shots_base.json (LiveWire alone: Extended has no inverter disc, D-44) and
-- wiki_shots_ext.json, with PZAT_OPTIONS=language=EN|FR and -P lang=en|fr. The scene is
-- built in the house next to the save's player (fixed squares of save 2026-10-17_17-50-04):
-- inverter in the living room on the public grid, solar panel and water pump with two rain
-- barrels outside, power bank; Extended: breaker board, power terminal. Debug watermark,
-- console, debug menu entries and the crafting window's debug lines hidden; player
-- untouchable, zombies cleared every tick. Menus are built by the real context-menu code;
-- the hovered entry is set directly (no mouse). Fixtures: positions imposed, time 13:00,
-- batteries set to 15 % (debug command) so that the inverter charges from the grid.
-- Raw captures land in the run folder; autotest/wiki_shots_crop.py crops them.
local WIKI = { steps = {}, at = 0, index = 0 }

local function wikiQuiet()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local t = ui:get(i):getTable()
        if t and t.Type == "WaterMarkUI" then t:setVisible(false) end
    end
    local console = UIManager.getDebugConsole and UIManager.getDebugConsole()
    if console then console:setVisible(false) end
    if ISCharacterInfoWindow and ISCharacterInfoWindow.instance then ISCharacterInfoWindow.instance:setVisible(false) end
    -- Inventory and loot panels unfold under a stray mouse pointer: hidden, as in the tutorials.
    if getPlayerInventory(0) then getPlayerInventory(0):setVisible(false) end
    if getPlayerLoot(0) then getPlayerLoot(0):setVisible(false) end
    getDebugOptions():setBoolean("UI.HideDebugContextMenuOptions", true)
    getDebugOptions():setBoolean("UI.uiShowContextMenuReportOptions", false)
end

local function wikiShot(name)
    local file = "wiki_" .. name .. "-" .. (S.ctx.params.lang or "en") .. ".png"
    local ok, err = pcall(takeScreenshot, file)
    rec(ok, "screenshot " .. file, err)
end

local function standAt(x, y, dir)
    local p = S.player
    p:setX(x); p:setY(y); p:setLastX(x); p:setLastY(y)
    if dir then p:setDir(dir) end
end

local function sqAt(x, y) return getCell():getGridSquare(x, y, 0) end

local function objectAt(x, y, sprite)
    local sq = sqAt(x, y)
    local objs = sq and sq:getObjects()
    for i = 0, objs and objs:size() - 1 or -1 do
        local o = objs:get(i)
        if o:getSprite() and o:getSprite():getName() == sprite then return o end
    end
    return nil
end

-- World context menu of `obj`, debug and test-driver entries removed, followed through the
-- submenus named in `path` ("*" = the first entry with a submenu); the last one is shown with
-- entry `hover` under the (virtual) mouse, so that its highlight and tooltip are drawn.
local function wikiStrip(menu)
    for i = #menu.options, 1, -1 do
        local n = tostring(menu.options[i].name)
        if n:find("PZDirector", 1, true) or n:find("^Debug") or n:find("^Admin") then
            menu:removeOptionByName(menu.options[i].name)
        end
    end
end

local function wikiCloseMenu()
    local m = WIKI.menu
    if not m then return end
    for _, sub in ipairs(m.chain) do sub:hideSelf() end
    m.ctx:closeAll()
    WIKI.menu = nil
end

local function wikiMenu(obj, path, hover)
    wikiCloseMenu()
    wikiQuiet()
    local ctx = ISWorldObjectContextMenu.createMenu(0, { obj }, 600, 220)
    wikiStrip(ctx)
    local chain, cur = { ctx }, ctx
    for _, label in ipairs(path) do
        local opt
        for _, o in ipairs(cur.options) do
            if o.subOption and (o.name == label or (label == "*" and not opt)) then opt = o end
        end
        if not opt then rec(false, "menu entry " .. tostring(label)); WIKI.menu = { ctx = ctx, chain = chain }; return nil end
        local sub = cur:getSubMenu(opt.subOption)
        wikiStrip(sub)
        cur:displaySubMenu(sub, opt)
        chain[#chain + 1] = sub
        cur = sub
    end
    WIKI.menu = { ctx = ctx, chain = chain, last = cur }
    if hover then
        for i, o in ipairs(cur.options) do
            if i == hover or o.name == hover then cur.mouseOver = i end
        end
        cur.mouseOut = false
    end
    return cur
end

local function wikiHover(menu, index)
    menu.mouseOver = index
    menu.mouseOut = false
end

local function makeBarrel(sq, litres)
    local obj = IsoThumpable.new(getCell(), sq, "carpentry_02_54", false)
    local fc = ComponentType.FluidContainer:CreateComponent()
    fc:setCapacity(100)
    GameEntityFactory.AddComponent(obj, true, fc)
    sq:AddSpecialObject(obj)
    obj:getFluidContainer():addFluid(Fluid.Water, litres)
    return obj
end

local function link(obj, target, x, y)
    standAt(x, y)
    local ok = LWLinkAction:new(S.player, obj, target):complete()
    rec(ok == true, "linked " .. tostring(obj:getSprite():getName()))
    return ok
end

-- Shared scene: inverter in the living room, solar panel in the side yard.
local function wikiScene()
    local p = S.player
    local inv, invObj = place(sqAt(10821, 9441), 12)
    local sol, solObj = place(sqAt(10821, 9446), 0)
    rec(inv ~= nil and sol ~= nil, "inverter and solar panel placed")
    S.inv, S.invObj, S.solObj = inv, invObj, solObj
    p:getInventory():AddItems("Base.ElectricWire", 40)
    p:getInventory():AddItem("Base.Screwdriver")
    p:getInventory():AddItem("LiveWire.VoltageTester")
end

local function step(wait, fn) WIKI.steps[#WIKI.steps + 1] = { wait = wait, fn = fn } end
-- Poll `cond` every 500 ms (at most `limit` ms) before going on.
local function waitFor(name, limit, cond)
    step(500, function()
        local w = WIKI
        w.waitStart = w.waitStart or getTimestampMs()
        if cond() then w.waitStart = nil; return end
        if getTimestampMs() - w.waitStart > limit then
            rec(false, "waited for " .. name)
            w.waitStart = nil
            return
        end
        w.index = w.index - 1
    end)
end

-- LiveWire alone: solar panel link menu, pump barrels, consumers, LCD, dismantle recipe.
local function wikiBase()
    local p = S.player
    wikiScene()
    local pump, pumpObj = place(sqAt(10818, 9446), 72)
    S.pumpObj = pumpObj
    S.barrel1 = makeBarrel(sqAt(10817, 9446), 80)
    S.barrel2 = makeBarrel(sqAt(10818, 9447), 60)
    p:getInventory():AddItems(LiveWire.Defs.PUMP_PIPE, 3)
    p:getInventory():AddItem("Base.Mov_LiveWire_Inverter")
    Events.EveryTenMinutes.Add(LiveWire.Sim.tick)
    local root = getText("ContextMenu_LW_Root")
    step(4000, function()
        standAt(10823.5, 9446.5, IsoDirections.W)
        local m = wikiMenu(S.solObj, { root, "*" })
        local linkTo = m and m:getOptionFromName(getText("ContextMenu_LW_LinkTo"))
        if linkTo then wikiHover(m, linkTo.id); WIKI.linkTo = linkTo end
    end)
    -- The hovered entry opens its submenu beside it: the wire count is in the same capture.
    step(1500, function() wikiShot("solar-menu") end)
    step(300, function()
        wikiCloseMenu()
        link(S.solObj, S.invObj, 10822.5, 9447.5)
        link(S.pumpObj, S.invObj, 10819.5, 9446.5)
        standAt(10820.5, 9447.5, IsoDirections.W)
    end)
    -- the "Connected." halo texts fade first
    step(5000, function()
        wikiMenu(S.pumpObj, { root, "*", getText("ContextMenu_LW_LinkBarrel") }, 1)
    end)
    step(1500, function()
        rec(S.barrel1:isHighlighted(0), "hovered barrel outlined")
        wikiShot("pump-barrels")
    end)
    step(300, function()
        wikiCloseMenu()
        getCore():doZoomScroll(0, -1)
        standAt(10820.5, 9443.5, IsoDirections.S)
        LiveWire.Demand.invalidate(S.inv.id)
        LiveWire.NetworkView.show(S.inv.id, "consumers")
    end)
    waitFor("consumer rows", 30000, function()
        local d = LiveWire.Registry.device(S.inv.id)
        LiveWire.Demand.measure(d, true)
        local snap = LiveWire.Client.snapshot(S.inv.id)
        return snap ~= nil and snap.consumers ~= nil and #snap.consumers > 0
    end)
    step(1200, function()
        local snap = LiveWire.Client.snapshot(S.inv.id)
        local lit, white = 0, 0
        for o in pairs(LiveWire.NetworkView.highlights) do
            lit = lit + 1
            local c = o:getHighlightColor(0)
            if o:isHighlighted(0) and c and c:getR() == 1 and c:getG() == 1 and c:getB() == 1 then white = white + 1 end
        end
        rec(LiveWire.NetworkView.gridActive(snap), "consumers on the public grid shown in white",
            #snap.consumers .. " rows, " .. lit .. " highlighted, " .. white .. " white")
        wikiShot("consumers-public-grid")
    end)
    step(300, function()
        LiveWire.NetworkView.hide()
        getCore():doZoomScroll(0, 1)
        local bank, bankObj = place(sqAt(10822, 9441), 16)
        local c = bankObj:getContainer()
        c:AddItem(instanceItem("Base.CarBattery2")); c:AddItem(instanceItem("Base.CarBattery2"))
        link(bankObj, S.invObj, 10822.5, 9442.5)
        LiveWire.Commands.handle(p, LiveWire.Protocol.C_DEBUG, { action = "battery15", device = S.inv.id })
        standAt(10821.5, 9442.5, IsoDirections.N)
    end)
    waitFor("public grid charging", 150000, function()
        local snap = LiveWire.Client.snapshot(S.inv.id)
        return snap ~= nil and (snap.gridW or 0) > 0
    end)
    step(300, function() wikiQuiet(); LiveWire.InverterPanel.open(p, S.inv.id) end)
    step(1500, function() wikiShot("inverter-mains") end)
    step(300, function() LiveWire.InverterPanel.instance.page = 3 end)
    step(1000, function() wikiShot("inverter-public-grid") end)
    step(300, function()
        LiveWire.InverterPanel.instance:close()
        -- The crafting window adds debug lines (recipe ids, tags, Force Action) under -debug.
        WIKI.isDebug = isDebugEnabled
        isDebugEnabled = function() return false end
        local r = getScriptManager():getCraftRecipe("LiveWire.LWDismantleInverter")
        ISEntityUI.OpenHandcraftWindow(p, nil, "*", false, r)
        local win
        for _, w in pairs(ISEntityUI.players[0].windows) do if w.instance then win = w.instance end end
        WIKI.craft = win
        local box = win.handCraftPanel.recipesPanel.recipeFilterPanel.searchEntryBox
        local word = r:getTranslationName():match("^(%S+)")
        box:setText(word)
        if box.onTextChange then box.onTextChange(box) end
        win.handCraftPanel.logic:setRecipe(r)
    end)
    step(2000, function() wikiShot("dismantle-recipe") end)
    step(300, function()
        isDebugEnabled = WIKI.isDebug
        if WIKI.craft then WIKI.craft:close() end
    end)
end

-- LiveWire Extended: Connect the building, board window and tint, terminal zone tool.
local function wikiExt()
    local p = S.player
    wikiScene()
    link(S.solObj, S.invObj, 10822.5, 9447.5)
    holdPower(S.inv)
    local fr = S.ctx.params.lang == "fr"
    -- the "Connected." / "installed" halo texts fade first
    step(5000, function()
        standAt(10822.5, 9443.5, IsoDirections.N)
        wikiMenu(S.invObj, { getText("ContextMenu_LWX_Root") }, 1)
    end)
    step(1500, function() wikiShot("connect-building") end)
    step(300, function()
        wikiCloseMenu()
        local bsq = sqAt(10821, 9439)
        local name = X.Terminal.SHEET .. "_8"
        local props = ISMoveableSpriteProps.new(getSprite(name))
        local board = props:placeMoveableInternal(p, bsq, props:instanceItem(name), name)
        S.board = board
        rec(X.Panels.link(p, board, S.invObj), "board linked")
        local inv = p:getInventory()
        for _, t in ipairs({ "Breaker20", "Breaker15", "Breaker20", "Breaker30", "TwilightSwitch" }) do inv:AddItem("LiveWire." .. t) end
        inv:AddItem("Base.Pencil")
        for _, t in ipairs({ "Breaker20", "Breaker15", "Breaker20", "Breaker30" }) do
            rec(X.Panels.installBreaker(p, board, "LiveWire." .. t), "breaker " .. t)
        end
        local labels = fr and { "Four", "TV", "Lits", "Porche" } or { "Oven", "TV", "Beds", "Porch" }
        for pos, text in ipairs(labels) do X.Panels.setLabel(p, board, pos, text) end
        rec(X.Panels.setTwilight(p, board, 4, true), "twilight switch fitted")
        for _, w in ipairs({ { 10818, 9435, "appliances_cooking_01_5", 1 }, { 10819, 9435, "lighting_indoor_01_0", 1 },
            { 10823, 9441, "appliances_television_01_7", 2 }, { 10820, 9441, "lighting_indoor_01_1", 2 },
            { 10820, 9439, "lighting_indoor_01_32", 2 }, { 10817, 9439, "lighting_indoor_01_13", 3 },
            { 10819, 9443, "lighting_indoor_01_2", 3 }, { 10826, 9438, "lighting_outdoor_01_27", 4 } }) do
            local o = objectAt(w[1], w[2], w[3])
            rec(o ~= nil and X.Points.connect(p, o, board, w[4]), "wired " .. w[3])
            if o and instanceof(o, "IsoLightSwitch") then o:setActive(true) end
        end
        X.Panels.setBreaker(p, board, 3, true)
        standAt(10822.5, 9441.5, IsoDirections.N)
    end)
    -- the wiring halo texts fade first
    step(5000, function()
        wikiQuiet()
        WIKI.win = X.BoardWindow.open(p, S.board)
        WIKI.win.selected = 4
    end)
    step(2000, function() wikiShot("board-window") end)
    step(300, function()
        WIKI.win.selected = nil
        WIKI.win:setX(0); WIKI.win:setY(60)
        standAt(10818.5, 9443.5)
    end)
    step(3000, function() wikiShot("board-tint") end)
    -- Locate on the Oven breaker, pressed through its button: the window must keep being drawn
    -- (prerender returns, no Lua error) for 60 frames and more, the oven lit in gold; pressed
    -- again, the region tint comes back.
    local oven = { 10818, 9435, "appliances_cooking_01_5" }
    local function color(o, c)
        local v = o and o:getHighlightColor(0)
        return o ~= nil and o:isHighlighted(0) and v ~= nil and math.abs(v:getR() - c[1]) < 0.01
            and math.abs(v:getG() - c[2]) < 0.01 and math.abs(v:getB() - c[3]) < 0.01
    end
    step(300, function()
        local win = WIKI.win
        WIKI.drawn = 0
        win.prerender = function(self)
            X.BoardWindow.prerender(self)
            WIKI.drawn = WIKI.drawn + 1
        end
        win.selected = 1
        standAt(10817.5, 9438.5, IsoDirections.SE)
    end)
    step(500, function()
        WIKI.locErrors, WIKI.drawn = getLuaDebuggerErrorCount(), 0
        local before = color(objectAt(oven[1], oven[2], oven[3]), X.BoardTint.COLORS.on)
        WIKI.win.btn.locate:forceClick()
        rec(WIKI.win.locating == 1, "Locate on the Oven breaker", "oven green before: " .. tostring(before))
    end)
    waitFor("60 frames in Locate", 30000, function() return WIKI.drawn >= 60 end)
    step(1500, function()
        local errs = getLuaDebuggerErrorCount() - WIKI.locErrors
        rec(errs == 0 and WIKI.drawn >= 60, "window drawn while locating",
            WIKI.drawn .. " frames, " .. errs .. " Lua errors")
        rec(color(objectAt(oven[1], oven[2], oven[3]), { 0.95, 0.75, 0.2 }), "oven lit in gold")
        wikiShot("board-locate")
    end)
    step(300, function()
        WIKI.locErrors, WIKI.drawn = getLuaDebuggerErrorCount(), 0
        WIKI.win.btn.locate:forceClick()
        rec(WIKI.win.locating == nil, "Locate turned off")
    end)
    waitFor("frames after Locate", 30000, function() return WIKI.drawn >= 30 end)
    step(300, function()
        local errs = getLuaDebuggerErrorCount() - WIKI.locErrors
        rec(errs == 0, "window drawn after Locate", WIKI.drawn .. " frames, " .. errs .. " Lua errors")
        local o = objectAt(oven[1], oven[2], oven[3])
        local v, inTint = o and o:getHighlightColor(0), 0
        for _ in pairs(WIKI.win.tint.lit or {}) do inTint = inTint + 1 end
        rec(color(o, X.BoardTint.COLORS.on), "oven tinted green again", "lit " .. tostring(o and o:isHighlighted(0))
            .. ", colour " .. (v and string.format("%.2f %.2f %.2f", v:getR(), v:getG(), v:getB()) or "nil")
            .. ", " .. inTint .. " tinted objects, oven tinted " .. tostring(o ~= nil and WIKI.win.tint.lit[o] ~= nil))
    end)
    step(300, function()
        WIKI.win:close()
        local tsq = freeGround(10815, 9449)
        local name = X.Terminal.SHEET .. "_0"
        local props = ISMoveableSpriteProps.new(getSprite(name))
        local term = props:placeMoveableInternal(p, tsq, props:instanceItem(name), name)
        rec(X.Terminals.link(p, term, S.invObj), "terminal linked")
        local tx, ty = tsq:getX(), tsq:getY()
        WIKI.tool = X.ZoneTool.open(p, term)
        WIKI.tool:setRect(tx - 6, ty - 1, tx + 3, ty + 6)
        rec(WIKI.tool.valid == true, "zone preview allowed (green)")
        for _ = 1, 2 do getCore():doZoomScroll(0, 1) end
        standAt(tx + 2.5, ty - 0.5, IsoDirections.SW)
    end)
    step(3000, function() wikiShot("zone-tool") end)
    step(300, function()
        WIKI.tool:close()
        for _ = 1, 2 do getCore():doZoomScroll(0, -1) end
    end)
end

function START.wiki()
    local p = S.player
    untouchable(p); clearZombies(); wikiQuiet()
    Events.OnTick.Add(clearZombies)
    getGameTime():setTimeOfDay(13)
    if S.ctx.params.part == "base" then wikiBase() else wikiExt() end
    WIKI.at = getTimestampMs()
end

function DONE.wiki()
    wikiQuiet()
    local w = WIKI
    if w.index >= #w.steps then return true end
    local nxt = w.steps[w.index + 1]
    if getTimestampMs() - w.at < nxt.wait then return false end
    w.index = w.index + 1
    w.at = getTimestampMs()
    nxt.fn()
    if w.index >= #w.steps then
        Events.OnTick.Remove(clearZombies)
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        return true
    end
    return false
end

function H.start(ctx)
    S.player, S.ctx = getPlayer(), ctx
    S.errors = getLuaDebuggerErrorCount()
    if ctx.params.part ~= "base" then rec(X ~= nil, "LiveWire Extended loaded") end
    START.wiki()
    return true
end

function H.done(ctx)
    clearZombies()
    return DONE.wiki()
end

function H.result(ctx)
    return { ok = S.ok, summary = "LiveWire wiki screenshots " .. tostring(ctx.params.part) .. " "
        .. tostring(ctx.params.lang or "en"), lines = S.lines }
end
return H
