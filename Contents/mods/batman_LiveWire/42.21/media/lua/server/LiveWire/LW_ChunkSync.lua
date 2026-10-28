-- Live Wire: when a chunk loads on the authority, push registry snapshots onto
-- the batteries it contains (nobody could touch them while unloaded), drop the
-- devices destroyed while unloaded, apply the
-- fuel a backup generator burnt while unloaded, and drop the
-- demand inventory of nearby inverters (docs/architecture.md section 6.2),
-- ages the fridge food of the chunk along the anchor power log (LW_FridgeCatchup.lua).
if isClient() then return end

LiveWire = LiveWire or {}

require "LiveWire/LW_Compat"

local CHUNK = 8

local function onLoadChunk(chunk)
    local R = LiveWire.Registry
    if not R or not R.ready or R.readOnly then return end
    -- Fridge food first: before Backup.restore (a vanilla generator that toggles ages
    -- the food around it) and before any game update reads it.
    if LiveWire.FridgeCatchup then
        local ok, err = pcall(LiveWire.FridgeCatchup.onLoadChunk, chunk)
        if not ok then LiveWire.warn("fridge catch-up failed: " .. tostring(err)) end
    end
    if LiveWire.Circuits then LiveWire.Circuits.onLoadChunk(chunk) end
    local cx, cy = LiveWire.Anchor.chunkCoords(chunk)
    if not cx then return end
    local x0, y0 = cx * CHUNK, cy * CHUNK
    local x1, y1 = x0 + CHUNK - 1, y0 + CHUNK - 1
    local reach = LiveWire.Config.tileRange() + CHUNK
    local R2 = reach * reach
    -- Copy first: validate() may remove devices from the registry.
    local list = R.devicesInChunk(cx, cy)
    for i = 1, #list do
        local dev = list[i]
        local inChunk = dev.x >= x0 and dev.x <= x1 and dev.y >= y0 and dev.y <= y1
        local alive = true
        if inChunk and LiveWire.Defs.devices[dev.model] then alive = LiveWire.Devices.validate(dev) end
        if alive then
            if inChunk and dev.role == "storage" then LiveWire.Batteries.restore(dev) end
            if inChunk and dev.role == "backup" then LiveWire.Backup.restore(dev) end
            if inChunk and dev.role == "inverter" then LiveWire.Devices.syncMark(dev) end
        end
    end
    for id in pairs(R.inverters) do
        local dev = R.device(id)
        local dx, dy = dev.x - (x0 + 4), dev.y - (y0 + 4)
        if dx * dx + dy * dy <= R2 then LiveWire.Demand.invalidate(id) end
    end
    if LiveWire.Pump then
        local ok, err = pcall(LiveWire.Pump.onLoadChunk, chunk)
        if not ok then LiveWire.warn("pump relay cleanup failed: " .. tostring(err)) end
    end
end

-- Past any event queue a performance mod may have installed: the fridge
-- catch-up has to settle the absence before anything ages the food, and a
-- single vanilla pass would leave it nothing to correct (LW_Compat.addLoadChunk).
LiveWire.Compat.addLoadChunk(onLoadChunk)
