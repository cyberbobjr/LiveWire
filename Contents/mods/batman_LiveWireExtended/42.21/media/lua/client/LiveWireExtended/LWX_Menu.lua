-- LiveWire Extended: "LiveWire Extended" submenu on a Live Wire inverter. Every option
-- is re-checked by the authority in its timed action.
if isServer() then return end
require "LiveWireExtended/LWX_Data"
require "LiveWireExtended/LWX_Buildings"
require "LiveWireExtended/LWX_Terminal"
require "LiveWireExtended/LWX_Panel"
require "LiveWireExtended/LWX_Breakers"
require "LiveWireExtended/LWX_Points"
require "LiveWireExtended/LWX_BoardWindow"
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
function Menu.onBreaker(player, obj, fullType, pos, mode)
    queueNear(player, obj:getSquare(), LWXBreakerAction:new(player, obj, fullType, pos, mode))
end

local function itemName(fullType)
    local it = getScriptManager():FindItem(fullType)
    return it and it:getDisplayName() or fullType
end

function Menu.panelExtra(sub, player, obj)
    local B = X.Breakers
    local record = X.Panel.recordAt(obj:getSquare())
    sub:addOption(getText("ContextMenu_LWX_OpenBoard"), player, function(p) X.BoardWindow.open(p, obj) end)
    local io = sub:addOption(getText("ContextMenu_LWX_InstallBreaker"), nil, nil)
    local isub = ISContextMenu:getNew(sub)
    sub:addSubMenu(io, isub)
    for _, fullType in ipairs(B.ORDER) do
        local t = B.TYPES[fullType]
        local o = isub:addOption(itemName(fullType), player, Menu.onBreaker, obj, fullType, nil, nil)
        local ok, why, arg = B.checkInstall(player, obj, fullType)
        if not ok then disable(o, why, arg)
        else hint(o, "Tooltip_LWX_BreakerRating", tostring(t.amps), tostring(t.volts), tostring(B.capacityW(t))) end
    end
    for _, slot in ipairs(record and record.slots or {}) do
        local key = slot.tripped and "ContextMenu_LWX_ResetBreaker"
            or slot.off and "ContextMenu_LWX_CloseBreaker" or "ContextMenu_LWX_OpenBreaker"
        sub:addOption(getText(key, Menu.slotLabel(slot)), player, Menu.onBreaker, obj, nil, slot.pos,
            (slot.off or slot.tripped) and "on" or "off")
    end
    Menu.addWireApplianceOptions(sub, player, obj, record)
    for _, slot in ipairs(record and record.slots or {}) do
        sub:addOption(getText("ContextMenu_LWX_RemoveBreaker", tostring(slot.pos), itemName(slot.type)),
            player, Menu.onBreaker, obj, nil, slot.pos, "remove")
    end
end

-- ---------------------------------------------------------------- points (E17)
function Menu.slotLabel(slot)
    if slot.label and slot.label ~= "" then return getText("ContextMenu_LWX_Module", tostring(slot.pos), slot.label) end
    return getText("ContextMenu_LWX_Module", tostring(slot.pos), slot.amps .. " A")
end

function Menu.onPoint(player, appliance, board, pos, disconnect)
    queueNear(player, appliance:getSquare(), LWXPointAction:new(player, appliance, board, pos, disconnect))
end

-- One option per breaker of `record` (board object `board`) for appliance `o`.
local function addSlotOptions(menu, player, o, board, record)
    for _, slot in ipairs(record.slots or {}) do
        local opt = menu:addOption(Menu.slotLabel(slot), player, Menu.onPoint, o, board, slot.pos, false)
        local ok, why, a1, a2 = X.Points.checkConnect(player, o, board, slot.pos)
        if not ok then
            disable(opt, why, a1)
            if a2 then opt.toolTip.description = getText(why, a1, a2) end
        else
            hint(opt, "Tooltip_LWX_PointWires", tostring(why))
        end
    end
end

