if isClient() then return end
-- LiveWire Extended: twilight switch fitted on a breaker (D-39). Its circuit is closed
-- only between the season's dusk and dawn (LWX_Breakers.isOpen). Fitted and removed
-- with a screwdriver; every ten game minutes the switches whose state changed re-apply
-- their points.
require "LiveWireExtended/LWX_PointsServer"

local X = LiveWire.Extended
local PT, B, P = X.Points, X.Breakers, X.Panel
local PS = X.Panels
local TW = {}
X.Twilight = TW

local function transmit()
    if isServer() then ModData.transmit(X.DATA_KEY) end
end

-- Fit (on = true) or remove the twilight switch of the breaker of module `pos`.
function PS.setTwilight(character, boardObj, pos, on)
    local record = P.isPanel(boardObj) and P.recordAt(boardObj:getSquare())
    if not record then return false end
    local slot = B.slotAt(record, tonumber(pos))
    if not slot or type(on) ~= "boolean" or (slot.twilight == true) == on then return false end
    local I = LiveWire.Install
    if not I.screwdriver(character) then
        LiveWire.notify(character, "Tooltip_LW_NeedScrewdriver", {}, true)
        return false
    end
    if on then
        if I.countType(character, B.TWILIGHT_ITEM) < 1 then
            LiveWire.notify(character, "Tooltip_LWX_NoTwilightItem", {}, true)
            return false
        end
        if not I.consume(character, B.TWILIGHT_ITEM, 1) then return false end
        slot.twilight = true
    else
        slot.twilight = nil
        I.giveItem(character, B.TWILIGHT_ITEM)
    end
    slot.night = B.isNight()
    transmit()
    PT.applySlot(slot)
    LiveWire.notify(character, on and "IGUI_LWX_TwilightFitted" or "IGUI_LWX_TwilightRemoved", { tostring(slot.pos) })
    return true
end

-- Re-apply the points of the twilight switches whose day or night state changed.
function TW.tick()
    local night, any = B.isNight(), false
    for _, r in pairs(X.Data.table().panels or {}) do
        for _, slot in ipairs(r.slots or {}) do
            if slot.twilight and slot.night ~= night then
                slot.night, any = night, true
                PT.applySlot(slot)
            end
        end
    end
    if any then transmit() end
end

-- A removed breaker gives its twilight switch back too.
local previousRemoved = PS.onBreakerRemoved
PS.onBreakerRemoved = function(record, slot, character)
    if previousRemoved then previousRemoved(record, slot, character) end
    if slot.twilight and character then LiveWire.Install.giveItem(character, B.TWILIGHT_ITEM) end
end

Events.EveryTenMinutes.Add(TW.tick)
