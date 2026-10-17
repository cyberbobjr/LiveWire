-- Live Wire: "Live Wire" submenu on world objects, and battery options in the inventory.
-- Placing, rotating and picking up the equipment is vanilla (furniture cursor and
-- its native menu). This menu only connects the equipment: on a device, the
-- inverters within cable range; on an inverter, the equipment to connect or
-- disconnect. Every option is re-checked by the authority in the timed action or
-- command.
if isServer() then return end

LiveWire = LiveWire or {}

local Menu = {}
LiveWire.Menu = Menu

local function I() return LiveWire.Install end

local function tip(option, key, arg, arg2)
    local t = ISWorldObjectContextMenu.addToolTip()
    if arg2 ~= nil then
        t.description = getText(key, arg, arg2)
    else
        t.description = getText(key, arg)
    end
    option.toolTip = t
    option.notAvailable = true
end

local function disabled(menu, text)
    local o = menu:addOption(text, nil, nil)
    o.notAvailable = true
    return o
end

local function modelName(model)
    return getText("IGUI_LW_Model_" .. tostring(model))
end

-- Display name of a linkable object (our device, vanilla generator or computer).
local function objectName(entry)
    if entry.kind == "device" then return modelName(LiveWire.Marks.get(entry.obj).model) end
    if entry.kind == "backup" then return getText("IGUI_LW_Model_BackupGenerator") end
    return getText("IGUI_LW_Model_ManagementComputer")
end

-- Inverter id an object is connected to, from its mark (sent by the server).
local function linkedInverter(obj, kind)
    if kind == "device" then return LiveWire.Marks.get(obj).inv end
    local m = I().vanillaMark(obj)
    return m and m.inverter or nil
end

local function tiles(d)
    return tostring(math.floor(d + 0.5))
end

-- Nearest Live Wire inverter seen by this client within maxDist tiles (any floor),
-- as { obj, dist, dz }, or nil. Used to explain why nothing is in cable range.
function Menu.nearestInverter(obj, maxDist)
    local V = LiveWire.Visuals
    local sq = obj and obj:getSquare()
    if not V or not V.inverters or not sq then return nil end
    local best = nil
    local list = V.inverters()
    for i = 1, #list do
        local o = list[i]
        local os = o:getSquare()
        if os and o:getObjectIndex() ~= -1 and LiveWire.Marks.get(o) then
            local d, dz = I().distance(sq:getX(), sq:getY(), sq:getZ(), os:getX(), os:getY(), os:getZ())
            if d <= maxDist and (not best or d < best.dist) then
                best = { obj = o, dist = d, dz = dz }
            end
        end
    end
    return best
end

local function queueNear(player, sq, action)
    if luautils.walkAdj(player, sq) then ISTimedActionQueue.add(action) end
end

-- Callbacks (first argument is the option target).
function Menu.onMeasure(player, sq)
    queueNear(player, sq, LWMeasureAction:new(player, sq))
end

function Menu.onLink(player, target, inverter)
    queueNear(player, target:getSquare(), LWLinkAction:new(player, target, inverter))
end

function Menu.onRepair(player, obj, overhaul)
    queueNear(player, obj:getSquare(), LWRepairAction:new(player, obj, overhaul))
end

function Menu.onInspect(player, obj)
    queueNear(player, obj:getSquare(), LWInspectAction:new(player, obj))
end

function Menu.onClearSnow(player, obj)
    queueNear(player, obj:getSquare(), LWClearSnowAction:new(player, obj))
end

function Menu.onUnlink(player, id)
    LiveWire.Client.send(LiveWire.Protocol.C_UNLINK, { device = id })
end

function Menu.onSetInverter(player, id, on)
    LiveWire.Client.send(LiveWire.Protocol.C_SET_INVERTER, { inverter = id, on = on })
end

function Menu.onReset(player, id)
    LiveWire.Client.send(LiveWire.Protocol.C_RESET, { inverter = id })
end

-- Management software on a linked computer: inside the Computer Mod screen when
-- that mod handles this computer, else on our own computer screen.
function Menu.onSoftware(player, id, computer)
    local CM = LiveWire.ComputerMod
    if CM and CM.isComputer(computer) and CM.openInside(player, computer) then return end
    LiveWire.SoftwareScreen.open(player, id, computer)
