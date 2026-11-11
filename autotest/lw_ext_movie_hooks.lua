-- LiveWire Extended movie (YouTube preview, English). A scripted tour in real places, with
-- the real actions (crafting window, furniture placement, timed actions with animations)
-- so that the recording looks like play. Steps run one after the other; each prints
--   [LWXMOVIE] caption <text>     (subtitle, shown from that moment)
-- and the recorder (record_movie.py) turns those lines into the subtitle file.
-- Scene 1: a house garage: craft a board and a breaker, place the inverter and the board,
--   link it, night: unwired lights go dark, install and label breakers, wire the lights and
--   the kitchen, switch, overload, reset, locate, energy.
-- Scene 2: another house with its own prewired, unlabelled board: link it and find out
--   which breaker feeds which room.
local H = {}
local S = { lines = {}, ok = true }
local X = LiveWire.Extended
local function rec(ok, name, detail)
    if not ok then S.ok = false end
    S.lines[#S.lines + 1] = (ok and "PASS " or "FAIL ") .. name .. " - " .. tostring(detail or "")
    print("[LWXMOVIE] " .. S.lines[#S.lines])
end
local function caption(text) print("[LWXMOVIE] caption " .. text) end

local HOUSE1 = { x = 10815, y = 9411 }       -- garage 10818,9411 6x5, kitchen 10815,9411 3x5
local GARAGE_TABLE = { 10818, 9413 }
local BOARD_SQ = { 10820, 9411 }
local INVERTER_SQ = { 10821, 9411 }
local HOUSE2 = { x = 10757, y = 9482 } -- vanilla electrical box on its east facade (10770,9487)

-- ---------------------------------------------------------------- helpers
local function sq(x, y, z) return getCell():getGridSquare(x, y, z or 0) end
local function player() return S.player end
local function idle() return ISTimedActionQueue.isPlayerDoingAction(S.player) == false end

local function quiet()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local t = ui:get(i):getTable()
        if t and t.Type == "WaterMarkUI" then t:setVisible(false) end
    end
    local console = UIManager.getDebugConsole and UIManager.getDebugConsole()
    if console then console:setVisible(false) end
    if ISCharacterInfoWindow and ISCharacterInfoWindow.instance then ISCharacterInfoWindow.instance:setVisible(false) end
    -- god mode stays on (its label is in the hidden watermark); no zombie may walk in
    local zs = getCell():getZombieList()
    for i = zs:size() - 1, 0, -1 do
        local z = zs:get(i)
        if z and math.abs(z:getX() - S.player:getX()) < 80 and math.abs(z:getY() - S.player:getY()) < 80 then
            z:removeFromWorld(); z:removeFromSquare()
        end
    end
end

-- set dressing: no corpse in the shot
local function clearBodies(radius)
    local px, py = math.floor(S.player:getX()), math.floor(S.player:getY())
    for y = py - radius, py + radius do
        for x = px - radius, px + radius do
            local s = getCell():getGridSquare(x, y, 0)
            local bodies = s and s:getDeadBodys()
            if bodies then
                for i = bodies:size() - 1, 0, -1 do
                    local b = bodies:get(i)
                    b:removeFromWorld(); b:removeFromSquare()
                end
            end
        end
    end
end

local function inventories(visible)
    if getPlayerInventory(0) then getPlayerInventory(0):setVisible(visible) end
    if getPlayerLoot(0) then getPlayerLoot(0):setVisible(visible) end
end

local function walkTo(x, y)
    local target = sq(x, y)
    if target then ISTimedActionQueue.add(ISWalkToTimedAction:new(S.player, target)) end
end

local function objectWith(square, test)
    local objs = square and square:getObjects()
    for i = 0, objs and objs:size() - 1 or -1 do
        if test(objs:get(i)) then return objs:get(i) end
    end
end

local function holdPower(inv)
    local orig = LiveWire.Sim.updateAnchor
    LiveWire.Sim.updateAnchor = function(dev, on) return orig(dev, (dev and dev.id == inv.id) or on) end
    inv.state = "on"
    LiveWire.Sim.updateAnchor(inv, true); LiveWire.Registry.grid(inv.grid).powered = true
end

-- Real furniture placement (the furniture cursor's action, with its animation).
local function placeItem(item, x, y, spriteName)
    local props = ISMoveableSpriteProps.new(getSprite(spriteName))
    local dir = props:getFaceDirectionFromSpriteName(spriteName)
    local target = sq(x, y)
    print("[LWXMOVIE] place " .. spriteName .. " item=" .. tostring(item and item:getFullType()) .. " dir=" .. tostring(dir)
        .. " canPlace=" .. tostring(props:canPlaceMoveable(S.player, target, item)))
    -- like the furniture cursor: walk next to the square first
    luautils.walkAdj(S.player, target, true)
    ISTimedActionQueue.add(ISMoveablesAction:new(S.player, target, "place", spriteName, nil, dir, item, nil))
end

-- Open the vanilla crafting window on a recipe, then start it as the Craft button does.
local function openCraft(recipeName)
    local recipe = getScriptManager():getCraftRecipe(recipeName)
    -- the debug session adds "( DBG:<recipe id> )" under the title: not for the movie
    local debugEnabled = isDebugEnabled
    isDebugEnabled = function() return false end
    local ok, err = pcall(ISEntityUI.OpenHandcraftWindow, S.player, nil, nil, false, recipe)
    isDebugEnabled = debugEnabled
    if not ok then error(err) end
end
local function craftWindow()
    local p = ISEntityUI.players and ISEntityUI.players[S.player:getPlayerNum()]
    local w = p and p.windows and p.windows.HandcraftWindow
    return w and w.instance
end
local function startCraft()
    local w = craftWindow()
    if w then ISEntityUI.HandcraftStart(S.player, w.handCraftPanel.logic, true, true) end
end
local function closeCraft()
    local w = craftWindow()
    if w then w:close() end
end

-- Right-click menu of the game on an object, shown at its place on the screen.
local function showMenu(obj)
    local num = S.player:getPlayerNum()
    local s = obj:getSquare()
    local x = isoToScreenX(num, s:getX() + 0.5, s:getY() + 0.5, s:getZ())
    local y = isoToScreenY(num, s:getX() + 0.5, s:getY() + 0.5, s:getZ())
    S.menu = ISWorldObjectContextMenu.createMenu(num, { obj }, x, y)
    -- debug-mode entries (the tests run the game with -debug) are not shown to players
    if S.menu then
        local names = {}
        for _, opt in ipairs(S.menu.options or {}) do
            local n = tostring(opt.name)
            if n:find("^Tile Report") or n:find("^Room Report") or n:find("^Coordinates Report") or n:find("^Seed") or n == "Debug"
                or n:find("^Inspect") or n:find("^Object") then names[#names + 1] = opt.name end
        end
        for _, n in ipairs(names) do S.menu:removeOptionByName(n) end
    end
    -- open the LiveWire Extended submenu like a mouse over would
    if S.menu then
        for _, opt in ipairs(S.menu.options or {}) do
            if opt.name == getText("ContextMenu_LWX_Root") and opt.subOption then
                local sub = S.menu:getSubMenu(opt.subOption)
                if sub then
                    sub:setX(S.menu:getX() + S.menu:getWidth()); sub:setY(S.menu:getY() + (opt.id or 1) * S.menu.itemHgt)
                    sub:setVisible(true)
                    S.subMenu = sub
                end
            end
        end
    end
end
local function closeMenu()
    for _, m in ipairs(S.subMenus or {}) do m:setVisible(false) end
    if S.subMenu then S.subMenu:setVisible(false) end
    if S.menu then S.menu:closeAll() end
    S.menu, S.subMenu, S.subMenus = nil, nil, nil
end

-- Right-click menu on `obj`, then each submenu of `path` opened as a mouse would, the last
-- entry highlighted: path = texts (or text prefixes) of the options to follow.
local function showMenuPath(obj, path)
    showMenu(obj)
    if S.subMenu then S.subMenu:setVisible(false) end
    S.subMenus = {}
    local cur = S.menu
    -- room on the right for the whole chain of submenus
    if cur then cur:setX(math.floor(getCore():getScreenWidth() * 0.12)); cur:setY(math.floor(getCore():getScreenHeight() * 0.28)) end
    for n, want in ipairs(path) do
        if not cur then return end
        -- "@object": the game's own submenu of the object when it has one, else LiveWire Extended
        if want == "@object" then
            want = X.Menu and X.Menu.objectSubMenu and X.Menu.objectSubMenu(cur, obj) and obj:getTileName()
                or getText("ContextMenu_LWX_Root")
            S.menuRoot = want
        end
        local found
        for i, opt in ipairs(cur.options or {}) do
            if not found and tostring(opt.name):sub(1, #want) == want then found = opt; cur.mouseOver = i end
        end
        if found and n < #path then found.toolTip = nil end
        if not found or not found.subOption then return end
        if n == #path then return end
        local sub = cur:getSubMenu(found.subOption)
        if not sub then return end
        sub:setX(cur:getX() + cur:getWidth() + 1)
        sub:setY(cur:getY() + cur.padTopBottom + ((found.id or 1) - 1) * cur.itemHgt)
        sub:setVisible(true)
        sub:bringToTop()
        S.subMenus[#S.subMenus + 1] = sub
        cur = sub
    end
end
local function wirePath(moduleText)
    return { "@object", getText("ContextMenu_LWX_ConnectPoint"), "Board ", moduleText }
end
local function speed(n) UIManager.getSpeedControls():SetCurrentGameSpeed(n) end

local function roomOf(name, def)
    local rooms = def:getRooms()
    for i = 0, rooms:size() - 1 do
        if rooms:get(i):getName() == name and rooms:get(i):getZ() == 0 then return rooms:get(i) end
    end
end

local function liveSwitchIn(roomDef)
    local s = sq(roomDef:getX() + 1, roomDef:getY() + 1, roomDef:getZ())
    local room = s and s:getRoom()
    local sw = room and room:getLightSwitches()
    for i = 0, sw and sw:size() - 1 or -1 do
        local o = sw:get(i)
        if o:getObjectIndex() ~= -1 then return o end
    end
end

-- ---------------------------------------------------------------- steps
-- { caption = text or nil, run = fn or nil, wait = seconds (minimum), untilIdle = bool, until_ = fn }
local STEPS = {}
local function step(t) STEPS[#STEPS + 1] = t end

step({ caption = "LiveWire Extended: breaker boards for your Live Wire power grid.", wait = 5 })
step({ caption = "Your inverter goes in the garage.", run = function()
    placeItem(S.inverterItem, INVERTER_SQ[1], INVERTER_SQ[2], "batman_livewire_01_12")
end, untilIdle = true, wait = 2 })
step({ run = function()
    local m = objectWith(sq(INVERTER_SQ[1], INVERTER_SQ[2]), function(o) return LiveWire.Marks.get(o) ~= nil end)
    S.invObj = m
    local mark = m and LiveWire.Marks.get(m)
    S.inv = mark and LiveWire.Registry.device(mark.id)
    if S.inv then holdPower(S.inv) end
    rec(S.inv ~= nil, "inverter placed by the real action")
    walkTo(GARAGE_TABLE[1] + 1, GARAGE_TABLE[2])
end, untilIdle = true })
step({ caption = "Craft a breaker board at a table: Electrical 3, sheet metal, wire and screws.", run = function()
    openCraft("LWXMakePanel16")
end, wait = 4 })
step({ caption = "Crafting takes a while: the game is sped up here.", run = function()
    startCraft(); closeCraft(); speed(3)
end, untilIdle = true, wait = 1 })
step({ caption = "Breakers come in 15, 20 and 30 A. Craft them, or find them at electricians' and in garages.", run = function()
    speed(1)
    openCraft("LWXMakeBreaker20")
end, wait = 4 })
step({ run = function() startCraft(); closeCraft(); speed(3) end, untilIdle = true, wait = 1 })
step({ run = function()
    speed(1)
    S.boardItem = S.player:getInventory():FindAndReturn("Base.Mov_LiveWire_Panel16")
    rec(S.boardItem ~= nil, "board crafted by the real recipe")
    rec(S.player:getInventory():getCountTypeRecurse("LiveWire.Breaker20") >= 1, "breaker crafted")
    walkTo(BOARD_SQ[1], BOARD_SQ[2] + 1)
end, untilIdle = true })
step({ caption = "Hang the board on a wall.", run = function()
    if S.boardItem then placeItem(S.boardItem, BOARD_SQ[1], BOARD_SQ[2], "batman_livewireext_01_10") end
end, untilIdle = true, wait = 2 })
step({ caption = "Night falls. Link the board to the inverter with electric wire.", run = function()
    S.board = X.Panel.onSquare(sq(BOARD_SQ[1], BOARD_SQ[2]))
    rec(S.board ~= nil, "board placed on the wall by the real action")
    getGameTime():setTimeOfDay(21.5)
    if S.board then showMenu(S.board) end
end, wait = 4 })
step({ run = function()
    closeMenu()
    if S.board then ISTimedActionQueue.add(LWXTerminalAction:new(S.player, S.board, S.invObj, false)) end
end, untilIdle = true, wait = 1 })
step({ caption = "The board now serves the house: lights and appliances wired to no breaker lose power.", run = function()
    rec(S.board and X.Panel.recordAt(S.board:getSquare()) ~= nil, "board linked by the real action")
end, wait = 6 })
step({ caption = "Open the board. Drag breakers from your inventory onto the empty modules.", run = function()
    inventories(true)
    S.win = X.BoardWindow.open(S.player, S.board)
    S.win:setX(getCore():getScreenWidth() - S.win:getWidth() - 20); S.win:setY(60)
end, wait = 3 })
step({ run = function()
    local it = S.player:getInventory():FindAndReturn("LiveWire.Breaker20")
    ISMouseDrag.dragging = { it }
end, wait = 2.5 })
step({ run = function()
    ISMouseDrag.dragging = nil
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, "LiveWire.Breaker20", 1, nil))
end, untilIdle = true, wait = 1 })
step({ run = function()
    local it = S.player:getInventory():FindAndReturn("LiveWire.Breaker15")
    ISMouseDrag.dragging = { it }
end, wait = 1.5 })
step({ run = function()
    ISMouseDrag.dragging = nil
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, "LiveWire.Breaker15", 2, nil))
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, "LiveWire.Breaker30", 3, nil))
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, "LiveWire.Breaker15", 4, nil))
end, untilIdle = true, wait = 1 })
step({ caption = "Write a label on each breaker with a pen or a pencil.", run = function()
    inventories(false)
    S.win.selected = 1
    S.win:onLabel()
end, wait = 1.5 })
step({ run = function()
    local box = ISTextBox and nil
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local t = ui:get(i):getTable()
        if t and t.Type == "ISTextBox" then box = t end
    end
    S.box = box
    if box then box.entry:setText("Kitchen") end
end, wait = 2 })
step({ run = function()
    if S.box then S.box:destroy() end
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, nil, 1, "label", "Kitchen"))
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, nil, 2, "label", "Lights"))
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, nil, 3, "label", "Oven"))
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, nil, 4, "label", "Garage"))
end, untilIdle = true, wait = 1 })
step({ caption = "Wire each appliance or room to its breaker, from the appliance itself.", run = function()
    S.win:setVisible(false)
    local kitchen = roomOf("kitchen", S.house1)
    S.kitchenSwitch = kitchen and liveSwitchIn(kitchen)
    S.fridge = objectWith(sq(10815, 9412), function(o) return o:getContainerByType("fridge") ~= nil or o:getContainerByType("freezer") ~= nil
        or (LiveWire.Appliances.saved(o) or {}).kind == "fridge" end)
    S.microwave = objectWith(sq(10817, 9411), function(o) return instanceof(o, "IsoStove") end)
    walkTo(10816, 9413)
end, untilIdle = true })
step({ caption = "Right-click the fridge, then Wire to a breaker board > the board > its breaker.", run = function()
    if S.fridge then showMenuPath(S.fridge, wirePath("module 1")) end
end, wait = 5 })
step({ caption = "Each connection takes electric wire for the distance, a screwdriver and Electrical 3.", run = function()
    inventories(true)
end, wait = 3 })
step({ run = function()
    closeMenu()
    if S.fridge then ISTimedActionQueue.add(LWXPointAction:new(S.player, S.fridge, S.board, 1, false)) end
end, untilIdle = true, wait = 2 })
step({ caption = "The microwave on the counter: same menu, same Kitchen breaker.", run = function()
    inventories(false)
    local o = S.microwave
    if not o then return end
    o:setHighlighted(true, false); o:setHighlightColor(1, 0.85, 0.2, 1)
    showMenuPath(o, wirePath("module 1"))
end, wait = 4 })
step({ run = function()
    closeMenu()
    local o = S.microwave
    if not o then return end
    ISTimedActionQueue.add(LWXPointAction:new(S.player, o, S.board, 1, false))
end, untilIdle = true, wait = 1 })
step({ run = function() if S.microwave then S.microwave:setHighlighted(false, false) end end, wait = 0.5 })
step({ caption = "And the oven, on the Kitchen breaker for now.", run = function()
    inventories(false)
    local o = S.stove
    if not o then return end
    o:setHighlighted(true, false); o:setHighlightColor(1, 0.85, 0.2, 1)
    showMenuPath(o, wirePath("module 1"))
end, wait = 4 })
step({ run = function()
    closeMenu()
    local o = S.stove
    if not o then return end
    ISTimedActionQueue.add(LWXPointAction:new(S.player, o, S.board, 1, false))
end, untilIdle = true, wait = 1 })
step({ run = function() if S.stove then S.stove:setHighlighted(false, false) end end, wait = 0.5 })