-- Linked boards within cable reach of square `sq` (object, record, distance).
local function boardsNear(sq)
    local out, I = {}, LiveWire.Install
    local range, floors = LiveWire.Config.get("LinkRange"), LiveWire.Config.get("LinkVerticalRange")
    for _, r in pairs(D.table().panels or {}) do
        local dist, dz = I.distance(sq:getX(), sq:getY(), sq:getZ(), r.x, r.y, r.z)
        local bsq = dist <= range and dz <= floors and getCell():getGridSquare(r.x, r.y, r.z)
        local board = bsq and X.Panel.onSquare(bsq)
        if board then out[#out + 1] = { obj = board, record = r, dist = dist } end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

-- On an appliance: "Wire to a breaker board" (boards in reach, then their breakers),
-- or "Unwire from module N" when it is wired.
function Menu.addPointOptions(sub, player, o)
    local key = X.Adapters.identity(o)
    local p = X.Points.point(key)
    if p then
        local opt = sub:addOption(getText("ContextMenu_LWX_DisconnectPoint", tostring(p.pos)), player, Menu.onPoint, o, nil, nil, true)
        -- The circuit of the appliance, in the option's tooltip (D-36).
        local slot = X.Points.slotOf(p)
        if slot then
            local name = slot.label ~= "" and slot.label or getText("IGUI_LWX_ModuleName", tostring(slot.pos))
            hint(opt, "Tooltip_LWX_WiredTo", name, tostring(slot.amps), tostring(slot.load or 0))
        end
        return
    end
    local list = boardsNear(o:getSquare())
    local root = sub:addOption(getText("ContextMenu_LWX_ConnectPoint"), nil, nil)
    local sq = o:getSquare()
    if X.Points.servedAt(sq:getX(), sq:getY(), sq:getZ()) then hint(root, "Tooltip_LWX_UnwiredServed") end
    if #list == 0 then
        disable(root, "Tooltip_LWX_NoBoardNear")
        return
    end
    local bsub = ISContextMenu:getNew(sub)
    sub:addSubMenu(root, bsub)
    for _, b in ipairs(list) do
        local bo = bsub:addOption(getText("ContextMenu_LWX_BoardAt", tostring(math.floor(b.dist + 0.5))), nil, nil)
        if #(b.record.slots or {}) == 0 then
            disable(bo, "Tooltip_LWX_NoBreakerThere")
        else
            local ssub = ISContextMenu:getNew(bsub)
            bsub:addSubMenu(bo, ssub)
            addSlotOptions(ssub, player, o, b.obj, b.record)
        end
    end
end

-- On a board: "Wire an appliance": the nearest unwired points in cable reach, same floor.
Menu.WIRE_LIST_MAX = 20
function Menu.addWireApplianceOptions(sub, player, board, record)
    if not record or #(record.slots or {}) == 0 then return end
    local range, cell, seen, found = LiveWire.Config.get("LinkRange"), getCell(), {}, {}
    for dy = -range, range do
        for dx = -range, range do
            local sq = cell:getGridSquare(record.x + dx, record.y + dy, record.z)
            local objs = sq and sq:getObjects()
            for i = 0, objs and objs:size() - 1 or -1 do
                local o = objs:get(i)
                local key = X.Adapters.find(o) and X.Adapters.identity(o)
                if key and not seen[key] and not X.Points.point(key) then
                    seen[key] = true
                    found[#found + 1] = { o = o, d = dx * dx + dy * dy }
                end
            end
        end
    end
    if #found == 0 then return end
    table.sort(found, function(a, b) return a.d < b.d end)
    local root = sub:addOption(getText("ContextMenu_LWX_WireAppliance"), nil, nil)
    local asub = ISContextMenu:getNew(sub)
    sub:addSubMenu(root, asub)
    for i = 1, math.min(#found, Menu.WIRE_LIST_MAX) do
        local o = found[i].o
        local ao = asub:addOption(getText("ContextMenu_LWX_ApplianceAt", Menu.applianceName(o),
            tostring(math.floor(math.sqrt(found[i].d) + 0.5))), nil, nil)
        local ssub = ISContextMenu:getNew(asub)
        asub:addSubMenu(ao, ssub)
        addSlotOptions(ssub, player, o, board, record)
    end
end

-- Player-facing name of a world appliance (translated moveable name when it has one).
function Menu.applianceName(o)
    local props = o:getSprite() and o:getSprite():getProperties()
    local group, custom = props and props:get("GroupName"), props and props:get("CustomName")
    if custom then
        local key = ((group and group .. " " or "") .. custom):gsub(" ", "_")
        local text = getText(key)
        if text ~= key then return text end
        return custom
    end
    return o:getObjectName() or "?"
end

-- Appliance (a point some adapter recognizes) among the clicked objects.
function Menu.applianceIn(worldobjects)
    for _, o in ipairs(worldobjects) do
        if o and X.Adapters.find(o) then return o end
        local sq = o and o.getSquare and o:getSquare()
        local objs = sq and sq:getObjects()
        for i = 0, objs and objs:size() - 1 or -1 do
            if X.Adapters.find(objs:get(i)) then return objs:get(i) end
        end
    end
    return nil
end

local function onFillWorld(playerNum, context, worldobjects, test)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local obj, mark = Menu.inverterIn(worldobjects)
    local terminal = Menu.terminalIn(worldobjects)
    local panel = Menu.panelIn(worldobjects)
    local appliance = Menu.applianceIn(worldobjects)
    if not obj and not terminal and not panel and not appliance then return end
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
    if appliance then Menu.addPointOptions(sub, player, appliance) end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
