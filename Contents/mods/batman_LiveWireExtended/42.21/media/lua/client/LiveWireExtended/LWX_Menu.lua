-- LiveWire Extended: "LiveWire Extended" submenu on a Live Wire inverter. Every option
-- is re-checked by the authority in its timed action.
if isServer() then return end
require "LiveWireExtended/LWX_Data"
require "LiveWireExtended/LWX_Buildings"
require "LiveWireExtended/LWX_Terminal"
require "LiveWireExtended/LWX_Panel"
require "LiveWireExtended/LWX_Breakers"
require "LiveWireExtended/LWX_ZoneTool"

local X = LiveWire.Extended
local D = X.Data
local Menu = {}
X.Menu = Menu

Menu.LEVEL = 3

local function disable(option, key, arg)
    local t = ISWorldObjectContextMenu.addToolTip()
    t.description = getText(key, arg)
    option.toolTip = t
    option.notAvailable = true
end

local function hint(option, key, arg1, arg2, arg3)
    local t = ISWorldObjectContextMenu.addToolTip()
    t.description = getText(key, arg1, arg2, arg3)
    option.toolTip = t
end

local function queueNear(player, sq, action)
    if luautils.walkAdj(player, sq) then ISTimedActionQueue.add(action) end
end

function Menu.onBuilding(player, obj, disconnect, key)
    queueNear(player, obj:getSquare(), LWXBuildingAction:new(player, obj, disconnect, key))
end

-- Inverter among the clicked objects (a Live Wire mark whose model is an inverter).
function Menu.inverterIn(worldobjects)
    for _, o in ipairs(worldobjects) do
        local sq = o and o.getSquare and o:getSquare()
        if sq then
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do
                local cand = objs:get(i)
                local m = LiveWire.Marks.get(cand)
                local def = m and LiveWire.Defs.devices[m.model]
                if def and def.role == "inverter" then return cand, m end
            end
        end
    end
    return nil
end

function Menu.areaLabel(entry)
    local a = entry.area
    local x, y = a.label and a.label.x or 0, a.label and a.label.y or 0
    if a.kind == "zone" then return getText("ContextMenu_LWX_DisconnectZone", tostring(x), tostring(y)) end
    return getText("ContextMenu_LWX_DisconnectBuilding", tostring(x), tostring(y))
end

function Menu.addBuildingOptions(sub, player, obj, mark)
    local sq = obj:getSquare()
    local o = sub:addOption(getText("ContextMenu_LWX_ConnectBuilding"), player, Menu.onBuilding, obj, false, nil)
    local def = X.Buildings.find(sq:getX(), sq:getY(), sq:getZ(), LiveWire.Config.tileRange(),
        LiveWire.Config.verticalRange())
    if not LiveWire.Install.hasLevel(player, Menu.LEVEL) then
        disable(o, "Tooltip_LWX_NeedLevel", tostring(LiveWire.Config.requiredLevel(Menu.LEVEL)))
    elseif not def then
        disable(o, "Tooltip_LWX_NoBuilding")
    elseif D.ownerOf(X.Buildings.key(def)) then
        disable(o, "Tooltip_LWX_AlreadyConnected")
    else
        hint(o, "Tooltip_LWX_ConnectBuilding", tostring(def:getX()), tostring(def:getY()))
    end
    for _, entry in ipairs(D.areaList(mark.id)) do
        if entry.area.kind == "building" then
            sub:addOption(Menu.areaLabel(entry), player, Menu.onBuilding, obj, true, entry.key)
        end
    end
end

-- Power terminal among the clicked objects.
function Menu.terminalIn(worldobjects)
    for _, o in ipairs(worldobjects) do
        local sq = o and o.getSquare and o:getSquare()
        local t = sq and X.Terminal.onSquare(sq)
        if t then return t end
    end
    return nil
end

function Menu.onTerminal(player, obj, inverter, unlink)
    queueNear(player, obj:getSquare(), LWXTerminalAction:new(player, obj, inverter, unlink))
end

-- Relay (E8): the building the linked terminal stands in or touches.
Menu.RELAY_REACH = 2
function Menu.addRelayOptions(sub, player, obj, record)
    local key = X.Terminal.key(record.x, record.y, record.z)
    local o = sub:addOption(getText("ContextMenu_LWX_ConnectBuilding"), player, Menu.onBuilding, obj, false, nil)
    local def = X.Buildings.find(record.x, record.y, record.z, Menu.RELAY_REACH, LiveWire.Config.verticalRange())
    if not LiveWire.Install.hasLevel(player, Menu.LEVEL) then
        disable(o, "Tooltip_LWX_NeedLevel", tostring(LiveWire.Config.requiredLevel(Menu.LEVEL)))
    elseif not def then
        disable(o, "Tooltip_LWX_NoBuildingNearTerminal")
    elseif D.ownerOf(X.Buildings.key(def)) then
        disable(o, "Tooltip_LWX_AlreadyConnected")
    else
        hint(o, "Tooltip_LWX_ConnectBuilding", tostring(def:getX()), tostring(def:getY()))
    end
    for _, entry in ipairs(D.areaList(record.inv)) do
        if entry.area.via == key then
            sub:addOption(Menu.areaLabel(entry), player, Menu.onBuilding, obj, true, entry.key)
        end
    end
