-- Live Wire: registry schema migrations (authority only).
-- Rules: idempotent, logged, never delete a device (unknown data goes to `legacy`).
if isClient() then return end

LiveWire = LiveWire or {}

local Migration = {}
LiveWire.Migration = Migration

-- steps[n] upgrades schema n to n + 1. Empty for schema 1.
Migration.steps = {}

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
