-- LiveWire Extended: "LiveWire Extended" submenu on a Live Wire inverter. Every option
-- is re-checked by the authority in its timed action.
if isServer() then return end
require "LiveWireExtended/LWX_Data"
require "LiveWireExtended/LWX_Buildings"
require "LiveWireExtended/LWX_Inverters"
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

-- First clicked object for which `probe(o, sq)` finds something: `sq` is the square of
-- the clicked object `o` (nil when it has none). Returns what the probe returned, when
-- its first value is not nil.
local function findIn(worldobjects, probe)
    for _, o in ipairs(worldobjects) do
        local sq = o and o.getSquare and o:getSquare()
        local a, b = probe(o, sq)
        if a then return a, b end
    end
    return nil
end

-- Inverter among the clicked objects (a Live Wire mark whose model is an inverter).
function Menu.inverterIn(worldobjects)
    return findIn(worldobjects, function(_, sq)
        if not sq then return nil end
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local cand = objs:get(i)
            local m = LiveWire.API.mark(cand)
            local def = m and LiveWire.API.model(m.model)
            if def and def.role == "inverter" then return cand, m end
        end
        return nil
    end)
end

function Menu.areaLabel(entry)
    local a = entry.area
    local x, y = a.label and a.label.x or 0, a.label and a.label.y or 0
    if a.kind == "zone" then return getText("ContextMenu_LWX_DisconnectZone", tostring(x), tostring(y)) end
    return getText("ContextMenu_LWX_DisconnectBuilding", tostring(x), tostring(y))
end

-- "Connect the building" option, enabled or explained by its tooltip. `findBuilding()`
-- gives the building def to connect (nil: none in reach, `noBuildingKey` says so).
-- `coupled`: the inverter is coupled to a master and keeps no zone of its own.
local function connectOption(sub, player, obj, findBuilding, noBuildingKey, coupled)
    local o = sub:addOption(getText("ContextMenu_LWX_ConnectBuilding"), player, Menu.onBuilding, obj, false, nil)
    local def = findBuilding()
    if coupled then
        disable(o, "Tooltip_LWX_CoupledInverter")
    elseif not LiveWire.API.hasLevel(player, X.LEVEL) then
        disable(o, "Tooltip_LWX_NeedLevel", tostring(LiveWire.Config.requiredLevel(X.LEVEL)))
    elseif not def then
        disable(o, noBuildingKey)
    elseif D.ownerOf(X.Buildings.key(def)) then
        disable(o, "Tooltip_LWX_AlreadyConnected")
    else
        hint(o, "Tooltip_LWX_ConnectBuilding", tostring(def:getX()), tostring(def:getY()))
    end
end

-- One "disconnect" option per area of inverter `inverterId` that `keep(area)` accepts.
local function disconnectOptions(sub, player, obj, inverterId, keep)
    for _, entry in ipairs(D.areaList(inverterId)) do
        if keep(entry.area) then
            sub:addOption(Menu.areaLabel(entry), player, Menu.onBuilding, obj, true, entry.key)
        end
    end
end

function Menu.addBuildingOptions(sub, player, obj, mark)
    local sq = obj:getSquare()
    connectOption(sub, player, obj, function()
        return X.Buildings.find(sq:getX(), sq:getY(), sq:getZ(), LiveWire.Config.tileRange(),
            LiveWire.Config.verticalRange())
    end, "Tooltip_LWX_NoBuilding", not X.Inverters.ownsZone(mark.cpl))
    disconnectOptions(sub, player, obj, mark.id, function(area) return area.kind == "building" end)
end

-- Power terminal among the clicked objects.
function Menu.terminalIn(worldobjects)
    return findIn(worldobjects, function(_, sq) return sq and X.Terminal.onSquare(sq) end)
end

function Menu.onTerminal(player, obj, inverter, unlink)
    queueNear(player, obj:getSquare(), LWXTerminalAction:new(player, obj, inverter, unlink))
end

-- Relay (E8): the building the linked terminal stands in or touches.
Menu.RELAY_REACH = 2
function Menu.addRelayOptions(sub, player, obj, record)
    local key = X.Terminal.key(record.x, record.y, record.z)
    connectOption(sub, player, obj, function()
        return X.Buildings.find(record.x, record.y, record.z, Menu.RELAY_REACH, LiveWire.Config.verticalRange())
    end, "Tooltip_LWX_NoBuildingNearTerminal")
    disconnectOptions(sub, player, obj, record.inv, function(area) return area.via == key end)
end

function Menu.onZone(player, obj)
    X.ZoneTool.open(player, obj)
end

-- "Link to an inverter" submenu of a terminal or a board (one option per inverter in range).
function Menu.addLinkOptions(sub, player, obj, labelKey, wiresKey)
    local list = LiveWire.API.invertersInRange(obj:getSquare())
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
    return findIn(worldobjects, function(_, sq) return sq and X.Panel.onSquare(sq) end)
end

function Menu.addPanelOptions(sub, player, obj)
    if X.Panel.recordAt(obj:getSquare()) then
        sub:addOption(getText("ContextMenu_LWX_UnlinkPanel"), player, Menu.onTerminal, obj, obj, true)
        Menu.panelExtra(sub, player, obj)
        return
    end
    Menu.addLinkOptions(sub, player, obj, "ContextMenu_LWX_LinkPanel", "Tooltip_LWX_PanelWires")
