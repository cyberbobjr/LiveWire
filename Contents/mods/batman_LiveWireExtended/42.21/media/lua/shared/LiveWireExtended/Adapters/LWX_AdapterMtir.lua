-- LiveWire Extended: adapter of My Tailor Is Rich (D-38). Only active when the mod is
-- loaded; nothing here is required by another mod. The electric sewing machine's power
-- test asks LiveWire.Extended.isCut(machine) (MTIR_SewingMachine.lua), so there is no
-- service to stop here. The adapter is only declared here: LWX_ModAdapters registers it.
require "LiveWireExtended/LWX_Points"

local X = LiveWire.Extended
local Ad, PT = X.Adapters, X.Points
X.AdapterSpecs = X.AdapterSpecs or {}

-- Estimated draw (the mod draws nothing in the engine) follows the Live Wire sandbox
-- like every appliance: PowerScale and the factor of the consumption profile.
Ad.MTIR_WATTS = 100

X.AdapterSpecs.mtir = {
    id = "mtir",
    recognize = function(o)
        local kind = MTIR and MTIR.getMachineKind and MTIR.getMachineKind(o)
        return kind ~= nil and kind.needsPower == true
    end,
    pieces = function(o) return { o } end,
    watts = function(o) return PT.blocked(o) and 0 or LiveWire.API.estimateWatts(Ad.MTIR_WATTS) end,
    estimated = true,   -- no engine draw: billed to the inverter through extraWatts
    isOn = function(o) return not PT.blocked(o) end,
    apply = function() end,
}
