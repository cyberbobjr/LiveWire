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
-- * The software runs INSIDE their computer screen, as one of their applications:
--   desktop icon, application window with their title bar, minimise and close
--   buttons, taskbar slot when minimised, reopened with the session. The content
--   is the same management application as on our own screen (LW_SoftwareApp.lua),
--   drawn in their window client rectangle (clientX/Y/W/H).
-- They expose no application API: like the author's own addons (New Music
-- Integration), we add a view ("LIVEWIRE") and wrap ComputerScreenUI methods,
-- always calling the original. No code of these mods is copied.
if isServer() then return end

LiveWire = LiveWire or {}

local CM = {}
LiveWire.ComputerMod = CM

CM.KEY = "ComputerModLiveWireInstalled"
CM.APP = "livewire"
CM.VIEW = "LIVEWIRE"

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

local function playerOf(ui)
    local p = ui.player
    if type(p) == "number" then return getSpecificPlayer(p) end
    return p or getPlayer()
end

-- Open their computer screen on `obj` and start our application once it is on
-- the desktop (after the boot sequence). Returns false when the screen did not
-- open (no power, too far: their own message is shown).
function CM.openInside(player, obj)
    if not CM.isInstalled(obj) or not ComputerContextMenu or not ComputerContextMenu.openComputerUI then
        return false
    end
    ComputerContextMenu.openComputerUI({ obj }, player:getPlayerNum(), obj)
    local ui = ComputerScreenUI and ComputerScreenUI.instance
    if not ui or ui.computer ~= obj then return false end
    ui.liveWirePending = true
    return true
end

local function onInstall(player, obj)
    if player:getInventory():getCountTypeRecurse("LiveWire.MonitorDisk") <= 0 then return end
    if CM.install(obj) then LiveWire.Client.showNotify(player, "IGUI_LW_SoftwareInstalled", {}) end
end

local function onOpen(player, obj)
    if not CM.openInside(player, obj) then
        LiveWire.Client.showNotify(player, "IGUI_LW_NoInverterForSoftware", {}, true)
    end
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
                    context:addOption(getText("ContextMenu_LW_Software"), player, onOpen, o)
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

-------------------------------------------------------------------------------
-- Our view inside their screen
-------------------------------------------------------------------------------
local function inside(x, y, r)
    return r and x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

local function startLiveWire(ui)
    if ui.saveCurrentNote then ui:saveCurrentNote() end
    ui.currentView = CM.VIEW
    ui.startMenuOpen = false
    ui.settingsMenuOpen = false
    for _, fn in ipairs({ "setDesktopShortcutsVisible", "setCalculatorButtonsVisible", "setInstallControlsVisible",
                          "setSettingsControlsVisible", "setPasswordControlsVisible", "setMailControlsVisible" }) do
        if ui[fn] then ui[fn](ui, false) end
    end
    if ui.removeMinimizedView then ui:removeMinimizedView(CM.VIEW) end
    if ui.moveCloseToWindow then ui:moveCloseToWindow() end
    if ui.backButton then ui.backButton:setVisible(true) end
    if ui.closeButton then ui.closeButton:setVisible(false) end
    if ui.updateStartMenuButtons then ui:updateStartMenuButtons() end
    if not ui.liveWireApp or ui.liveWireApp.computer ~= ui.computer then
        if ui.liveWireApp then ui.liveWireApp:close() end
        ui.liveWireApp = LiveWire.SoftwareApp.new(playerOf(ui), CM.inverterFor(ui.computer), { header = false })
        ui.liveWireApp.computer = ui.computer
    end
end

