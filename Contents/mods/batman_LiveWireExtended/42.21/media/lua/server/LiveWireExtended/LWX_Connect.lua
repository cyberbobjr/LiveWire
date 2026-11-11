if isClient() then return end
-- LiveWire Extended: authority side. Validates and records the connected areas, then
-- re-declares the generator positions of the inverter (LiveWire.Anchor.reshape), asks
-- Live Wire to rebuild the appliance list and sends the public table to the clients.
require "LiveWireExtended/LWX_Data"
require "LiveWireExtended/LWX_Buildings"
require "LiveWireExtended/LWX_Sites"
require "LiveWireExtended/LWX_Inverters"

local X = LiveWire.Extended
local D = X.Data
local C = {}
X.Connect = C

-- Change the areas of inverter `id` (mutate receives its entry), then publish.
function C.commit(id, mutate)
    local key = tostring(id)
    LiveWire.Anchor.reshape(id, function()
        local t = D.table()
        local e = t.inverters[key] or { areas = {} }
        e.areas = e.areas or {}
        mutate(e)
        local any = false
        for _ in pairs(e.areas) do any = true; break end
        t.inverters[key] = any and e or nil
        D.invalidate(key)
    end)
    LiveWire.API.invalidateDemand(id)
    X.Data.touch()
    if isServer() then ModData.transmit(X.DATA_KEY) end
end

-- Building an inverter (or a terminal at x, y, z feeding it) can connect.
function C.buildingFor(x, y, z, reach)
    return X.Buildings.find(x, y, z, reach, LiveWire.Config.verticalRange())
end

-- Can `character` connect the building near (x, y, z) to inverter `dev`?
-- Returns ok, translation key, argument, building.
function C.canConnect(character, dev, x, y, z, reach)
    if not LiveWire.API.screwdriver(character) then return false, "Tooltip_LW_NeedScrewdriver" end
    if not LiveWire.API.hasLevel(character, X.LEVEL) then
        return false, "Tooltip_LWX_NeedLevel", tostring(LiveWire.Config.requiredLevel(X.LEVEL))
    end
    local def = C.buildingFor(x, y, z, reach)
    if not def then return false, "Tooltip_LWX_NoBuilding" end
    if D.ownerOf(X.Buildings.key(def)) then return false, "Tooltip_LWX_AlreadyConnected" end
    return true, nil, nil, def
end

local function count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- Connect the building near (x, y, z) to inverter `dev`; `via` is an optional terminal
-- key recorded with the area (relay, E8). Returns true when connected.
function C.connectBuilding(character, dev, x, y, z, reach, via)
    local ok, why, arg, def = C.canConnect(character, dev, x, y, z, reach)
    if not ok then
        LiveWire.notify(character, why, { arg }, true)
        return false
    end
    local area = X.Buildings.area(def, dev.id)
    if not area then
        LiveWire.notify(character, "Tooltip_LWX_NoBuilding", {}, true)
        return false
    end
    area.via = via
    local key = X.Buildings.key(def)
    C.commit(dev.id, function(e) e.areas[key] = area end)
    local chunks = {}
    for _, p in ipairs(area.positions) do chunks[p.cx .. "," .. p.cy] = true end
    LiveWire.notify(character, "IGUI_LWX_BuildingConnected", { tostring(count(chunks)) })
    X.log("building " .. key .. " connected to " .. tostring(dev.id) .. ", " .. #area.positions .. " positions")
    return true
end

-- Connect site `site` (X.Sites: a building or a player enclosure) to inverter `dev` without a
-- player check (a linked breaker board serves its site, D-44, D-62); `via` is the key of what
-- brought it. False when another inverter already powers that site.
function C.connectSite(dev, site, via)
    local key = site and X.Sites.key(site)
    if not key then return false end
    local owner = D.ownerOf(key)
    if owner then return owner == tostring(dev.id) end
    local area = X.Sites.area(site, dev.id)
    if not area then return false end
    area.via = via
    C.commit(dev.id, function(e) e.areas[key] = area end)
    X.log("site " .. key .. " connected to " .. tostring(dev.id) .. " by its board " .. tostring(via))
    return true
end

function C.disconnect(character, dev, key)
    local e = D.entry(dev.id)
    if not e or not e.areas or not e.areas[key] then return false end
    C.commit(dev.id, function(entry) entry.areas[key] = nil end)
    LiveWire.notify(character, "IGUI_LWX_AreaDisconnected", {})
    X.log("area " .. tostring(key) .. " disconnected from " .. tostring(dev.id))
    return true
end

-- Forget areas of inverters that no longer own a zone (picked up, destroyed, or coupled
-- while no add-on keeps the zones of coupled inverters). Their positions were already
-- withdrawn with their anchor (LW_Devices, LWCoupleAction).
function C.prune()
    if not LiveWire.API.writable() then return end
    local t, changed = D.table(), false
    local stale = {}
    for id in pairs(t.inverters) do
        if not X.Inverters.get(id) then stale[#stale + 1] = id end
    end
    for i = 1, #stale do
        t.inverters[stale[i]] = nil
        D.invalidate(stale[i])
        changed = true
        X.log("areas of removed inverter " .. tostring(stale[i]) .. " forgotten")
    end
    if changed then X.Data.touch() end
    if changed and isServer() then ModData.transmit(X.DATA_KEY) end
    return changed
end

Events.EveryHours.Add(C.prune)
