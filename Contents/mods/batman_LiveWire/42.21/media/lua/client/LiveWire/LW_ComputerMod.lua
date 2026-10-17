-- Live Wire: optional integration with the Computer Mod (id ComputerModkum,
-- Workshop 3725497089) and its Laptop addon (id ComputerModLaptop, 3798992436).
-- Nothing here runs without them.
--
-- * The management software comes on a disk found in loot (LiveWire.MonitorDisk,
--   server/Items/LiveWire_Distributions.lua). Right-click a Computer Mod computer
--   or laptop with the disk: "Install the Live Wire software". The flag is written
--   in the computer data with their own helpers (ComputerModComputerTypes.getData /
--   transmitData). It is prefixed "ComputerMod" because their laptop data only
--   synchronises keys with that prefix (ComputerMod_ComputerTypes.lua:143-147).
-- * Their desktop gets a "Live Wire" app (wrapper of ComputerScreenUI's
--   getDesktopAppItems and activateDesktopItem, the way the author's own addons
--   extend it); it opens our management software window (LW_Dashboard.lua) for the
--   inverter linked to this computer, or else the nearest inverter in cable range.
-- No code of these mods is copied: only their global functions are called.
if isServer() then return end

LiveWire = LiveWire or {}

local CM = {}
LiveWire.ComputerMod = CM

CM.KEY = "ComputerModLiveWireInstalled"
CM.APP = "livewire"

function CM.available()
    return ComputerModComputerTypes ~= nil and ComputerModComputerTypes.isComputer ~= nil
end

function CM.isComputer(obj)
    return CM.available() and obj ~= nil and ComputerModComputerTypes.isComputer(obj)
end

function CM.isInstalled(obj)
    if not CM.isComputer(obj) then return false end
    local data = ComputerModComputerTypes.getData(obj)
    return type(data) == "table" and data[CM.KEY] == true
end

function CM.install(obj)
    local data = ComputerModComputerTypes.getData(obj)
    if type(data) ~= "table" then return false end
    data[CM.KEY] = true
    ComputerModComputerTypes.transmitData(obj)
    return true
end

-- Inverter shown by the software running on `obj`: the one this computer is
-- linked to (vanilla desktop link), else the nearest inverter in cable range.
function CM.inverterFor(obj)
    local m = LiveWire.Install.vanillaMark(obj)
    if m and type(m.inverter) == "string" then return m.inverter end
    local sq = obj and obj.getSquare and obj:getSquare()
    local list = LiveWire.Install.invertersInRange(sq)
    local im = list[1] and LiveWire.Marks.get(list[1].obj)
    return im and im.id or nil
end

function CM.openSoftware(player, obj)
    local id = CM.inverterFor(obj)
    if not id then
        LiveWire.Client.showNotify(player, "IGUI_LW_NoInverterForSoftware", {}, true)
        return
    end
    LiveWire.Dashboard.open(player, id)
end

local function onInstall(player, obj)
    if player:getInventory():getCountTypeRecurse("LiveWire.MonitorDisk") <= 0 then return end
    if CM.install(obj) then LiveWire.Client.showNotify(player, "IGUI_LW_SoftwareInstalled", {}) end
end

-- "Live Wire" options on a Computer Mod computer or laptop.
local function onFillWorld(playerNum, context, worldobjects, test)
    if test or not CM.available() then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local seen = {}
    for _, o in ipairs(worldobjects) do
        if o and not seen[o] and CM.isComputer(o) then
            seen[o] = true
            if CM.isInstalled(o) then
                -- A linked desktop already has the option in the "Live Wire" menu.
                if not LiveWire.Install.vanillaMark(o) then
                    context:addOption(getText("ContextMenu_LW_Software"), player, CM.openSoftware, o)
                end
            else
                local opt = context:addOption(getText("ContextMenu_LW_InstallSoftware"), player, onInstall, o)
                if player:getInventory():getCountTypeRecurse("LiveWire.MonitorDisk") <= 0 then
                    local t = ISWorldObjectContextMenu.addToolTip()
                    t.description = getText("Tooltip_LW_NeedDisk")
                    opt.toolTip = t
                    opt.notAvailable = true
                end
            end
        end
    end
end

-- Desktop app, once their UI is loaded.
local function patchScreen()
    if CM.patched or not ComputerScreenUI or not ComputerScreenUI.getDesktopAppItems
        or not ComputerScreenUI.activateDesktopItem then
        return
    end
    CM.patched = true
    local origItems = ComputerScreenUI.getDesktopAppItems
    ComputerScreenUI.getDesktopAppItems = function(self, ...)
        local items = origItems(self, ...)
        if type(items) == "table" and CM.isInstalled(self.computer) then
            items[#items + 1] = { key = "app_" .. CM.APP, kind = "app", app = CM.APP,
                                  label = getText("IGUI_LW_App"),
                                  texture = getTexture("media/ui/LiveWire/App.png") }
        end
        return items
    end
    local origActivate = ComputerScreenUI.activateDesktopItem
    ComputerScreenUI.activateDesktopItem = function(self, item, ...)
        if item and item.app == CM.APP then
            local player = self.player
            if type(player) == "number" then player = getSpecificPlayer(player) end
            CM.openSoftware(player or getPlayer(), self.computer)
            return
        end
        return origActivate(self, item, ...)
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
Events.OnGameStart.Add(patchScreen)
