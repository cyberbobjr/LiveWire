-- Live Wire: "Live Wire" submenu on world objects, and battery options in the inventory.
-- Every option is re-checked by the authority in the timed action or command.
if isServer() then return end

LiveWire = LiveWire or {}

local Menu = {}
LiveWire.Menu = Menu

local function I() return LiveWire.Install end

local function tip(option, key, arg)
    local t = ISWorldObjectContextMenu.addToolTip()
    t.description = getText(key, arg)
    option.toolTip = t
    option.notAvailable = true
end

local function modelName(model)
    return getText("IGUI_LW_Model_" .. tostring(model))
end

local function queueNear(player, sq, action)
    if luautils.walkAdj(player, sq) then ISTimedActionQueue.add(action) end
end

local function isKit(item)
    return LiveWire.Defs.kitToModel[item:getFullType()] ~= nil
end

-- Callbacks (first argument is the option target).
function Menu.onMeasure(player, sq)
    queueNear(player, sq, LWMeasureAction:new(player, sq))
end

function Menu.onInstall(player, kit, sq)
    if luautils.walkAdj(player, sq) then
        ISInventoryPaneContextMenu.transferIfNeeded(player, kit)
        ISTimedActionQueue.add(LWInstallAction:new(player, kit, sq))
    end
end

function Menu.onDismantle(player, obj)
    queueNear(player, obj:getSquare(), LWDismantleAction:new(player, obj))
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

function Menu.onDashboard(player, id)
    LiveWire.Dashboard.open(player, id)
end

function Menu.onRecondition(player, item)
    ISInventoryPaneContextMenu.transferIfNeeded(player, item)
    ISTimedActionQueue.add(LWReconditionAction:new(player, item))
end

-- Options for one of our placed devices.
local function addDeviceOptions(sub, player, obj)
    local mark = LiveWire.Marks.get(obj)
    local def = LiveWire.Defs.devices[mark.model]
    if not def then return end
    local opt = sub:addOption(modelName(mark.model), nil, nil)
    local menu = ISContextMenu:getNew(sub)
    sub:addSubMenu(opt, menu)

    if def.role == "inverter" then
        menu:addOption(getText("ContextMenu_LW_Dashboard"), player, Menu.onDashboard, mark.id)
        menu:addOption(getText("ContextMenu_LW_TurnOn"), player, Menu.onSetInverter, mark.id, true)
        menu:addOption(getText("ContextMenu_LW_TurnOff"), player, Menu.onSetInverter, mark.id, false)
        menu:addOption(getText("ContextMenu_LW_Reset"), player, Menu.onReset, mark.id)
    else
        local inverter = I().nearestInverter(obj:getSquare())
        local o = menu:addOption(getText("ContextMenu_LW_Link"), player, Menu.onLink, obj, inverter)
        local ok, why, arg = I().checkLink(player, obj, inverter)
        if not ok then tip(o, why, arg) end
        menu:addOption(getText("ContextMenu_LW_Unlink"), player, Menu.onUnlink, mark.id)
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
    local d = menu:addOption(getText("ContextMenu_LW_Dismantle"), player, Menu.onDismantle, obj)
    if not I().screwdriver(player) then
        tip(d, "Tooltip_LW_NeedScrewdriver")
    elseif def.role == "storage" then
        local c = obj:getContainer()
        if c and c:getItems():size() > 0 then tip(d, "Tooltip_LW_EmptyFirst") end
    end
end

-- Options for a vanilla generator (backup power) or desktop computer (management).
local function addVanillaOptions(sub, player, obj, kind)
    local mark = I().vanillaMark(obj)
    local title = "IGUI_LW_Model_BackupGenerator"
    if kind == "computer" then title = "IGUI_LW_Model_ManagementComputer" end
    local opt = sub:addOption(getText(title), nil, nil)
    local menu = ISContextMenu:getNew(sub)
    sub:addSubMenu(opt, menu)
    if kind == "computer" and mark and type(mark.inverter) == "string" then
        menu:addOption(getText("ContextMenu_LW_Dashboard"), player, Menu.onDashboard, mark.inverter)
    end
    local inverter = I().nearestInverter(obj:getSquare())
    local o = menu:addOption(getText("ContextMenu_LW_Link"), player, Menu.onLink, obj, inverter)
    local ok, why, arg = I().checkLink(player, obj, inverter)
    if not ok then tip(o, why, arg) end
    if mark then
        menu:addOption(getText("ContextMenu_LW_Unlink"), player, Menu.onUnlink, mark.id)
    end
end

local function onFillWorld(playerNum, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
    local player = getSpecificPlayer(playerNum)
    if not player or player:getVehicle() then return end
    local sq = ISWorldObjectContextMenu.fetchVars and ISWorldObjectContextMenu.fetchVars.clickedSquare
    if not sq and worldobjects[1] then sq = worldobjects[1]:getSquare() end
    if not sq then return end

    -- Our devices among the clicked objects and on the clicked square.
    -- Vanilla generators and computers only when they are linked or an inverter is
    -- in range, so that their vanilla menus are not cluttered.
    local devices, vanilla, seen = {}, {}, {}
    local function addObj(o)
        if not o or seen[o] then return end
        local kind = I().linkKind(o)
        if kind == "device" then
            seen[o] = true
            devices[#devices + 1] = o
        elseif kind and o:getSquare() and (I().vanillaMark(o) or I().nearestInverter(o:getSquare())) then
            seen[o] = true
            vanilla[#vanilla + 1] = { obj = o, kind = kind }
        end
    end
    for _, o in ipairs(worldobjects) do addObj(o) end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do addObj(objs:get(i)) end

    local inv = player:getInventory()
    local kits = inv:getAllEvalRecurse(isKit)
    local hasTester = inv:getCountTypeRecurse("LiveWire.VoltageTester") > 0

    if #devices == 0 and #vanilla == 0 and kits:size() == 0 and not hasTester then return end
    if test then return ISWorldObjectContextMenu.setTest() end

    local root = context:addOption(getText("ContextMenu_LW_Root"), worldobjects, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)

    if hasTester then
        sub:addOption(getText("ContextMenu_LW_Measure"), player, Menu.onMeasure, sq)
    end

    -- One install option per kit type.
    local doneKits = {}
    for i = 0, kits:size() - 1 do
        local kit = kits:get(i)
        local fullType = kit:getFullType()
        if not doneKits[fullType] then
            doneKits[fullType] = true
            local model = LiveWire.Defs.kitToModel[fullType]
            local def = LiveWire.Defs.devices[model]
            local target = sq
            local o = sub:addOption(getText("ContextMenu_LW_Install", modelName(model)),
                player, Menu.onInstall, kit, target)
            local ok, why, arg = I().check(player, model, target)
            if not ok then tip(o, why, arg) end
        end
    end

    for i = 1, #devices do addDeviceOptions(sub, player, devices[i]) end
    for i = 1, #vanilla do addVanillaOptions(sub, player, vanilla[i].obj, vanilla[i].kind) end

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
