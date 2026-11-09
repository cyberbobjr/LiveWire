-- Live Wire: drawing and window helpers shared by the client panels, the counterpart of
-- LW_UIScale.lua (sizes) for what every window repeated: filled rectangles and borders
-- drawn from a {r, g, b} colour table, buttons, the single-window life cycle, and the
-- snapshot figures read by both the inverter LCD and the management software.
if isServer() then return end

require "ISUI/ISButton"
require "LiveWire/LW_UIScale"

LiveWire = LiveWire or {}

local Kit = {}
LiveWire.UIKit = Kit

-- Delay between two subscriptions of an open window to the snapshots of its inverter.
Kit.RESUBSCRIBE_MS = 60 * 1000

-- Filled rectangle. `ui` is any UI element; when the window carries a scale factor
-- (`ui.lwK`, set once at creation) the reference-pixel coordinates are multiplied by it.
function Kit.rect(ui, x, y, w, h, c, a)
    local k = ui.lwK or 1
    ui:drawRect(x * k, y * k, w * k, h * k, a or 1, c[1], c[2], c[3])
end

function Kit.border(ui, x, y, w, h, c, a)
    local k = ui.lwK or 1
    ui:drawRectBorder(x * k, y * k, w * k, h * k, a or 1, c[1], c[2], c[3])
end

-- Plain ISButton added to `ui`. `k` (optional): the reference-pixel coordinates are
-- scaled and rounded with LiveWire.UIScale.px; without it they are used as given.
function Kit.button(ui, x, y, w, h, title, onclick, internal, k)
    if k then
        local px = LiveWire.UIScale.px
        x, y, w, h = px(x, k), px(y, k), px(w, k), px(h, k)
    end
    local b = ISButton:new(x, y, w, h, title, ui, onclick)
    b.internal = internal
    b:initialise()
    b:instantiate()
    ui:addChild(b)
    return b
end

-- Single-window life cycle of a panel class: at most one instance (`Panel.instance`),
-- listed in LiveWire.Client.panels so that the end of the session closes it.
--   Panel.closeInstance()      close the open window, if any (first line of Panel.open)
--   Panel.releaseInstance(p)   forget `p` when it is the open window; true when it was
-- Registered by name: a Lua reload replaces the class instead of listing it twice.
function Kit.singleton(name, Panel)
    local client = LiveWire.Client or {}
    LiveWire.Client = client
    client.panels = client.panels or {}
    client.panels[name] = Panel
    function Panel.closeInstance()
        if Panel.instance then Panel.instance:close() end
    end
    function Panel.releaseInstance(self)
        if Panel.instance == self then
            Panel.instance = nil
            return true
        end
        return false
    end
end

-------------------------------------------------------------------------------
-- Snapshot figures shared by the inverter LCD and the management software
-------------------------------------------------------------------------------
local View = {}
LiveWire.SnapshotView = View

-- Source families in display order, by Defs kind; the translation key of a family is
-- IGUI_LW_Family_<Kind> (first letter upper case). The only list of families.
View.FAMILIES = { "solar", "wind", "hydro" }

-- One scale for the production and load bars: the largest of the inverter rating, the
-- nominal power of the sources, the production and the demand (never under 1).
function View.scale(snap)
    local nominal = 0
    for i = 1, #snap.sources do nominal = nominal + (snap.sources[i].nominal or 0) end
    return math.max(snap.inverter.maxW or 0, nominal, snap.production or 0, snap.demand or 0, 1)
end

-- { { kind, key, n, w } ... }: number of sources and watts per family, in display order.
function View.familyTotals(snap)
    local out = {}
    for _, kind in ipairs(View.FAMILIES) do
        local n, w = 0, 0
        for i = 1, #snap.sources do
            if snap.sources[i].kind == kind then n = n + 1; w = w + snap.sources[i].w end
        end
        local name = string.upper(string.sub(kind, 1, 1)) .. string.sub(kind, 2)
        out[#out + 1] = { kind = kind, key = "IGUI_LW_Family_" .. name, n = n, w = w }
    end
    return out
end
