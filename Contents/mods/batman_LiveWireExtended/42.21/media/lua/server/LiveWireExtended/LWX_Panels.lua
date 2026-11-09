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

-- Building a board serves: the house it was drawn for (its key on the object, a box on
-- the facade stands outside), else the building it hangs in or against.
local function buildingOf(record, obj)
    local house = obj and obj:hasModData() and obj:getModData().LWXHouse
    local def = house and X.Buildings.byKey(house)
    return def or X.Buildings.find(record.x, record.y, record.z, 1, LiveWire.Config.verticalRange())
end

P.kind.onLink = function(record, dev, key, obj)
    record.size = P.size(obj) or 8
    record.slots = {}
    -- D-44: no radius anymore, the inverter powers the board's building
    X.Connect.connectDef(dev, buildingOf(record, obj), key)
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