end

function Menu.onMuffle(player, obj, remove)
    queueNear(player, obj:getSquare(), LWMuffleAction:new(player, obj, remove))
end

function Menu.onPanel(player, id)
    LiveWire.InverterPanel.open(player, id)
end

function Menu.onShowRange(player, id, sq)
    if LiveWire.RangeView.isShown(id) then
        LiveWire.RangeView.hide()
    else
        LiveWire.RangeView.show(id, sq:getX(), sq:getY(), sq:getZ())
    end
end

function Menu.onResetBreaker(player, id)
    LiveWire.Client.send(LiveWire.Protocol.C_RESET_BREAKER, { device = id })
end

function Menu.onAckAlarm(player, id)
    LiveWire.Client.send(LiveWire.Protocol.C_ACK_ALARM, { device = id })
end

function Menu.onRecondition(player, item)
    ISInventoryPaneContextMenu.transferIfNeeded(player, item)
    ISTimedActionQueue.add(LWReconditionAction:new(player, item))
end

-- "Connect to an inverter" submenu of a device or vanilla object, or its link line.
local function addLinkOptions(menu, player, obj, kind, linkId)
    local sq = obj:getSquare()
    local current = linkedInverter(obj, kind)
    if current then
        local invObj = I().inverterById(sq, current)
        if invObj then
            local is = invObj:getSquare()
            local d = I().distance(sq:getX(), sq:getY(), sq:getZ(), is:getX(), is:getY(), is:getZ())
            disabled(menu, getText("ContextMenu_LW_LinkedTo", tiles(d)))
        else
            disabled(menu, getText("ContextMenu_LW_LinkedFar"))
        end
        if linkId then
            menu:addOption(getText("ContextMenu_LW_Unlink"), player, Menu.onUnlink, linkId)
        end
        return
    end
    if kind == "device" then disabled(menu, getText("ContextMenu_LW_NotLinked")) end
    local inverters = I().invertersInRange(sq)
    local range = tostring(LiveWire.Config.get("LinkRange"))
    if #inverters == 0 then
        local near = Menu.nearestInverter(obj, 2 * LiveWire.Config.get("LinkRange"))
        if near and near.dz > I().LINK_FLOORS then
            disabled(menu, getText("ContextMenu_LW_InverterFloors", tostring(near.dz), tostring(I().LINK_FLOORS)))
        elseif near then
            disabled(menu, getText("ContextMenu_LW_InverterTooFar", tostring(math.ceil(near.dist - 1e-9)), range))
        else
            disabled(menu, getText("ContextMenu_LW_NoInverter", range))
        end
        return
    end
    local opt = menu:addOption(getText("ContextMenu_LW_LinkTo"), nil, nil)
    local sub = ISContextMenu:getNew(menu)
    menu:addSubMenu(opt, sub)
    for i = 1, #inverters do
        local inv = inverters[i]
        local o = sub:addOption(getText("ContextMenu_LW_InverterAt", tiles(inv.dist),
            tostring(I().wiresFor(inv.dist))), player, Menu.onLink, obj, inv.obj)
        local ok, why, arg, arg2 = I().checkLink(player, obj, inv.obj)
        if not ok then tip(o, why, arg, arg2) end
    end
end

