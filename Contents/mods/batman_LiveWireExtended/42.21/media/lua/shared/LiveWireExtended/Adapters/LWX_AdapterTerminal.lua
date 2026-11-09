-- LiveWire Extended: adapter of a power terminal of this sub-mod (D-36): its whole zone
-- follows its breaker. The adapter is only declared here: LWX_ModAdapters registers it.
require "LiveWireExtended/LWX_Points"
require "LiveWireExtended/LWX_Terminal"

local X = LiveWire.Extended
local PT = X.Points
X.AdapterSpecs = X.AdapterSpecs or {}

X.AdapterSpecs.terminal = {
    id = "terminal",
    recognize = function(o) return X.Terminal.isTerminal(o) and X.Terminal.recordAt(o:getSquare()) ~= nil end,
    pieces = function(o) return { o } end,
    watts = function() return 0 end,   -- its zone's appliances are measured by Live Wire
    isOn = function(o) return not PT.blocked(o) end,
    apply = function(o, off)
        if isClient() or not X.Connect then return end
        local sq = o:getSquare()
        local key = X.Terminal.key(sq:getX(), sq:getY(), sq:getZ())
        local t = X.Terminal.recordAt(sq)
        local e = t and X.Data.entry(t.inv)
        local area = e and e.areas and e.areas["t:" .. key]
        if not area or (area.off == true) == off then return end
        X.Connect.commit(t.inv, function(entry)
            local a = entry.areas["t:" .. key]
            if a then a.off = off or nil end
        end)
    end,
}
