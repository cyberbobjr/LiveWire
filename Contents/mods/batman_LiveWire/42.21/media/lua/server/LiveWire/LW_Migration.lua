-- Live Wire: registry schema migrations (authority only).
-- Rules: idempotent, logged, never delete a device (unknown data goes to `legacy`).
-- ModData.getOrCreate is usable here: Registry.init runs on OnInitGlobalModData.
if isClient() then return end

LiveWire = LiveWire or {}

local Migration = {}
LiveWire.Migration = Migration

-- steps[n] upgrades schema n to n + 1.
Migration.steps = {}

-- 1 -> 2 (mod 0.1.1): devices became tiles of the mod tileset. Devices of schema 1
-- were vanilla sprites marked at the root of their ModData; they can no longer be
-- recognised (and the heavy inverter is gone). Every network and every device is
-- moved to `legacy`, and the public anchors of the old inverters are withdrawn.
-- The old objects stay in the world as plain furniture.
Migration.steps[1] = function(data)
    data.legacy = data.legacy or {}
    data.legacy.schema1 = { devices = data.devices, grids = data.grids, byPos = data.byPos }
    local anchors = ModData.getOrCreate(LiveWire.ANCHOR_KEY)
    for id, dev in pairs(data.devices) do
        if dev.role == "inverter" then anchors[id] = nil end
    end
    data.devices, data.grids, data.byPos = {}, {}, {}
end

-- Returns true when the data is usable, false when it comes from a newer mod version.
function Migration.run(data)
    if data.schema == nil then
        data.schema = LiveWire.SCHEMA
        return true
    end
    if data.schema > LiveWire.SCHEMA then
        LiveWire.warn("registry schema " .. tostring(data.schema) .. " is newer than this mod ("
            .. tostring(LiveWire.SCHEMA) .. "): simulation suspended, nothing will be written")
        return false
    end
    while data.schema < LiveWire.SCHEMA do
        local step = Migration.steps[data.schema]
        if not step then
            LiveWire.warn("no migration from schema " .. tostring(data.schema))
            return false
        end
        local from = data.schema
        step(data)
        data.schema = from + 1
        LiveWire.log("migrated registry schema " .. tostring(from) .. " -> " .. tostring(data.schema))
    end
    return true
end