step({ caption = "Ceiling lights: right-click the wall switch of the room, Light Switch > Wire to a breaker board. It wires all the lights of that room.", run = function()
    if S.kitchenSwitch then walkTo(S.kitchenSwitch:getX(), S.kitchenSwitch:getY()) end
end, untilIdle = true, wait = 0.5 })
step({ run = function()
    if S.kitchenSwitch then showMenuPath(S.kitchenSwitch, wirePath("module 2")) end
end, wait = 5 })
step({ run = function()
    closeMenu()
    if S.kitchenSwitch then ISTimedActionQueue.add(LWXPointAction:new(S.player, S.kitchenSwitch, S.board, 2, false)) end
end, untilIdle = true, wait = 1 })
step({ caption = "Lamps have a switch of their own: right-click each lamp and wire it the same way, one by one.", run = function()
    S.lamp = objectWith(sq(10819, 9416), function(o) return instanceof(o, "IsoLightSwitch") end)
    if S.lamp then walkTo(10819, 9417) end
end, untilIdle = true, wait = 0.5 })
step({ run = function()
    if S.lamp then showMenuPath(S.lamp, wirePath("module 2")) end
end, wait = 5 })
step({ run = function()
    closeMenu()
    if S.lamp then ISTimedActionQueue.add(LWXPointAction:new(S.player, S.lamp, S.board, 2, false)) end
    rec(S.lamp ~= nil, "lamp found in the living room")
end, untilIdle = true, wait = 1 })
step({ caption = "Light is back: the kitchen and the lamp are now on the Lights breaker.", run = function()
    local garage = roomOf("garage", S.house1)
    S.garageSwitch = garage and liveSwitchIn(garage)
    walkTo(10820, 9413)
end, untilIdle = true, wait = 2 })
step({ run = function()
    if S.garageSwitch then ISTimedActionQueue.add(LWXPointAction:new(S.player, S.garageSwitch, S.board, 4, false)) end
end, untilIdle = true, wait = 1 })
step({ caption = "Switch a circuit off and on from the board.", run = function()
    S.win:setVisible(true)
    S.win.selected = 2
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, nil, 2, "off"))
end, untilIdle = true, wait = 3 })
step({ run = function()
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, nil, 2, "on"))
end, untilIdle = true, wait = 3 })
step({ caption = "Turn on the oven and the microwave on the same 20 A circuit...", run = function()
    S.win.selected = 1
    if S.stove then S.stove:setActivated(true) end
    if S.microwave then S.microwave:setActivated(true) end
    LiveWire.Demand.invalidate(S.inv.id)
end, wait = 2 })
step({ caption = "...and its breaker trips on its own: 20 A at 120 V is 2400 W.", run = function() end,
    until_ = function() return LiveWire.Demand.ready(S.inv) end, wait = 1 })
