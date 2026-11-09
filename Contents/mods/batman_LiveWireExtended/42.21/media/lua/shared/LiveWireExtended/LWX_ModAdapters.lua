-- LiveWire Extended: adapters beyond the vanilla families (D-38, D-36). Each lives in
-- its own file under Adapters/ and is only active when what it adapts is loaded; nothing
-- here is required by another mod.
--   mtir      My Tailor Is Rich electric sewing machine (LWX_AdapterMtir)
--   fa2       Functional Appliances 2 machines set to a temperature (LWX_AdapterFa2)
--   livewire  Live Wire water pump and management computer (LWX_AdapterLiveWire)
--   terminal  a power terminal of this sub-mod: its whole zone follows its breaker
--             (LWX_AdapterTerminal)
-- This file registers them in that order (mod adapters are tried in registration order),
-- whatever the order in which the engine loaded the adapter files.
require "LiveWireExtended/LWX_Points"
require "LiveWireExtended/Adapters/LWX_AdapterMtir"
require "LiveWireExtended/Adapters/LWX_AdapterFa2"
require "LiveWireExtended/Adapters/LWX_AdapterLiveWire"
require "LiveWireExtended/Adapters/LWX_AdapterTerminal"

local X = LiveWire.Extended

for _, id in ipairs({ "mtir", "fa2", "livewire", "terminal" }) do
    X.Adapters.register(X.AdapterSpecs[id])
end

-- Public, for other mods: has object `o` no current because of a breaker board?
-- (an open or tripped breaker, or unwired in a building or zone a board serves).
function X.isCut(o)
    return o ~= nil and X.Points.blocked(o)
end
