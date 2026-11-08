-- LiveWire Extended, client side: receive the public table of connected areas, and
-- re-declare the generator positions of each inverter whose areas changed (positions
-- added on the server never reach a client that already holds the chunk).
if isServer() then return end
require "LiveWireExtended/LWX_Data"

local X = LiveWire.Extended
local D = X.Data

-- Same positions? (order-sensitive: the authority writes them in a stable order)
local function samePositions(a, b)
    a, b = a or {}, b or {}
    if #a ~= #b then return false end
    for i = 1, #a do
        local p, q = a[i], b[i]
        if p.cx ~= q.cx or p.cy ~= q.cy or p.x ~= q.x or p.y ~= q.y or p.z ~= q.z then return false end
    end
    return true
end

local function flatten(e)
    local out = {}
    if not e or not e.areas then return out end
    local keys = {}
    for k in pairs(e.areas) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        for _, p in ipairs(e.areas[k].positions or {}) do out[#out + 1] = p end
    end
    return out
end

function X.receive(data)
    if type(data) ~= "table" then return end
    local incoming = type(data.inverters) == "table" and data.inverters or {}
    local current = D.table().inverters
    local ids = {}
    for id in pairs(current) do ids[id] = true end
    for id in pairs(incoming) do ids[id] = true end
    for id in pairs(ids) do
        local old, new = current[id], incoming[id]
        if samePositions(flatten(old), flatten(new)) then
            current[id] = new
        else
            LiveWire.Anchor.reshape(id, function()
                D.table().inverters[id] = new
                D.invalidate(id)
            end)
        end
    end
    D.invalidate()
    if X.onChanged then X.onChanged() end
end

Events.OnReceiveGlobalModData.Add(function(key, data)
    if key == X.DATA_KEY and isClient() then X.receive(data) end
end)

Events.OnGameStart.Add(function()
    if isClient() then ModData.request(X.DATA_KEY) end
end)
