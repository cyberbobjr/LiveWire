-- LiveWire Extended: Functional Appliances 2 menus test the square's current only. While a
-- machine is cut by a breaker, its options are greyed out (client side only).
if isServer() then return end
require "LiveWireExtended/LWX_Points"

local X = LiveWire.Extended

Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context)
    if not FA or not context or not context.options then return end
    for _, opt in ipairs(context.options) do
        for k = 1, 10 do
            local p = opt["param" .. k]
            if p and instanceof(p, "IsoObject") then
                local a = X.Adapters.find(p)
                if a and a.id == "fa2" and X.Points.blocked(p) then
                    opt.notAvailable = true
                    local t = ISWorldObjectContextMenu.addToolTip()
                    t.description = getText("Tooltip_LWX_MachineCut")
                    opt.toolTip = t
                    break
                end
            end
        end
    end
end)
