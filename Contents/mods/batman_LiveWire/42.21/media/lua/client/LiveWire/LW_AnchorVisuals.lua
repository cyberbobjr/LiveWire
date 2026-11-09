-- Live Wire: client-side visuals of the power anchors (never loaded on a dedicated server).
-- Wake fridge hum, ambient sounds and light sources of the powered objects, as the
-- engine does on generator activation (IsoGenerator.java:279, IsoObject.java:4800-4812).
-- checkHaveElectricity does nothing on a server. The squares are visited a few
-- hundred per tick; the OnTick handler exists only while squares remain to visit.
if isServer() then return end

require "LiveWire/LW_Coverage"
require "LiveWire/LW_EventBus"

LiveWire = LiveWire or {}

local V = {}
LiveWire.AnchorVisuals = V

V.SQUARES_PER_TICK = 250
local queue = {}
local jobs = {}
local watching = false

function V.refresh(a, id)
    local key = LiveWire.posKey(a.x, a.y, a.z)
    if not jobs[key] then queue[#queue + 1] = key end
    -- Coalesce repeated toggles: effects read the current world power state.
    jobs[key] = LiveWire.Coverage.scan(id, a)
    if not watching then watching = true; Events.OnTick.Add(V.tick) end
end

function V.tick()
    local cell = getCell()
    if not cell then return end
    local budget = V.SQUARES_PER_TICK
    while budget > 0 and #queue > 0 do
        local key = queue[1]
        local done, used = LiveWire.Coverage.step(jobs[key], budget, function(x, y, z)
            local sq = cell:getGridSquare(x, y, z)
            if not sq then return end
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do
                local o = objs:get(i)
                if o:couldBePoweredByGenerator() then o:checkHaveElectricity() end
            end
        end)
        budget = budget - used
        if done then jobs[key] = nil; table.remove(queue, 1) end
    end
    if #queue == 0 then watching = false; Events.OnTick.Remove(V.tick) end
end

-- Told by the anchors (LW_EventBus.lua); nobody calls it on a dedicated server (file not loaded).
LiveWire.Events.on(LiveWire.Events.ANCHOR_VISUALS, function(a, id) return LiveWire.AnchorVisuals.refresh(a, id) end)
