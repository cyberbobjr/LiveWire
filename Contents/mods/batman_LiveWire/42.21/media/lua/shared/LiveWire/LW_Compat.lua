-- Live Wire: optional mods detected at start-up.
--   Computer Mod (id ComputerModkum, Workshop 3725497089) and its Laptop addon
--   (id ComputerModLaptop, Workshop 3798992436): the management software can be
--   installed on their computers (LW_ComputerMod.lua).

LiveWire = LiveWire or {}

local Compat = {}
LiveWire.Compat = Compat

-- Mod ids may come with a path prefix in Build 42 lists: compare the end.
function Compat.isModActive(id)
    local mods = getActivatedMods and getActivatedMods()
    if not mods then return false end
    for i = 0, mods:size() - 1 do
        local m = tostring(mods:get(i))
        if m == id or string.sub(m, -(#id + 1)) == "\\" .. id or string.sub(m, -(#id + 1)) == "/" .. id then
            return true
        end
    end
    return false
end

function Compat.computerMod()
    return Compat.isModActive("ComputerModkum")
end