end

-- Breakers of a linked board (E16): install one of the carried types, remove one.
function Menu.onBreaker(player, obj, fullType, pos, mode)
    queueNear(player, obj:getSquare(), LWXBreakerAction:new(player, obj, fullType, pos, mode))
end

function Menu.onEnlarge(player, obj)
    queueNear(player, obj:getSquare(), LWXEnlargeAction:new(player, obj))
end

local function itemName(fullType)
    local it = getScriptManager():FindItem(fullType)
    return it and it:getDisplayName() or fullType
end

function Menu.panelExtra(sub, player, obj)
    local B = X.Breakers
    local record = X.Panel.recordAt(obj:getSquare())
    sub:addOption(getText("ContextMenu_LWX_OpenBoard"), player, function(p) X.BoardWindow.open(p, obj) end)
    -- Admin, before removing the sub-mod: switch every breaker back on (E23).
    if X.isAdmin(player) then
        local released = X.Data.table().released == true
        sub:addOption(getText(released and "ContextMenu_LWX_ResumeAll" or "ContextMenu_LWX_ReleaseAll"), player,
            function(p)
                local cmd = released and "resume" or "release"
                if isClient() then sendClientCommand(p, "LiveWireExtended", cmd, {})
                elseif released then X.Release.resume(p) else X.Release.run(p) end
            end)
    end
    local index = X.Panel.tileIndex(obj)
    local nextIndex = X.Panel.enlargedIndex(index)
    if nextIndex then
        local grow = sub:addOption(getText("IGUI_LWX_EnlargeTo", tostring(X.Panel.SIZES[index]),
            tostring(X.Panel.SIZES[nextIndex])), player, Menu.onEnlarge, obj)
        local ok, why, arg = X.Panel.enlargeCheck(player, obj)
        if not ok then disable(grow, why, arg) else hint(grow, "Tooltip_LWX_EnlargeCost", tostring(X.LEVEL)) end
    end
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
    for _, slot in ipairs(record and record.slots or {}) do
        local o = sub:addOption(getText(slot.twilight and "ContextMenu_LWX_TwilightRemove" or "ContextMenu_LWX_TwilightFit",
            Menu.slotLabel(slot)), player, Menu.onBreaker, obj, nil, slot.pos, slot.twilight and "twilightOff" or "twilightOn")
        if not slot.twilight then
            if not LiveWire.API.screwdriver(player) then disable(o, "Tooltip_LW_NeedScrewdriver")
            elseif LiveWire.API.countType(player, B.TWILIGHT_ITEM) < 1 then disable(o, "Tooltip_LWX_NoTwilightItem")
            else hint(o, "Tooltip_LWX_Twilight") end
        end
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
    local out, I = {}, LiveWire.API
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
    return findIn(worldobjects, function(o, sq)
        if o and X.Adapters.find(o) then return o end
        local objs = sq and sq:getObjects()
        for i = 0, objs and objs:size() - 1 or -1 do
            if X.Adapters.find(objs:get(i)) then return objs:get(i) end
        end
        return nil
    end)
end

-- The game's own submenu of object `o` (B42 groups an object's actions under its name, as
-- "Light Switch >" or "Dark Wall Lamp >"), or nil when the game made none.
function Menu.objectSubMenu(context, o)
    local name = o and o.getTileName and o:getTileName()
    if not name then return nil end
    for _, opt in ipairs(context.options or {}) do
        if opt.name == name and opt.subOption then return context:getSubMenu(opt.subOption) end
    end
    return nil
end

-- What the context menu offers, in the order of the submenu. `find(worldobjects)` gives
-- the clicked target (and, for an inverter, its mark); `add(sub, player, target, extra)`
-- fills the submenu. `ownMenu`: the options go in the game's own submenu of the object
-- when it made one (B42 groups an object's actions under its name).
local TARGETS = {
    { find = Menu.inverterIn,
      add = function(sub, player, obj, mark) Menu.addBuildingOptions(sub, player, obj, mark) end },
    { find = Menu.terminalIn, add = Menu.addTerminalOptions },
    { find = Menu.panelIn, add = Menu.addPanelOptions },
    { find = Menu.applianceIn, add = Menu.addPointOptions, ownMenu = true },
}

local function onFillWorld(playerNum, context, worldobjects, test)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local hits = {}
    for _, target in ipairs(TARGETS) do
        local found, extra = target.find(worldobjects)
        if found then hits[#hits + 1] = { target = target, found = found, extra = extra } end
    end
    if #hits == 0 then return end
    if test then return ISWorldObjectContextMenu.setTest() end
    local rest = {}
    for _, hit in ipairs(hits) do
        local own = hit.target.ownMenu and Menu.objectSubMenu(context, hit.found)
        if own then
            hit.target.add(own, player, hit.found, hit.extra)
        else
            rest[#rest + 1] = hit
        end
    end
    if #rest == 0 then return end
    local root = context:addOption(getText("ContextMenu_LWX_Root"), worldobjects, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)
    for _, hit in ipairs(rest) do hit.target.add(sub, player, hit.found, hit.extra) end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
