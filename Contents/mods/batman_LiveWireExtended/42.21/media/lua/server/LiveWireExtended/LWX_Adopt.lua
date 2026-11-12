if isClient() then return end
-- LiveWire Extended: first start in a world that already has Live Wire inverters. With this
-- sub-mod an inverter has no radius any more (D-44), so the inverters placed before it was
-- enabled would lose their power. Once per world, on the authority, every inverter that owns
-- a zone gets the site of its own square connected (a map building with its cellars, or a
-- loaded player enclosure), as "Connect the building" would. An inverter standing outside,
-- or whose site another inverter already powers, is left to the player.
require "LiveWireExtended/LWX_Data"
require "LiveWireExtended/LWX_Sites"
require "LiveWireExtended/LWX_Inverters"
require "LiveWireExtended/LWX_Connect"

local X = LiveWire.Extended
local AD = {}
X.Adopt = AD

-- Connect the site of every inverter of `anchors` (LiveWire.API.anchors form) that has no
-- area yet. Returns the number of inverters connected.
function AD.adopt(anchors)
    local D, n = X.Data, 0
    for id in pairs(anchors) do
        local dev = not D.entry(id) and X.Inverters.get(id)
        local site = dev and X.Sites.at(dev.x, dev.y, dev.z)
        if site and X.Connect.connectSite(dev, site, nil) then
            n = n + 1
            X.log("inverter " .. tostring(id) .. " placed before LiveWire Extended: its site was connected")
        end
    end
    return n
end

-- Runs once per world, as soon as the registry is ready.
function AD.tick()
    local t = X.Data.table()
    if t.adopted then
        Events.EveryOneMinute.Remove(AD.tick)
        return
    end
    if not LiveWire.API.writable() then return end
    AD.adopt(LiveWire.API.anchors())
    t.adopted = true
    X.Data.touch()
    if isServer() then ModData.transmit(X.DATA_KEY) end
    Events.EveryOneMinute.Remove(AD.tick)
end

Events.EveryOneMinute.Add(AD.tick)
