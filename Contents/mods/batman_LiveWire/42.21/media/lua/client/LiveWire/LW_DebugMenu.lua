-- Live Wire: "Debug" submenu of the Live Wire menu, shown in single player with
-- -debug and to administrators in multiplayer (LW_Debug.lua). Display only: the
-- server re-checks the right on every command (LW_DebugCommands.lua).
if isServer() then return end

LiveWire = LiveWire or {}

local DebugMenu = {}
LiveWire.DebugMenu = DebugMenu

-- Display order of the network actions.
local ORDER = {
    "dump", "battery100", "battery50", "battery15", "battery0", "advance1", "advance12",
    "repairAll", "damageInverter", "trip", "refuel", "reanchor",
}

function DebugMenu.onAction(player, action, deviceId)
    LiveWire.Client.send(LiveWire.Protocol.C_DEBUG, { action = action, device = deviceId })
end

-- deviceId: any device of the network to act on (nil: only the global tools).
function DebugMenu.fill(sub, player, deviceId)
    if not LiveWire.Debug.allowed(player) then return end
    local opt = sub:addOption(getText("ContextMenu_LW_Debug"), nil, nil)
    local menu = ISContextMenu:getNew(sub)
    sub:addSubMenu(opt, menu)
    menu:addOption(getText("ContextMenu_LW_Debug_spawnKit"), player, DebugMenu.onAction, "spawnKit", nil)
    menu:addOption(getText("ContextMenu_LW_Debug_RemoveRelays"), player, DebugMenu.onAction, "removeRelays", nil)
    menu:addOption(getText("ContextMenu_LW_Debug_EnablePumps"), player, DebugMenu.onAction, "enablePumps", nil)
    if not deviceId then return end
    for i = 1, #ORDER do
        menu:addOption(getText("ContextMenu_LW_Debug_" .. ORDER[i]), player, DebugMenu.onAction, ORDER[i], deviceId)
    end
end
