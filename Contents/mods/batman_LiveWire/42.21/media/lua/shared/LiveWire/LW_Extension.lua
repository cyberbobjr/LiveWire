-- Live Wire: one-registrant extension points. An optional sub-mod registers ONE
-- provider table while Lua files load; registration closes at OnInitGlobalModData.
-- LiveWire.Coverage, LiveWire.CircuitProvider and LiveWire.Coupling are built on it.
--
--   local point = LiveWire.Extension.single(name, schema [, options])
--   point.register(p) -> true, or false and a reason:
--       "registration_closed" (after OnInitGlobalModData), "already_registered",
--       "invalid_provider" (not a table, or a field breaks the schema)
--   point.get()       -> the registered provider, or nil
--   point.active()    -> true when a provider is registered
--
-- `schema` maps a field name to its expected Lua type: "function", "boolean",
-- "number", "string", "table". A trailing "?" makes the field optional ("function?");
-- "any?" accepts any value. options.closed = true also refuses fields that are not
-- in the schema.
LiveWire = LiveWire or {}

local Extension = {}
LiveWire.Extension = Extension

local sealed = false

local function matches(spec, value)
    local optional = string.sub(spec, -1) == "?"
    local want = optional and string.sub(spec, 1, -2) or spec
    if value == nil then return optional end
    return want == "any" or type(value) == want
end

function Extension.single(name, schema, options)
    local closed = options ~= nil and options.closed == true
    local provider
    local point = { name = name }

    function point.register(p)
        if sealed then return false, "registration_closed" end
        if provider then return false, "already_registered" end
        if type(p) ~= "table" then return false, "invalid_provider" end
        for field, spec in pairs(schema) do
            if not matches(spec, p[field]) then return false, "invalid_provider" end
        end
        if closed then
            for field in pairs(p) do
                if schema[field] == nil then return false, "invalid_provider" end
            end
        end
        provider = p
        return true
    end

    function point.get() return provider end
    function point.active() return provider ~= nil end
    return point
end

-- True once registration is closed (for registries that are not a single provider).
function Extension.isSealed() return sealed end

Events.OnInitGlobalModData.Add(function() sealed = true end)