end

function Menu.onZone(player, obj)
    X.ZoneTool.open(player, obj)
end

-- "Link to an inverter" submenu of a terminal or a board (one option per inverter in range).
function Menu.addLinkOptions(sub, player, obj, labelKey, wiresKey)
    local list = LiveWire.Install.invertersInRange(obj:getSquare())
    if #list == 0 then
        local o = sub:addOption(getText(labelKey), nil, nil)
        disable(o, "Tooltip_LWX_NoInverter")
        return
    end
    local lo = sub:addOption(getText(labelKey), nil, nil)
    local lsub = ISContextMenu:getNew(sub)
    sub:addSubMenu(lo, lsub)
    for i = 1, #list do
        local inv = list[i].obj
        local o = lsub:addOption(getText("ContextMenu_LWX_InverterAt", tostring(math.floor(list[i].dist + 0.5))),
            player, Menu.onTerminal, obj, inv, false)
        local ok, why, a1, a2 = X.Link.check(player, obj, inv)
        if not ok then
            local t = ISWorldObjectContextMenu.addToolTip()
            t.description = getText(why, a1, a2)
            o.toolTip = t
            o.notAvailable = true
        else
            hint(o, wiresKey, tostring(a1))
        end
    end
end

function Menu.addTerminalOptions(sub, player, obj)
    local record = X.Terminal.recordAt(obj:getSquare())
    if record then
        sub:addOption(getText("ContextMenu_LWX_UnlinkTerminal"), player, Menu.onTerminal, obj, obj, true)
        sub:addOption(getText("ContextMenu_LWX_SetZone"), player, Menu.onZone, obj)
        Menu.addRelayOptions(sub, player, obj, record)
        return
    end
    Menu.addLinkOptions(sub, player, obj, "ContextMenu_LWX_LinkTerminal", "Tooltip_LWX_TerminalWires")
end

-- Breaker board among the clicked objects.
function Menu.panelIn(worldobjects)
    for _, o in ipairs(worldobjects) do
        local sq = o and o.getSquare and o:getSquare()
        local p = sq and X.Panel.onSquare(sq)
        if p then return p end
    end
    return nil
end

function Menu.addPanelOptions(sub, player, obj)
    if X.Panel.recordAt(obj:getSquare()) then
        sub:addOption(getText("ContextMenu_LWX_UnlinkPanel"), player, Menu.onTerminal, obj, obj, true)
        if Menu.panelExtra then Menu.panelExtra(sub, player, obj) end
        return
    end
    Menu.addLinkOptions(sub, player, obj, "ContextMenu_LWX_LinkPanel", "Tooltip_LWX_PanelWires")
end

-- Breakers of a linked board (E16): install one of the carried types, remove one.
function Menu.onBreaker(player, obj, fullType, pos, remove)
    queueNear(player, obj:getSquare(), LWXBreakerAction:new(player, obj, fullType, pos, remove))
end

local function itemName(fullType)
    local it = getScriptManager():FindItem(fullType)
    return it and it:getDisplayName() or fullType
end

function Menu.panelExtra(sub, player, obj)
    local B = X.Breakers
    local record = X.Panel.recordAt(obj:getSquare())
    local io = sub:addOption(getText("ContextMenu_LWX_InstallBreaker"), nil, nil)
    local isub = ISContextMenu:getNew(sub)
    sub:addSubMenu(io, isub)
    for _, fullType in ipairs(B.ORDER) do
        local t = B.TYPES[fullType]
        local o = isub:addOption(itemName(fullType), player, Menu.onBreaker, obj, fullType, nil, false)
        local ok, why, arg = B.checkInstall(player, obj, fullType)
        if not ok then disable(o, why, arg)
        else hint(o, "Tooltip_LWX_BreakerRating", tostring(t.amps), tostring(t.volts), tostring(B.capacityW(t))) end
    end
    for _, slot in ipairs(record and record.slots or {}) do
        sub:addOption(getText("ContextMenu_LWX_RemoveBreaker", tostring(slot.pos), itemName(slot.type)),
            player, Menu.onBreaker, obj, nil, slot.pos, true)
    end
end

local function onFillWorld(playerNum, context, worldobjects, test)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local obj, mark = Menu.inverterIn(worldobjects)
    local terminal = Menu.terminalIn(worldobjects)
    local panel = Menu.panelIn(worldobjects)
    if not obj and not terminal and not panel then return end
    if test then return ISWorldObjectContextMenu.setTest() end
    local root = context:addOption(getText("ContextMenu_LWX_Root"), worldobjects, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)
    if obj then
        Menu.addBuildingOptions(sub, player, obj, mark)
        if Menu.extra then Menu.extra(sub, player, obj, mark) end
    end
    if terminal then Menu.addTerminalOptions(sub, player, terminal) end
    if panel then Menu.addPanelOptions(sub, player, panel) end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
