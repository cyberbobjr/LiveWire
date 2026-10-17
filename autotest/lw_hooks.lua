-- Live Wire in-game test (pz-autotest, single player). Uses the vanilla furniture
-- code paths (placeMoveable, pickUpMoveable, rotateMoveable) and the real timed
-- action for linking. Leaves the placed devices next to the player for the
-- final screenshot.
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
local p, cell

local function hasOtherObjects(sq)
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        if objs:get(i) ~= sq:getFloor() then return true end
    end
    return sq:getWorldObjects():size() > 0
end

-- Free floor square near the player matching `pred`, not yet used.
local used = {}
local function findSquare(pred)
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for r = 1, 25 do
        for dx = -r, r do
            for dy = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local sq = cell:getGridSquare(px + dx, py + dy, pz)
                    local k = tostring(px + dx) .. "," .. tostring(py + dy)
                    if sq and not used[k] and sq:isSolidFloor() and sq:isFree(false) and not sq:HasStairs()
                        and not hasOtherObjects(sq) and pred(sq) then
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

-- Text of the "Live Wire" part of a real vanilla world context menu.
local function liveWireMenu(obj)
    local ctx = ISWorldObjectContextMenu.createMenu(0, { obj }, 400, 200)
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

function H.start(ctx)
    p = getPlayer()
    cell = getCell()
    p:setPerkLevelDebug(Perks.Electricity, 10)
    giveItem("Base.Screwdriver")
    for _ = 1, 20 do giveItem("Base.ElectricWire") end
    local R = LiveWire.Registry
    local inv, bank, solar

    check("scripts: placeable items exist, heavy inverter removed", function()
        local sm = getScriptManager()
        return sm:FindItem("Base.Mov_LiveWire_Inverter") ~= nil and sm:FindItem("Base.Mov_LiveWire_WaterWheel") ~= nil
            and sm:FindItem("LiveWire.HeavyInverterKit") == nil and sm:FindItem("LiveWire.VoltageTester") ~= nil
    end)
    check("tiles: sprites loaded with properties", function()
        local s = getSprite(SHEET .. "16")
        local props = s and s:getProperties()
        return props ~= nil and props:has("IsMoveAble") and props:get("container") == "livewirepowerbank",
            "container=" .. tostring(props and props:get("container"))
    end)
    check("item name from Moveables.json", function()
        local it = instanceItem("Base.Mov_LiveWire_Inverter")
        return it:getDisplayName() ~= nil and it:getWorldSprite() == SHEET .. "12", it:getDisplayName()
    end)
    check("registry migrated (schema 2)", function()
        return R.ready and not R.readOnly and R.data.schema == 2, "schema=" .. tostring(R.data.schema)
    end)

    local inSq = findSquare(function(sq) return sq:getRoom() ~= nil end)
    local outSq = findSquare(function(sq) return sq:isOutside() end)
    local inSq2 = findSquare(function(sq) return sq:getRoom() ~= nil end)
    local outSq2 = findSquare(function(sq) return sq:isOutside() end)
    rec(inSq ~= nil and outSq ~= nil and inSq2 ~= nil and outSq2 ~= nil, "test squares found",
        "player " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()) .. "," .. math.floor(p:getZ()))
    if not (inSq and outSq and inSq2 and outSq2) then return true end

    check("inverter placed indoors with the vanilla cursor code and registered", function()
        local obj = place("Base.Mov_LiveWire_Inverter", SHEET .. "12", inSq)
        if not obj then return false, "no object" end
        local m = LiveWire.Marks.get(obj)
        local dev = m and R.device(m.id)
        inv = obj
        return dev ~= nil and dev.role == "inverter" and dev.grid ~= nil and obj:getContainer() == nil,
            "id=" .. tostring(m and m.id) .. " containers=" .. tostring(obj:getContainerCount())
    end)
    check("power bank is an empty container (no loot) that accepts car batteries", function()
        local obj = place("Base.Mov_LiveWire_PowerBank", SHEET .. "16", inSq2)
        if not obj then return false, "no object" end
        bank = obj
        local c = obj:getContainer()
        if not c then return false, "no container" end
        local n = c:getItems():size()
        local b = instanceItem("Base.CarBattery2")
        local fits = c:hasRoomFor(p, b)
        c:AddItem(b)
        return c:getType() == "livewirepowerbank" and n == 0 and fits and c:getItems():size() == 1,
            "type=" .. c:getType() .. " items=" .. n .. " cap=" .. c:getCapacity()
    end)
    check("solar panel refused indoors", function()
        local it = giveItem("Base.Mov_LiveWire_SolarPanel")
        local props = ISMoveableSpriteProps.new(SHEET .. "0")
        local sq = findSquare(function(s) return s:getRoom() ~= nil end)
        local refused = sq ~= nil and props:canPlaceMoveableInternal(p, sq, it) == false
        p:getInventory():Remove(it)
        return refused
    end)
    check("solar panel placed outdoors and registered", function()
        local obj, can = place("Base.Mov_LiveWire_SolarPanel", SHEET .. "0", outSq)
        solar = obj
        local m = obj and LiveWire.Marks.get(obj)
        return m ~= nil and R.device(m.id) ~= nil and R.device(m.id).role == "source", "canPlace=" .. tostring(can)
    end)
    check("water wheel refused away from water", function()
        local ok, why = LiveWire.Placement.check("WaterWheel", outSq2)
        return LiveWire.Placement.nextToRiver(outSq2) or (ok == false and why == "Tooltip_LW_NeedWaterSide")
    end)
    check("menu finds the inverter from the solar panel", function()
        local list = LiveWire.Install.invertersInRange(solar:getSquare())
        return #list >= 1 and list[1].obj == inv, "found=" .. #list
    end)
    check("solar panel linked by the real timed action", function()
        standNear(solar:getSquare())
        local ok0, why = LiveWire.Install.checkLink(p, solar, inv)
        if not ok0 then return false, "checkLink: " .. tostring(why) end
        local wires = p:getInventory():getCountTypeRecurse("Base.ElectricWire")
        local done = LWLinkAction:new(p, solar, inv):complete()
        local m = LiveWire.Marks.get(solar)
        local im = LiveWire.Marks.get(inv)
        return done == true and m.inv == im.id and R.device(m.id).grid == R.device(im.id).grid,
            "wires used=" .. tostring(wires - p:getInventory():getCountTypeRecurse("Base.ElectricWire"))
    end)
    check("power bank linked", function()
        standNear(bank:getSquare())
        local done = LWLinkAction:new(p, bank, inv):complete()
        return done == true and LiveWire.Marks.get(bank).inv == LiveWire.Marks.get(inv).id
    end)
    check("rotating the inverter keeps its id and its links", function()
        local id = LiveWire.Marks.get(inv).id
        local sq = inv:getSquare()
        standNear(sq)
        ISMoveableSpriteProps.new(SHEET .. "13"):rotateMoveable(p, sq, SHEET .. "12")
        local obj = ourObject(sq, SHEET .. "13")
        if not obj then return false, "rotated object missing" end
        inv = obj
        local m = LiveWire.Marks.get(obj)
        local dev = m and R.device(m.id)
        local grid = dev and R.grid(dev.grid)
        local n = 0
        if grid then
            for _ in pairs(grid.members) do n = n + 1 end
        end
        return m ~= nil and m.id == id and n == 2, "id=" .. tostring(m and m.id) .. " members=" .. n
    end)
    check("simulation step runs", function()
        LiveWire.Sim.tick()
        local dev = R.device(LiveWire.Marks.get(inv).id)
        local snap = LiveWire.Sim.snapshot(R.grid(dev.grid))
        return snap ~= nil and #snap.sources == 1, "sources=" .. tostring(snap and #snap.sources)
    end)
    check("picking a panel up removes it and keeps its condition on the item", function()
        local obj = place("Base.Mov_LiveWire_SolarPanel", SHEET .. "0", outSq2)
        if not obj then return false, "no object" end
        local id = LiveWire.Marks.get(obj).id
        R.device(id).cond = 77
        standNear(outSq2)
        ISMoveableSpriteProps.new(SHEET .. "0"):pickUpMoveable(p, outSq2, true)
        local gone = ourObject(outSq2, SHEET .. "0") == nil and R.device(id) == nil
        ISMoveableSpriteProps.new(SHEET .. "0"):placeMoveable(p, outSq2, SHEET .. "0")
        local again = ourObject(outSq2, SHEET .. "0")
        local m2 = again and LiveWire.Marks.get(again)
        local cond = m2 and R.device(m2.id) and R.device(m2.id).cond
        return gone and cond == 77, "gone=" .. tostring(gone) .. " cond=" .. tostring(cond)
    end)
    check("breaker panel on a wall", function()
        local sq = findSquare(function(s) return s:getRoom() ~= nil and s:getWall(true) ~= nil end)
        if not sq then return true, "SKIP no wall" end
        local obj, can = place("Base.Mov_LiveWire_Breaker", SHEET .. "20", sq)
        local m = obj and LiveWire.Marks.get(obj)
        return m ~= nil and R.device(m.id) ~= nil, "canPlace=" .. tostring(can)
    end)
    check("menu of a connected solar panel", function()
        local menu, out = liveWireMenu(solar)
        if menu then menu:closeAll() end
        for i = 1, #out do lines[#lines + 1] = "    | " .. out[i] end
        return contains(out, getText("ContextMenu_LW_Unlink"))
            and contains(out, string.sub(getText("ContextMenu_LW_LinkedTo", "9"), 1, 10))
    end)
    check("menu of the inverter lists the equipment", function()
        standNear(inv:getSquare())
        local menu, out = liveWireMenu(inv)
        for i = 1, #out do lines[#lines + 1] = "    | " .. out[i] end
        return contains(out, getText("ContextMenu_LW_LinkDevice"))
            and contains(out, getText("ContextMenu_LW_UnlinkDevice"))
            and contains(out, getText("IGUI_LW_Model_PowerBank"))
    end)
    check("no Lua error recorded", function()
        local n = getLuaDebuggerErrorCount and getLuaDebuggerErrorCount() or 0
        return n == 0, "errors=" .. tostring(n)
    end)
    if ISCharacterInfoWindow and ISCharacterInfoWindow.instance then ISCharacterInfoWindow.instance:setVisible(false) end
    return true
end

function H.result(ctx)
    local pass, total = 0, 0
    for i = 1, #lines do
        local head = lines[i]:sub(1, 4)
        if head == "PASS" then pass = pass + 1 end
        if head == "PASS" or head == "FAIL" then total = total + 1 end
    end
    return { ok = okAll, summary = tostring(pass) .. "/" .. tostring(total) .. " PASS", lines = lines }
end

return H
