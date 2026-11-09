-- LiveWire Extended: adapter of Functional Appliances 2 machines set to a temperature
-- (D-38). The setting lives in the object ModData (`CustomTemp`) and the container
-- temperature (E12). Only active when the mod is loaded. The adapter is only declared
-- here: LWX_ModAdapters registers it; the menu patch is client/LWX_Fa2Menu.lua.
require "LiveWireExtended/LWX_Points"

local X = LiveWire.Extended
local Ad = X.Adapters
X.AdapterSpecs = X.AdapterSpecs or {}

-- Draw while set: warm or hot 800 W, cold 300 W (estimates; the mod draws nothing).
Ad.FA_WATTS = { Warm = 800, Hot = 800, Cold = 300 }
local SAVED = "LWXSavedTemp"
local function faSetting(o)
    if not FA or not o.getContainer or not o:hasModData() then return nil end
    local md = o:getModData()
    return md[SAVED] or md.CustomTemp
end

X.AdapterSpecs.fa2 = {
    id = "fa2",
    estimated = true,
    recognize = function(o)
        local t = faSetting(o)
        return t ~= nil and o:getContainer() ~= nil
    end,
    pieces = function(o) return { o } end,
    watts = function(o)
        local md = o:getModData()
        return LiveWire.API.estimateWatts(Ad.FA_WATTS[md.CustomTemp] or 0)
    end,
    isOn = function(o) return o:getModData().CustomTemp ~= "Off" end,
    -- Cut: keep the setting, room temperature and "Off" as the mod does without current.
    -- Restore: put the setting back; the mod applies its temperature (updateMachineTemp
    -- when available, otherwise when the object loads).
    apply = function(o, off)
        local md, c = o:getModData(), o:getContainer()
        if off then
            if md.CustomTemp ~= "Off" and md[SAVED] == nil then
                md[SAVED] = md.CustomTemp
                md.CustomTemp = "Off"
                c:setCustomTemperature(1)
            end
        elseif md[SAVED] ~= nil then
            md.CustomTemp = md[SAVED]
            md[SAVED] = nil
            if FA.updateMachineTemp then FA.updateMachineTemp(o) end
        else
            return
        end
        o:transmitModData()
        if c.requestSync then c:requestSync() end
    end,
}