step({ run = function()
    LiveWire.Demand.measure(S.inv, true)
    X.Protection.check()
end, wait = 5 })
step({ caption = "The oven gets its own 30 A breaker. Reset the tripped one.", run = function()
    if S.stove then
        ISTimedActionQueue.add(LWXPointAction:new(S.player, S.stove, nil, nil, true))
        ISTimedActionQueue.add(LWXPointAction:new(S.player, S.stove, S.board, 3, false))
    end
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, nil, 1, "on"))
end, untilIdle = true, wait = 3 })
step({ caption = "Locate shows what a breaker feeds.", run = function()
    S.win.selected = 1
    S.win:locate(1)
end, wait = 5 })
step({ caption = "Each circuit shows its load in watts and amps, and the energy it used.", run = function()
    S.win:clearLocate()
    S.win.selected = 3
    LiveWire.Demand.measure(S.inv, true)
    X.Protection.check()
end, wait = 5 })
step({ caption = "A twilight switch keeps a circuit on only from dusk to dawn.", run = function()
    S.player:getInventory():AddItem("LiveWire.TwilightSwitch")
    S.win.selected = 4
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board, nil, 4, "twilightOn"))
end, untilIdle = true, wait = 4 })
-- Scene 2: a prewired house
step({ caption = "Many houses already have an electrical box on their wall: it becomes their breaker board.", run = function()
    S.win:close()
    getSandboxOptions():getOptionByName("LiveWireExtended.HouseBoardPercent"):setValue(100)
    -- in front of the box, outside
    S.player:setX(10771.5); S.player:setY(9488.5)
    S.player:setLastX(S.player:getX()); S.player:setLastY(S.player:getY())
end, wait = 4 })
step({ run = function()
    local list = getWorld():getMetaGrid():getBuildings()
    for i = 0, list:size() - 1 do
        local d = list:get(i)
        if d:getX() == HOUSE2.x and d:getY() == HOUSE2.y then S.house2 = d end
    end
end, until_ = function()
    return S.house2 and getCell():getGridSquare(S.house2:getX() + S.house2:getW() - 1, S.house2:getY() + S.house2:getH() - 1, 0) ~= nil
end, wait = 3 })
step({ run = function()
    -- the house board: inside or on the facade (one square around the building)
    local d = S.house2
    for y = d:getY() - 1, d:getY() + d:getH() do
        for x = d:getX() - 1, d:getX() + d:getW() do
            local o = sq(x, y) and X.Panel.onSquare(sq(x, y))
            if o and o:getModData().LWXHouse then S.board2 = o end
        end
    end
    rec(S.board2 ~= nil, "the second house has its own board")
    if S.board2 then
        local b = S.board2:getSquare()
        print("[LWXMOVIE] house board at " .. b:getX() .. "," .. b:getY() .. " " .. S.board2:getSprite():getName())
        clearBodies(20)
        S.board2:setHighlighted(true, false)
        S.board2:setHighlightColor(1, 0.85, 0.2, 1)
        -- the inverter indoors, just behind the wall of the box (or in its room when the box is inside)
        local ax, ay = X.Houses.acrossWall(b:getX(), b:getY(), S.board2:getSprite():getName())
        local inner = b:getRoom() and b or (ax and sq(ax, ay)) or b
        S.inner = inner
        local function clear(s)
            if not s or not s:getRoom() or s:getRoom() ~= inner:getRoom() or not s:isFree(false) then return false end
            local objs = s:getObjects()
            for i = 0, objs:size() - 1 do
                local o = objs:get(i)
                local name = o:getSprite() and o:getSprite():getName() or ""
                if o ~= s:getFloor() and o ~= s:getWall(true) and o ~= s:getWall(false)
                    and not name:find("^floors_") and not name:find("^blends_") then return false end
            end
            return true
        end
        for _, d in ipairs({ { 0, 0 }, { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 }, { 0, 2 }, { 0, -2 } }) do
            local s = sq(inner:getX() + d[1], inner:getY() + d[2])
            if clear(s) then S.inv2Sq = { s:getX(), s:getY() }; break end
        end
        print("[LWXMOVIE] inverter 2 at " .. tostring(S.inv2Sq and (S.inv2Sq[1] .. "," .. S.inv2Sq[2])))
    end
end, wait = 1 })
step({ caption = "This one hangs on the outside wall of the house.", wait = 4 })
step({ caption = "Your inverter stays indoors, just behind that wall.", run = function()
    getGameTime():setTimeOfDay(22)
    if S.board2 then S.board2:setHighlighted(false, false) end
    if not S.inv2Sq then return end
    -- inside, one step from where the inverter goes
    S.player:setX(S.inv2Sq[1] - 0.5); S.player:setY(S.inv2Sq[2] + 1.5)
    S.player:setLastX(S.player:getX()); S.player:setLastY(S.player:getY())
end, wait = 2 })
step({ run = function()
    if S.inv2Item and S.inv2Sq then placeItem(S.inv2Item, S.inv2Sq[1], S.inv2Sq[2], "batman_livewire_01_12") end
end, untilIdle = true, wait = 2 })
step({ caption = "Back outside at the box: right-click it, LiveWire Extended > Link to an inverter.", run = function()
    if not S.inv2Sq then return end
    S.inv2Obj = objectWith(sq(S.inv2Sq[1], S.inv2Sq[2]), function(x) return LiveWire.Marks.get(x) ~= nil end)
    rec(S.inv2Obj ~= nil, "second inverter placed by the real action")
    local m = S.inv2Obj and LiveWire.Marks.get(S.inv2Obj)
    S.inv2 = m and LiveWire.Registry.device(m.id)
    if S.inv2 then holdPower(S.inv2) end
    S.player:setX(10771.5); S.player:setY(9488.5)
    S.player:setLastX(S.player:getX()); S.player:setLastY(S.player:getY())
end, wait = 2 })
step({ run = function()
    if S.board2 then showMenuPath(S.board2, { getText("ContextMenu_LWX_Root"), getText("ContextMenu_LWX_LinkPanel"), "" }) end
end, wait = 5 })
step({ run = function()
    closeMenu()
    if S.board2 and S.inv2Obj then ISTimedActionQueue.add(LWXTerminalAction:new(S.player, S.board2, S.inv2Obj, false)) end
end, untilIdle = true, wait = 2 })
step({ caption = "It comes prewired: one breaker per room, without labels.", run = function()
    S.win = S.board2 and X.BoardWindow.open(S.player, S.board2)
    rec(S.win ~= nil, "house board window open")
    if not S.win then return end
    S.win:setX(getCore():getScreenWidth() - S.win:getWidth() - 20); S.win:setY(60)
end, wait = 4 })
step({ caption = "Switch the breakers off one by one to find out what each one feeds.", run = function()
    if not S.win then return end
    S.win.selected = 1
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board2, nil, 1, "off"))
end, untilIdle = true, wait = 3 })
step({ run = function()
    if not S.board2 then return end
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board2, nil, 1, "on"))
    S.win.selected = 2
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board2, nil, 2, "off"))
end, untilIdle = true, wait = 3 })
step({ caption = "Then label them yourself.", run = function()
    if not S.board2 then return end
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board2, nil, 2, "on"))
    ISTimedActionQueue.add(LWXBreakerAction:new(S.player, S.board2, nil, 2, "label", "Bedroom"))
