-- One name editor shared by the inverter menu and management software.
if isServer() then return end
require "ISUI/ISTextBox"
LiveWire = LiveWire or {}
local Name = {}
LiveWire.NetworkName = Name

function Name.open(player, inverterId, current, via)
    if not player or not LiveWire.Protocol.isDeviceId(inverterId) then return nil end
    local target = { inverter = inverterId, via = via }
    local function confirm(data, button)
        if button.internal ~= "OK" then return end
        LiveWire.Client.send(LiveWire.Protocol.C_RENAME, {
            inverter = data.inverter, via = data.via, name = button.parent.entry:getText(),
        })
    end
    local num = player:getPlayerNum()
    local dialog = ISTextBox:new(0, 0, 420, 160,
        getText("IGUI_LW_RenameNetworkPrompt", LiveWire.Protocol.MAX_NAME),
        current or "", target, confirm, num)
    dialog.maxChars = LiveWire.Protocol.MAX_NAME
    dialog:initialise()
    dialog:addToUIManager()
    dialog:setX(getPlayerScreenLeft(num) + math.max(0, (getPlayerScreenWidth(num) - dialog:getWidth()) / 2))
    dialog:setY(getPlayerScreenTop(num) + math.max(0, (getPlayerScreenHeight(num) - dialog:getHeight()) / 2))
    dialog.entry:focus()
    return dialog
end
