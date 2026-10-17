-- Live Wire: when a chunk loads on the authority, push registry snapshots onto
-- the batteries it contains (nobody could touch them while unloaded), apply the
-- fuel a backup generator burnt while unloaded, and drop the
-- demand inventory of nearby inverters (docs/architecture.md section 6.2).
if isClient() then return end

LiveWire = LiveWire or {}

local CHUNK = 8

local function onLoadChunk(chunk)
    local R = LiveWire.Registry
    if not R or not R.ready or R.readOnly then return end
    local cx, cy = LiveWire.Anchor.chunkCoords(chunk)
    if not cx then return end
    local x0, y0 = cx * CHUNK, cy * CHUNK
    local x1, y1 = x0 + CHUNK - 1, y0 + CHUNK - 1
    local reach = LiveWire.Config.tileRange() + CHUNK
    local R2 = reach * reach
    for _, dev in pairs(R.devices()) do
        if dev.x >= x0 and dev.x <= x1 and dev.y >= y0 and dev.y <= y1 then
            if dev.role == "storage" then LiveWire.Batteries.restore(dev) end
            if dev.role == "backup" then LiveWire.Backup.restore(dev) end
        end
        if dev.role == "inverter" then
            local dx, dy = dev.x - (x0 + 4), dev.y - (y0 + 4)
            if dx * dx + dy * dy <= R2 then LiveWire.Demand.invalidate(dev.id) end
        end
    end
end

Events.LoadChunk.Add(onLoadChunk)
