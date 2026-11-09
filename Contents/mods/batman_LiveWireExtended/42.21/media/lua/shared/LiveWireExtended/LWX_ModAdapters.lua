-- LiveWire Extended: adapters beyond the vanilla families (D-38, D-36). Each is only
-- active when what it adapts is loaded; nothing here is required by another mod.
--   mtir      My Tailor Is Rich electric sewing machine: its power test asks
--             LiveWire.Extended.isCut(machine) (MTIR_SewingMachine.lua), no service
--             to stop here.
--   fa2       Functional Appliances 2 machines set to a temperature: the setting lives
--             in the object ModData (`CustomTemp`) and the container temperature (E12).
--   livewire  Live Wire water pump and management computer: Live Wire asks the circuit
--             provider (deviceBlocked) for the registry device.
--   terminal  a power terminal of this sub-mod: its whole zone follows its breaker.
require "LiveWireExtended/LWX_Points"
require "LiveWireExtended/LWX_Terminal"

local X = LiveWire.Extended
local Ad, PT = X.Adapters, X.Points

-- Public, for other mods: has object `o` no current because of a breaker board?
-- (an open or tripped breaker, or unwired in a building or zone a board serves).
function X.isCut(o)
    return o ~= nil and PT.blocked(o)
end

local function blocked(o) return PT.blocked(o) end

-- ---------------------------------------------------------------- My Tailor Is Rich
Ad.MTIR_WATTS = 100
Ad.register({
    id = "mtir",
    recognize = function(o)
        local kind = MTIR and MTIR.getMachineKind and MTIR.getMachineKind(o)
        return kind ~= nil and kind.needsPower == true
    end,
    pieces = function(o) return { o } end,
    watts = function(o) return blocked(o) and 0 or Ad.MTIR_WATTS end,
    isOn = function(o) return not blocked(o) end,
    apply = function() end,
})

-- ---------------------------------------------------------------- Functional Appliances 2
-- Draw while set: warm or hot 800 W, cold 300 W (estimates; the mod draws nothing).
Ad.FA_WATTS = { Warm = 800, Hot = 800, Cold = 300 }
local SAVED = "LWXSavedTemp"
local function faSetting(o)
    if not FA or not o.getContainer or not o:hasModData() then return nil end
    local md = o:getModData()
    return md[SAVED] or md.CustomTemp
end

Ad.register({
    id = "fa2",
    recognize = function(o)
        local t = faSetting(o)
        return t ~= nil and o:getContainer() ~= nil
    end,
    pieces = function(o) return { o } end,
    watts = function(o)
        local md = o:getModData()
        return Ad.FA_WATTS[md.CustomTemp] or 0
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
})

-- Functional Appliances 2 menus test the square's current only: while a machine is cut,
-- its options are greyed out (client).
if not isServer() then
    Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context)
        if not FA or not context or not context.options then return end
        for _, opt in ipairs(context.options) do
            for k = 1, 10 do
                local p = opt["param" .. k]
                if p and instanceof(p, "IsoObject") then
                    local a = Ad.find(p)
                    if a and a.id == "fa2" and blocked(p) then
                        opt.notAvailable = true
                        local t = ISWorldObjectContextMenu.addToolTip()
                        t.description = getText("Tooltip_LWX_MachineCut")
                        opt.toolTip = t
                        break
                    end
                end
            end
        end
    end)
end

-- ---------------------------------------------------------------- Live Wire devices
local function deviceId(o)
    local m = LiveWire.Marks and LiveWire.Marks.get(o)
    local def = m and LiveWire.Defs.devices[m.model]
    if def and def.role == "pump" then return m.id end
    local key = LiveWire.Defs.COMPUTER_KEY
    local c = o.hasModData and o:hasModData() and o:getModData()[key]
    return c and c.id or nil
end

Ad.register({
    id = "livewire",
    recognize = function(o) return deviceId(o) ~= nil end,
    identity = function(o) return "dev:" .. tostring(deviceId(o)) end,
    pieces = function(o) return { o } end,
    watts = function() return 0 end,   -- billed by Live Wire itself
    isOn = function(o) return not blocked(o) end,
    apply = function() end,            -- Live Wire reads deviceBlocked at its next step
})

X.circuitProvider.deviceBlocked = function(dev)
    return PT.blockedKey("dev:" .. tostring(dev.id), dev.x, dev.y, dev.z)
end

-- ---------------------------------------------------------------- power terminal
Ad.register({
    id = "terminal",
    recognize = function(o) return X.Terminal.isTerminal(o) and X.Terminal.recordAt(o:getSquare()) ~= nil end,
    pieces = function(o) return { o } end,
    watts = function() return 0 end,   -- its zone's appliances are measured by Live Wire
    isOn = function(o) return not blocked(o) end,
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
})
