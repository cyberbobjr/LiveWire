-- Native inventory refresh adapter: keep disconnected cold containers recognisable.
-- No render/frame hook and no changes to food or container contents.
if isServer() then return end
require "ISUI/ISInventoryPage"
require "LiveWire/LW_Appliances"
local previous = ISInventoryPage.addContainerButton
function ISInventoryPage:addContainerButton(container, texture, name, tooltip, ...)
    local o = container and container:getParent()
    local s = o and o.getModData and LiveWire.Appliances.saved(o)
    local original
    if s and s.kind == "fridge" and s.cut then
        for i, t in pairs(s.types) do
            if o:getContainerByIndex(tonumber(i)) == container then original = t; break end
        end
    end
    if original then
        local label = o:getModData()[original .. "_customContainerName"] or getText("IGUI_ContainerTitle_" .. original)
        name = label .. " (" .. getText("IGUI_LW_CircuitOff") .. ")"
        tooltip = name
    end
    local button = previous(self, container, texture, name, tooltip, ...)
    if original and button and ContainerButtonIcons[original] then button:setImage(ContainerButtonIcons[original]) end
    return button
end
