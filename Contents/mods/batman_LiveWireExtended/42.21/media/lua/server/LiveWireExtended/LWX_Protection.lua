if isClient() then return end
-- LiveWire Extended: each breaker protects its circuit (D-35). The load of a circuit is
-- the sum of the draws of its points as Live Wire last measured them, over every
-- inverter's inventory (whoever bills the appliance). Above its rating (W = A x V) the
-- breaker trips on its own and cuts its points until it is reset on the board. Load
-- shedding, the base main breaker and cut appliances lower the measured draw: they
-- never trip a breaker. Checked every ten game minutes, after Live Wire's measurement.
require "LiveWireExtended/LWX_PointsServer"

local X = LiveWire.Extended
local PT, Ad, B = X.Points, X.Adapters, X.Breakers
local PR = {}
X.Protection = PR

local function slotKey(p) return p.board .. "#" .. p.pos end

-- Circuit loads in W: { ["boardKey#pos"] = watts }.
function PR.loads()
    local loads = {}
    local API = LiveWire.API
    for _, id in ipairs(API.inventoryIds()) do
        API.eachBilled(id, function(o, w)
            local p = PT.point(Ad.identity(o))
            if p and p.adapter == "vanilla" then loads[slotKey(p)] = (loads[slotKey(p)] or 0) + w end
        end)
    end
    -- Points of mod adapters are not in Live Wire's inventories: ask their adapter.
    for key, p in pairs(PT.table()) do
        if p.adapter ~= "vanilla" then
            local objs = PT.objectsOf(key, p)
            local a = objs[1] and Ad.find(objs[1])
            if a then loads[slotKey(p)] = (loads[slotKey(p)] or 0) + a.watts(objs[1]) end
        end
    end
    return loads
end

function PR.check()
    local boards = X.Data.table().panels
    if not boards or X.Data.table().released then return end  -- released before removal (E23)
    local loads, any = PR.loads(), false
    local now = getGameTime():getWorldAgeHours()
    for boardKey, r in pairs(boards) do
        for _, slot in ipairs(r.slots or {}) do
            local load = math.floor((loads[boardKey .. "#" .. slot.pos] or 0) + 0.5)
            if slot.load ~= load then slot.load, any = load, true end  -- shown by the board window
            -- Energy of the interval, before a trip (E24); sent only when the figures changed.
            if B.meterAdd(slot, load, now) then any = true end
            if not slot.off and not slot.tripped and load > B.capacityW(slot) then
                slot.tripped, any = true, true
                PR.lastTrip = { board = boardKey, pos = slot.pos, load = load }
                PT.applySlot(slot)
                LiveWire.notifyNear(r.x, r.y, r.z, 20, "IGUI_LWX_BreakerTripped", { tostring(slot.pos) })
                X.log("breaker at module " .. slot.pos .. " of board " .. boardKey .. " tripped: "
                    .. math.floor(load + 0.5) .. " W over " .. B.capacityW(slot) .. " W")
            end
        end
    end
    if any then X.Data.touch() end
    if any and isServer() then ModData.transmit(X.DATA_KEY) end
end

Events.EveryTenMinutes.Add(PR.check)