local function patchScreen()
    if CM.patched or not ComputerScreenUI or not ComputerScreenUI.getDesktopAppItems
        or not ComputerScreenUI.activateDesktopItem or not ComputerScreenUI.drawDesktop then
        return
    end
    CM.patched = true
    local O = {}

    O.items = ComputerScreenUI.getDesktopAppItems
    ComputerScreenUI.getDesktopAppItems = function(self, ...)
        local items = O.items(self, ...)
        if type(items) == "table" and CM.isInstalled(self.computer) then
            items[#items + 1] = { key = "app_" .. CM.APP, kind = "app", app = CM.APP,
                                  label = getText("IGUI_LW_App"),
                                  texture = getTexture("media/ui/LiveWire/App.png") }
        end
        return items
    end

    O.activate = ComputerScreenUI.activateDesktopItem
    ComputerScreenUI.activateDesktopItem = function(self, item, ...)
        if item and item.app == CM.APP then
            startLiveWire(self)
            return
        end
        return O.activate(self, item, ...)
    end

    -- Drawn right after the desktop, under their stencil, before the start menu
    -- and the context menus (their prerender).
    O.drawDesktop = ComputerScreenUI.drawDesktop
    ComputerScreenUI.drawDesktop = function(self, ...)
        local r = O.drawDesktop(self, ...)
        if self.liveWirePending and self.currentView == "DESKTOP" then
            self.liveWirePending = nil
            startLiveWire(self)
        end
        if self.currentView == CM.VIEW and self.liveWireApp and self.clientX then
            local snap = self.liveWireApp:snapshot()
            local right = ""
            if snap then right = tostring(snap.production) .. " W / " .. tostring(snap.demand) .. " W" end
            if self.drawAppWindow then self:drawAppWindow(getText("IGUI_LW_App_Name"), getText("IGUI_LW_App_OS"), right) end
            self.liveWireApp:update()
            self.liveWireApp:draw(self, self.clientX, self.clientY, self.clientW, self.clientH)
        end
        return r
    end

    O.down = ComputerScreenUI.onMouseDown
    ComputerScreenUI.onMouseDown = function(self, x, y, ...)
        if self.currentView == CM.VIEW and self.liveWireApp and not self.computerModGamepadKeyboard then
            if self.getFrameControlAt and self:getFrameControlAt(x, y) then return O.down(self, x, y, ...) end
            if self.getStickyPasswordNoteRect and inside(x, y, self:getStickyPasswordNoteRect()) then
                return O.down(self, x, y, ...)
            end
            if self.liveWireApp:onMouseDown(x, y) then return true end
            if self.windowX and inside(x, y, { x = self.windowX, y = self.windowY, w = self.windowW, h = self.windowH }) then
                return true
            end
        end
        return O.down(self, x, y, ...)
    end

    if ComputerScreenUI.getWindowTitleForView then
        O.title = ComputerScreenUI.getWindowTitleForView
        ComputerScreenUI.getWindowTitleForView = function(self, view, ...)
            if view == CM.VIEW then return getText("IGUI_LW_App") end
            return O.title(self, view, ...)
        end
    end

    -- Their restore sends an unknown view back to the desktop.
    if ComputerScreenUI.restoreMinimizedWindow and ComputerScreenUI.getMinimizedWindows then
        O.restore = ComputerScreenUI.restoreMinimizedWindow
        ComputerScreenUI.restoreMinimizedWindow = function(self, index, ...)
            local list = self:getMinimizedWindows()
            local w = list and list[index or 1]
            if w and w.view == CM.VIEW then
                table.remove(list, index or 1)
                startLiveWire(self)
                if self.saveSessionView then self:saveSessionView() end
                return
            end
            return O.restore(self, index, ...)
        end
    end

    -- Reopen the software when the screen comes back with it as last view.
    if ComputerScreenUI.resumePoweredSession and ComputerScreenUI.getComputerData then
        O.resume = ComputerScreenUI.resumePoweredSession
        ComputerScreenUI.resumePoweredSession = function(self, ...)
            local d = self:getComputerData()
            local last = d and d.ComputerModLastView
            local r = O.resume(self, ...)
            if last == CM.VIEW and self.currentView == "DESKTOP" then startLiveWire(self) end
            return r
        end
    end

    -- Stop asking the server for snapshots when the screen goes away.
    for _, name in ipairs({ "shutdownComputer", "hideComputerScreen" }) do
        if ComputerScreenUI[name] then
            local orig = ComputerScreenUI[name]
            ComputerScreenUI[name] = function(self, ...)
                if self.liveWireApp then
                    self.liveWireApp:close()
                    self.liveWireApp = nil
                end
                return orig(self, ...)
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
Events.OnGameStart.Add(patchScreen)
