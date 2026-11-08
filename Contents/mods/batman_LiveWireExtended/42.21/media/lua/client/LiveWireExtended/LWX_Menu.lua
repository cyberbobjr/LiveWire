-- LiveWire Extended: "LiveWire Extended" submenu on a Live Wire inverter. Every option
-- is re-checked by the authority in its timed action.
if isServer() then return end
require "LiveWireExtended/LWX_Data"
require "LiveWireExtended/LWX_Buildings"
require "LiveWireExtended/LWX_Terminal"

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

local function hint(option, key, arg1, arg2)
    local t = ISWorldObjectContextMenu.addToolTip()
    t.description = getText(key, arg1, arg2)
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

function Menu.addTerminalOptions(sub, player, obj)
    local record = X.Terminal.recordAt(obj:getSquare())
    if record then
        sub:addOption(getText("ContextMenu_LWX_UnlinkTerminal"), player, Menu.onTerminal, obj, obj, true)
        if Menu.terminalExtra then Menu.terminalExtra(sub, player, obj, record) end
        return
    end
    local list = LiveWire.Install.invertersInRange(obj:getSquare())
    if #list == 0 then
        local o = sub:addOption(getText("ContextMenu_LWX_LinkTerminal"), nil, nil)
        disable(o, "Tooltip_LWX_NoInverter")
        return
    end
    local lo = sub:addOption(getText("ContextMenu_LWX_LinkTerminal"), nil, nil)
    local lsub = ISContextMenu:getNew(sub)
    sub:addSubMenu(lo, lsub)
    for i = 1, #list do
        local inv = list[i].obj
        local o = lsub:addOption(getText("ContextMenu_LWX_InverterAt", tostring(math.floor(list[i].dist + 0.5))),
            player, Menu.onTerminal, obj, inv, false)
        local ok, why, a1, a2 = X.Terminal.checkLink(player, obj, inv)
        if not ok then
            local t = ISWorldObjectContextMenu.addToolTip()
            t.description = getText(why, a1, a2)
            o.toolTip = t
            o.notAvailable = true
        else
            hint(o, "Tooltip_LWX_TerminalWires", tostring(a1))
        end
    end
end

local function onFillWorld(playerNum, context, worldobjects, test)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local obj, mark = Menu.inverterIn(worldobjects)
    local terminal = Menu.terminalIn(worldobjects)
    if not obj and not terminal then return end
    if test then return ISWorldObjectContextMenu.setTest() end
    local root = context:addOption(getText("ContextMenu_LWX_Root"), worldobjects, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)
    if obj then
        Menu.addBuildingOptions(sub, player, obj, mark)
        if Menu.extra then Menu.extra(sub, player, obj, mark) end
    end
    if terminal then Menu.addTerminalOptions(sub, player, terminal) end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