end, untilIdle = true, wait = 3 })
step({ caption = "LiveWire Extended, an add-on for Live Wire. Coming soon on the Steam Workshop.", run = function()
    if S.win then S.win:close() end
end, wait = 5 })

-- ---------------------------------------------------------------- movie 2 (-P movie=2)
-- An outdoor power terminal carries the power of the garage inverter to the back garden,
-- its zone is drawn on the ground, a floodlight beyond the inverter's circle comes on,
-- and the powered places are shown (range view, inverter screen).
-- A clearing north of the garage, no building around: the terminal 12 squares from the
-- inverter (cable reach), its zone the terminal's block plus the block north of it (8 x 16,
-- all outdoors), the floodlight in that north block, beyond the inverter's circle (20).
local TERM_SQ = { 10821, 9399 }
local FLOOD_SQ = { 10820, 9387 }
local STEPS2 = {}
local function step2(t) STEPS2[#STEPS2 + 1] = t end
local function zoom(n) for _ = 1, math.abs(n) do pcall(function() getCore():doZoomScroll(0, n > 0 and 1 or -1) end) end end

step2({ caption = "LiveWire Extended: power exactly where you choose.", run = function()
    placeItem(S.inverterItem, INVERTER_SQ[1], INVERTER_SQ[2], "batman_livewire_01_12")
end, untilIdle = true, wait = 3 })
step2({ caption = "With LiveWire Extended, an inverter alone powers nothing: no circle around it any more.", run = function()
    S.invObj = objectWith(sq(INVERTER_SQ[1], INVERTER_SQ[2]), function(o) return LiveWire.Marks.get(o) ~= nil end)
    local mark = S.invObj and LiveWire.Marks.get(S.invObj)
    S.inv = mark and LiveWire.Registry.device(mark.id)
    rec(S.inv ~= nil, "inverter placed by the real action")
    if S.inv then holdPower(S.inv) end
    rec(not sq(10818, 9415):haveElectricity(), "the garage stays dark with the inverter alone (D-44)")
end, wait = 4 })
step2({ caption = "Right-click the inverter: LiveWire Extended > Connect the building.", run = function()
    if S.invObj then showMenuPath(S.invObj, { getText("ContextMenu_LWX_Root"), getText("ContextMenu_LWX_ConnectBuilding") }) end
end, wait = 4 })
step2({ caption = "The whole house gets power, and only the house.", run = function()
    closeMenu()
    if S.invObj then ISTimedActionQueue.add(LWXBuildingAction:new(S.player, S.invObj, false, nil)) end
end, until_ = function() return sq(10818, 9415):haveElectricity() end, untilIdle = true, wait = 4 })
step2({ caption = "Show the powered area outlines what the inverter serves: the building.", run = function()
    rec(sq(10818, 9415):haveElectricity(), "the garage has power once the building is connected")
    if S.inv then LiveWire.RangeView.show(S.inv.id, S.inv.x, S.inv.y, S.inv.z) end
    zoom(2)
end, wait = 5 })
step2({ caption = "Night falls. The clearing north of the house has no power.", run = function()
    LiveWire.RangeView.hide()
    zoom(-2)
    getGameTime():setTimeOfDay(23)
    S.player:setX(FLOOD_SQ[1] + 2.5); S.player:setY(FLOOD_SQ[2] - 1.5)
    S.player:setLastX(S.player:getX()); S.player:setLastY(S.player:getY())
end, wait = 3 })
step2({ caption = "A floodlight set up here stays dark: no power.", run = function()
    placeItem(S.floodItem, FLOOD_SQ[1], FLOOD_SQ[2], "lighting_outdoor_01_49")
end, untilIdle = true, wait = 2 })
step2({ run = function()
    S.flood = objectWith(sq(FLOOD_SQ[1], FLOOD_SQ[2]), function(o) return instanceof(o, "IsoLightSwitch") end)
    rec(S.flood ~= nil, "floodlight placed by the real action")
    if S.flood then S.flood:setActive(true, false, true) end
    rec(not sq(FLOOD_SQ[1], FLOOD_SQ[2]):haveElectricity(), "no power there before the terminal")
end, wait = 3 })
step2({ caption = "An outdoor power terminal carries power further. Place it within cable reach of the inverter.", run = function()
    placeItem(S.termItem, TERM_SQ[1], TERM_SQ[2], X.Terminal.SHEET .. "_0")
end, untilIdle = true, wait = 2 })
step2({ caption = "Right-click it: LiveWire Extended > Link to an inverter.", run = function()
    S.term = objectWith(sq(TERM_SQ[1], TERM_SQ[2]), function(o) return X.Terminal.isTerminal(o) end)
    rec(S.term ~= nil, "terminal placed by the real action")
    if S.term then showMenuPath(S.term, { getText("ContextMenu_LWX_Root"), getText("ContextMenu_LWX_LinkTerminal"), "" }) end
end, wait = 5 })
step2({ caption = "It takes one electric wire per 4 squares, a screwdriver and Electrical 3.", run = function()
    closeMenu()
    if S.term and S.invObj then ISTimedActionQueue.add(LWXTerminalAction:new(S.player, S.term, S.invObj, false)) end
end, untilIdle = true, wait = 2 })
step2({ caption = "Then LiveWire Extended > Set the zone.", run = function()
    rec(S.term and X.Terminal.recordAt(S.term:getSquare()) ~= nil, "terminal linked by the real action")
    if S.term then showMenuPath(S.term, { getText("ContextMenu_LWX_Root"), getText("ContextMenu_LWX_SetZone") }) end
end, wait = 3 })
step2({ caption = "Drag a rectangle on the ground: the outline shows the blocks that will get power.", run = function()
    closeMenu()
    if not S.term then return end
    S.tool = X.ZoneTool.open(S.player, S.term)
    local tcx, tcy = X.Zone.chunkOf(TERM_SQ[1], TERM_SQ[2])
    S.zr = { x0 = tcx * 8, y0 = (tcy - 1) * 8, x1 = tcx * 8 + 7, y1 = tcy * 8 + 7 }
    S.tool:setRect(S.zr.x1, S.zr.y1, S.zr.x1 - 1, S.zr.y1 - 1)
end, wait = 1 })
for k = 1, 4 do
    step2({ run = function()
        if not S.tool then return end
        local z = S.zr
        S.tool:setRect(z.x1, z.y1, z.x1 - math.floor((z.x1 - z.x0) * k / 4), z.y1 - math.floor((z.y1 - z.y0) * k / 4))
    end, wait = 0.6 })
end
step2({ caption = "Zones snap to whole blocks of 8 x 8 squares, up to 2 x 2 blocks, next to the terminal. Green: allowed. Apply.", run = function()
    rec(S.tool and S.tool.valid == true, "zone preview allowed")
end, wait = 3 })
step2({ run = function()
    if S.tool then S.tool:onApply() end
end, wait = 2 })
step2({ caption = "The floodlight comes on: the clearing has power.", run = function()
    if S.flood then S.flood:setActive(true, false, true) end
    walkTo(FLOOD_SQ[1] + 2, FLOOD_SQ[2] + 3)
end, until_ = function() return sq(FLOOD_SQ[1], FLOOD_SQ[2]):haveElectricity() end, untilIdle = true, wait = 5 })
step2({ caption = "Show the powered area again: the house, plus the blocks of the terminal. Nothing else.", run = function()
    rec(sq(FLOOD_SQ[1], FLOOD_SQ[2]):haveElectricity(), "the floodlight square has power through the zone")
    if S.inv then LiveWire.RangeView.show(S.inv.id, S.inv.x, S.inv.y, S.inv.z) end
    zoom(2)
end, wait = 6 })
step2({ caption = "The inverter's screen lists the buildings and terminals it powers.", run = function()
    LiveWire.RangeView.hide()
    zoom(-2)
    if S.inv and LiveWire.InverterPanel and LiveWire.InverterPanel.open then
        LiveWire.InverterPanel.open(S.player, S.inv.id, S.invObj)
        S.panel = LiveWire.InverterPanel.instance
        if S.panel then S.panel.page = 4 end
    end
    rec(S.panel ~= nil, "inverter screen open on page 4")
end, wait = 6 })
step2({ caption = "LiveWire Extended, an add-on for Live Wire. Coming soon on the Steam Workshop.", run = function()
    if S.panel and S.panel.close then S.panel:close() end
end, wait = 5 })

-- ---------------------------------------------------------------- setup and driver
function H.start(ctx)
    if ctx.params.movie == "2" then STEPS = STEPS2 end
    S.player = getPlayer()
    S.shots = ctx.params.shots == "1"
    S.errors = getLuaDebuggerErrorCount()
    Events.EveryTenMinutes.Remove(LiveWire.Sim.tick)
    getSandboxOptions():getOptionByName("ElecShutModifier"):setValue(0)
    -- movie 1 shows a breaker tripping (realistic profile); movie 2 keeps the default profile
    getSandboxOptions():getOptionByName("LiveWire.ConsumptionProfile"):setValue(ctx.params.movie == "2" and 3 or 1)
    local p = S.player
    p:setPerkLevelDebug(Perks.Electricity, 5)
    p:setGodMod(true)
    if p.setNoClip then p:setNoClip(false) end
    S.house1 = getWorld():getMetaGrid():getBuildingAt(HOUSE1.x + 1, HOUSE1.y + 1, 0)
    -- the start house must not have a board of its own (drawn at load, D-40)
    local rooms = S.house1:getRooms()
    for i = 0, rooms:size() - 1 do
        local r = rooms:get(i)
        local rects = r:getRects()
        for j = 0, rects:size() - 1 do
            local rc = rects:get(j)
            for y = rc:getY(), rc:getY() + rc:getH() - 1 do
                for x = rc:getX(), rc:getX() + rc:getW() - 1 do
                    local s = sq(x, y, r:getZ())
                    local o = s and X.Panel.onSquare(s)
                    if o then s:transmitRemoveItemFromSquare(o) end
                end
            end
        end
    end
    -- set dressing: clear the stacked crates on the north wall, so board and inverter
    -- go on a bare wall section (the board at 10820, the inverter on the floor beside it)
    local crateSq = sq(INVERTER_SQ[1], INVERTER_SQ[2])
    for i = crateSq:getObjects():size() - 1, 0, -1 do
        local o = crateSq:getObjects():get(i)
        if o:getContainer() then crateSq:transmitRemoveItemFromSquare(o) end
    end
    -- the oven of the kitchen
    S.stove = objectWith(sq(10817, 9414), function(o) return instanceof(o, "IsoStove") end)
    local inv = p:getInventory()
    -- the save's own items named in another language (an ID card) and the spare batteries: not for an English movie
    local items = inv:getItems()
    for i = items:size() - 1, 0, -1 do
        local it = items:get(i)
        local t = it:getType()
        if not p:isEquipped(it) and not it:isWorn() and (t:find("^IDcard") or t:find("Battery")) then
            inv:Remove(it)
        end
    end
    inv:AddItems("Base.SmallSheetMetal", 3)
    inv:AddItems("Base.ElectricWire", 40)
    if inv:getCountTypeRecurse("LiveWire.VoltageTester") == 0 then inv:AddItem("LiveWire.VoltageTester") end  -- needed to wire (Extended)
    inv:AddItems("Base.Screws", 20)
    inv:AddItems("Base.ElectronicsScrap", 6)
    inv:AddItem("Base.Screwdriver")
    inv:AddItem("Base.Pencil")
    for _, t in ipairs({ "LiveWire.Breaker15", "LiveWire.Breaker30", "LiveWire.Breaker15" }) do inv:AddItem(t) end
    S.inverterItem = inv:AddItem("Base.Mov_LiveWire_Inverter")
    S.termItem = inv:AddItem("Base.Mov_LiveWire_Terminal")
    do
        local props = ISMoveableSpriteProps.new(getSprite("lighting_outdoor_01_49"))
        S.floodItem = props:instanceItem("lighting_outdoor_01_49")
        if S.floodItem then inv:AddItem(S.floodItem) end
    end
    -- outdoor squares can be powered (the game's "generator outdoors" option)
    getSandboxOptions():getOptionByName("AllowExteriorGenerator"):setValue(true)
    S.inv2Item = inv:AddItem("Base.Mov_LiveWire_Inverter")
    getGameTime():setTimeOfDay(18.5)
    p:setX(10820.5); p:setY(9413.5); p:setLastX(p:getX()); p:setLastY(p:getY())
    local gs = sq(10818, 9415)
    local garageSwitch = gs and objectWith(gs, function(o) return instanceof(o, "IsoLightSwitch") end)
    if garageSwitch then garageSwitch:setActive(true, false, true) end
    inventories(false)
    quiet()
    clearBodies(20)
    S.i, S.at = 0, getTimestampMs()
    print("[LWXMOVIE] start")
    return true
end

function H.done(ctx)
    local now = getTimestampMs()
    local cur = STEPS[S.i]
    if cur then
        local elapsed = (now - S.at) / 1000
        if elapsed < (cur.wait or 0) then return false end
        if cur.untilIdle and not idle() and elapsed < 60 then return false end
        if cur.until_ and not cur.until_() and elapsed < 30 then return false end
    end
    S.i = S.i + 1
    local nextStep = STEPS[S.i]
    if not nextStep then
        print("[LWXMOVIE] end")
        rec(getLuaDebuggerErrorCount() == S.errors, "no Lua error", getLuaDebuggerErrorCount() - S.errors)
        return true
    end
    quiet()
    -- debug: a game screenshot at the end of each step (-P shots=1)
    if S.shots and S.i > 1 then pcall(takeScreenshot, string.format("step_%02d.png", S.i - 1)) end
    if nextStep.caption then caption(nextStep.caption) end
    if nextStep.run then
        local ok, err = pcall(nextStep.run)
        if not ok then rec(false, "step " .. S.i .. " ran", tostring(err)) end
    end
    print("[LWXMOVIE] step " .. S.i)
    S.at = now
    return false
end

function H.result() return { ok = S.ok, summary = "LiveWire Extended movie", lines = S.lines } end
return H
