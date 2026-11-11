if isClient() then return end
-- LiveWire Extended: breaker boards on the authority (D-35). Linked through LWX_Linked;
-- the record keeps the board size and its breakers:
--   panels["x,y,z"] = { x, y, z, inv = inverterId, size = 8|16|24, slots = { ... } }
require "LiveWireExtended/LWX_Linked"
require "LiveWireExtended/LWX_Panel"
require "LiveWireExtended/LWX_Breakers"
require "LiveWireExtended/LWX_Connect"

local X = LiveWire.Extended
local P = X.Panel
local PS = {}
X.Panels = PS

P.kind.onLink = function(record, dev, key, obj)
    record.size = P.size(obj) or 8
    record.slots = {}
    -- a weatherproof box remembers the side of its wall (P.siteOf, also read by the clients)
    local spr = obj and obj:getSprite()
    local dx, dy = P.acrossWall(spr and spr:getName())
    record.wall = dx and { dx, dy } or nil
    -- D-44, D-62: no radius anymore, the inverter powers the site of the board's wall face
    X.Connect.connectSite(dev, P.siteOf(record), key)
end

local previousForget = P.kind.onForget
P.kind.onForget = function(record, key)
    if previousForget then previousForget(record, key) end
    local e = record.inv and X.Data.entry(record.inv)
    if e and e.areas then
        X.Connect.commit(record.inv, function(entry)
            for k, a in pairs(entry.areas) do
                if a.via == key then entry.areas[k] = nil end
            end
        end)
    end
end

function PS.link(character, obj, invObj)
    if not P.isPanel(obj) then return false end
    return X.Linked.link(character, obj, invObj)
end

function PS.unlink(character, obj)
    if not P.isPanel(obj) then return false end
    return X.Linked.unlink(character, obj)
end

local function transmit()
    X.Data.touch()
    if isServer() then ModData.transmit(X.DATA_KEY) end
end

-- Install a breaker item of `fullType` in board `obj`, in module `at` or the first free one.
function PS.installBreaker(character, obj, fullType, at)
    local B = X.Breakers
    local ok, why, arg = B.checkInstall(character, obj, fullType, at)
    if not ok then
        LiveWire.notify(character, why, { arg }, true)
        return false
    end
    if not LiveWire.API.consume(character, fullType, 1) then return false end
    local t, pos = B.TYPES[fullType], why
    local record = P.recordAt(obj:getSquare())
    local slot = { type = fullType, pos = pos, poles = t.poles, amps = t.amps, volts = t.volts,
        label = "", off = false, tripped = false, points = {} }
    local slots, at = record.slots, #record.slots + 1
    for i, s in ipairs(slots) do
        if s.pos > pos then at = i; break end
    end
    table.insert(slots, at, slot)
    transmit()
    LiveWire.notify(character, "IGUI_LWX_BreakerInstalled", { tostring(t.amps), tostring(t.volts) })
    X.log("breaker " .. fullType .. " installed at module " .. pos .. " of board " .. record.x .. "," .. record.y .. "," .. record.z)
    return true
end

-- Remove the breaker whose first module is `pos`; the item goes back to the character.
function PS.removeBreaker(character, obj, pos)
    local record = P.isPanel(obj) and P.recordAt(obj:getSquare())
    if not record then return false end
    local slot, i = X.Breakers.slotAt(record, tonumber(pos))
    if not slot then return false end
    if not LiveWire.API.screwdriver(character) then
        LiveWire.notify(character, "Tooltip_LW_NeedScrewdriver", {}, true)
        return false
    end
    table.remove(record.slots, i)
    if PS.onBreakerRemoved then PS.onBreakerRemoved(record, slot, character) end
    LiveWire.API.giveItem(character, slot.type)
    transmit()
    LiveWire.notify(character, "IGUI_LWX_BreakerRemoved", {})
    X.log("breaker removed from module " .. slot.pos .. " of board " .. record.x .. "," .. record.y .. "," .. record.z)
    return true
end

-- Enlarge board `obj` one size on its spot (D-55). The authority checks the rules again,
-- takes the materials, puts the tile of the next size on the same face and updates the
-- record. Breakers, labels and wired appliances stay on the board.
function PS.enlarge(character, obj)
    local ok, why, arg = P.enlargeCheck(character, obj)
    local record = ok and P.recordAt(obj:getSquare())
    if ok and not record then ok, why = false, "Tooltip_LWX_PanelNotLinked" end
    if not ok then
        LiveWire.notify(character, why, { arg }, true)
        return false
    end
    local nextIndex = P.enlargedIndex(P.tileIndex(obj))
    for _, item in ipairs(P.ENLARGE_COST.items) do
        if not LiveWire.API.consume(character, item[1], item[2]) then return false end
    end
    obj:setSpriteFromName(X.Terminal.SHEET .. "_" .. nextIndex)
    if isServer() then obj:transmitUpdatedSpriteToClients() end
    record.size = P.SIZES[nextIndex]
    transmit()
    LiveWire.notify(character, "IGUI_LWX_Enlarged", { tostring(record.size) })
    X.log("board " .. record.x .. "," .. record.y .. "," .. record.z .. " enlarged to " .. record.size .. " modules")
    return true
end