-- Inverter: connect or disconnect the equipment around it.
local function addInverterOptions(menu, player, obj, mark)
    menu:addOption(getText("ContextMenu_LW_Panel"), player, Menu.onPanel, mark.id)
    if mark.st == "on" then
        menu:addOption(getText("ContextMenu_LW_TurnOff"), player, Menu.onSetInverter, mark.id, false)
    elseif mark.st == "off" then
        menu:addOption(getText("ContextMenu_LW_TurnOn"), player, Menu.onSetInverter, mark.id, true)
    end
    if mark.st == "tripped" then
        menu:addOption(getText("ContextMenu_LW_Reset"), player, Menu.onReset, mark.id)
    end
    if mark.muf then
        menu:addOption(getText("ContextMenu_LW_Unmuffle"), player, Menu.onMuffle, obj, true)
    else
        local o = menu:addOption(getText("ContextMenu_LW_Muffle"), player, Menu.onMuffle, obj, false)
        local ok, why, arg = LWMuffleAction.canDo(player, obj, false)
        if not ok then tip(o, why, arg) end
    end
    local rangeKey = "ContextMenu_LW_ShowRange"
    if LiveWire.RangeView.isShown(mark.id) then rangeKey = "ContextMenu_LW_HideRange" end
    menu:addOption(getText(rangeKey), player, Menu.onShowRange, mark.id, obj:getSquare())

    local around = I().objectsInRange(obj:getSquare(), nil, true)
    local free, linked = {}, {}
    for i = 1, #around do
        local e = around[i]
        local isInverter = e.kind == "device"
            and LiveWire.Defs.devices[LiveWire.Marks.get(e.obj).model].role == "inverter"
        if not isInverter then
            local inv = linkedInverter(e.obj, e.kind)
            if inv == mark.id then
                linked[#linked + 1] = e
            elseif not inv then
                free[#free + 1] = e
            end
        end
    end
    local range = tostring(LiveWire.Config.get("LinkRange"))

    local lo = menu:addOption(getText("ContextMenu_LW_LinkDevice"), nil, nil)
    local lsub = ISContextMenu:getNew(menu)
    menu:addSubMenu(lo, lsub)
    if #free == 0 then disabled(lsub, getText("ContextMenu_LW_NothingToLink", range)) end
    for i = 1, #free do
        local e = free[i]
        local o = lsub:addOption(getText("ContextMenu_LW_DeviceAt", objectName(e), tiles(e.dist),
            tostring(I().wiresFor(e.dist))), player, Menu.onLink, e.obj, obj)
        local ok, why, arg, arg2 = I().checkLink(player, e.obj, obj)
        if not ok then tip(o, why, arg, arg2) end
    end

    local uo = menu:addOption(getText("ContextMenu_LW_UnlinkDevice"), nil, nil)
    local usub = ISContextMenu:getNew(menu)
    menu:addSubMenu(uo, usub)
    if #linked == 0 then disabled(usub, getText("ContextMenu_LW_NothingLinked")) end
    for i = 1, #linked do
        local e = linked[i]
        local id
        if e.kind == "device" then id = LiveWire.Marks.get(e.obj).id else id = I().vanillaMark(e.obj).id end
        usub:addOption(getText("ContextMenu_LW_LinkedDeviceAt", objectName(e), tiles(e.dist)),
            player, Menu.onUnlink, id)
    end
end

-- Options for one of our placed devices.
local function addDeviceOptions(root, player, obj)
    local mark = LiveWire.Marks.get(obj)
    local def = LiveWire.Defs.devices[mark.model]
    if not def then return end
    local opt = root:addOption(modelName(mark.model), nil, nil)
    local menu = ISContextMenu:getNew(root)
    root:addSubMenu(opt, menu)

    if def.role == "inverter" then
        addInverterOptions(menu, player, obj, mark)
    else
        addLinkOptions(menu, player, obj, "device", mark.id)
    end
    if def.kind == "breaker" and mark.st == "tripped" then
        menu:addOption(getText("ContextMenu_LW_ResetBreaker"), player, Menu.onResetBreaker, mark.id)
    end
    if def.kind == "alarm" and mark.st == "ringing" then
        menu:addOption(getText("ContextMenu_LW_AckAlarm"), player, Menu.onAckAlarm, mark.id)
    end
    if def.kind == "solar" then
        menu:addOption(getText("ContextMenu_LW_ClearSnow"), player, Menu.onClearSnow, obj)
    end
    menu:addOption(getText("ContextMenu_LW_Inspect"), player, Menu.onInspect, obj)
    local r = menu:addOption(getText("ContextMenu_LW_Repair"), player, Menu.onRepair, obj, false)
    local ok, why, arg = LWRepairAction.canRepair(player, obj, false)
    if not ok then tip(r, why, arg) end
    local ov = menu:addOption(getText("ContextMenu_LW_Overhaul"), player, Menu.onRepair, obj, true)
    ok, why, arg = LWRepairAction.canRepair(player, obj, true)
    if not ok then tip(ov, why, arg) end
end

-- Options for a vanilla generator (backup power) or desktop computer (management).
local function addVanillaOptions(root, player, obj, kind)
    local mark = I().vanillaMark(obj)
    local title = "IGUI_LW_Model_BackupGenerator"
    if kind == "computer" then title = "IGUI_LW_Model_ManagementComputer" end
    local opt = root:addOption(getText(title), nil, nil)
    local menu = ISContextMenu:getNew(root)
    root:addSubMenu(opt, menu)
    if kind == "computer" and mark and type(mark.inverter) == "string" then
        local o = menu:addOption(getText("ContextMenu_LW_Software"), player, Menu.onSoftware, mark.inverter, obj)
        -- With the Computer Mod, the software must be installed from its disk first.
        local CM = LiveWire.ComputerMod
        if CM and CM.isComputer(obj) and not CM.isInstalled(obj) then tip(o, "Tooltip_LW_NeedSoftware") end
    end
    addLinkOptions(menu, player, obj, kind, mark and mark.id)
end

local function onFillWorld(playerNum, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
    local player = getSpecificPlayer(playerNum)
    if not player or player:getVehicle() then return end
    local sq = ISWorldObjectContextMenu.fetchVars and ISWorldObjectContextMenu.fetchVars.clickedSquare
    if not sq and worldobjects[1] then sq = worldobjects[1]:getSquare() end
    if not sq then return end

    -- Our devices among the clicked objects and on the clicked square.
    -- Vanilla generators and computers only when they are connected or an
    -- inverter is in range, so that their vanilla menus are not cluttered.
    local devices, vanilla, seen = {}, {}, {}
    local function addObj(o)
        if not o or seen[o] then return end
        local kind = I().linkKind(o)
        if kind == "device" then
            seen[o] = true
            devices[#devices + 1] = o
        elseif kind and o:getSquare() and (I().vanillaMark(o) or #I().invertersInRange(o:getSquare()) > 0
                or Menu.nearestInverter(o, 2 * LiveWire.Config.get("LinkRange")) ~= nil) then
            seen[o] = true
            vanilla[#vanilla + 1] = { obj = o, kind = kind }
        end
    end
    for _, o in ipairs(worldobjects) do addObj(o) end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do addObj(objs:get(i)) end

    local hasTester = player:getInventory():getCountTypeRecurse("LiveWire.VoltageTester") > 0
    local debug = LiveWire.Debug.allowed(player)
    if #devices == 0 and #vanilla == 0 and not hasTester and not debug then return end
    if test then return ISWorldObjectContextMenu.setTest() end

    local root = context:addOption(getText("ContextMenu_LW_Root"), worldobjects, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)

    if hasTester then
        sub:addOption(getText("ContextMenu_LW_Measure"), player, Menu.onMeasure, sq)
    end
    for i = 1, #devices do addDeviceOptions(sub, player, devices[i]) end
    for i = 1, #vanilla do addVanillaOptions(sub, player, vanilla[i].obj, vanilla[i].kind) end

    if debug and LiveWire.DebugMenu then
        -- Network to act on: a clicked device, else the nearest inverter.
        local id = nil
        if devices[1] then id = LiveWire.Marks.get(devices[1]).id end
        for i = 1, #vanilla do
            local m = I().vanillaMark(vanilla[i].obj)
            if not id and m then id = m.id end
        end
        if not id then
            local list = I().invertersInRange(sq)
            local m = list[1] and LiveWire.Marks.get(list[1].obj)
            id = m and m.id
        end
        LiveWire.DebugMenu.fill(sub, player, id)
    end
end

local function onFillInventory(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local list = ISInventoryPane.getActualItems(items)
    for _, item in ipairs(list) do
        if LiveWire.Defs.isBattery(item:getFullType()) then
            local o = context:addOption(getText("ContextMenu_LW_Recondition"), player, Menu.onRecondition, item)
            local ok, why, arg = LWReconditionAction.canRecondition(player, item)
            if not ok then
                local t = ISToolTip:new()
                t:initialise()
                t:setVisible(false)
                t.description = getText(why, arg)
                o.toolTip = t
                o.notAvailable = true
            end
            return
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
Events.OnFillInventoryObjectContextMenu.Add(onFillInventory)
