-- LiveWire Extended: adapter of the Live Wire water pump and management computer (D-38).
-- Live Wire asks the circuit provider (deviceBlocked, LWX_CircuitProvider.lua) for the
-- registry device. The adapter is only declared here: LWX_ModAdapters registers it.
require "LiveWireExtended/LWX_Points"

local X = LiveWire.Extended
local PT = X.Points
X.AdapterSpecs = X.AdapterSpecs or {}

local function deviceId(o)
    return LiveWire.API.pumpId(o) or LiveWire.API.computerId(o)
end

X.AdapterSpecs.livewire = {
    id = "livewire",
    recognize = function(o) return deviceId(o) ~= nil end,
    identity = function(o) return "dev:" .. tostring(deviceId(o)) end,
    pieces = function(o) return { o } end,
    watts = function() return 0 end,   -- billed by Live Wire itself
    isOn = function(o) return not PT.blocked(o) end,
    apply = function() end,            -- Live Wire reads deviceBlocked at its next step
}
