-- Live Wire: internal event bus. A low layer (the registry, the placement wrappers, the
-- anchors) tells "something happened" without knowing which module cares: each module
-- subscribes itself when its file loads. The module is LiveWire.Events (never a global
-- named Events: that is the engine's table).
--
-- Closed list of event names (the constants below; an unknown name is a programming
-- error). Arguments are those of the call the emitter used to make directly.
--   REGISTRY_RESET           ()                        Registry.init: drop every cache
--                                                      (LW_Circuits, LW_Demand)
--   TOPOLOGY_CHANGED         ()                        a network was coupled, uncoupled or
--                                                      an inverter removed (LW_Circuits)
--   GRID_RELEASED            (grid, defer)             a grid loses its breaker control
--                                                      (LW_Circuits.release)
--   JOURNAL_ENTRY            (grid, key, args)         one line of the network journal
--                                                      (LW_Events.lua: Journal.add)
--   INVERTER_REMOVED         (id)                      forget the demand of that inverter
--                                                      (LW_Demand)
--   SQUARE_CHANGED           (square)                  furniture was placed on a square, any
--                                                      side (LW_PumpRelays, LW_PumpView,
--                                                      LW_FridgeAging)
--   DEVICE_PLACED            (character, square, sprite)  one of our tiles was placed, authority
--                                                      only (LW_Devices)
--   DEVICE_PICKED_UP         (id, character)           one of our tiles was picked up, authority
--                                                      only (LW_Devices)
--   ROTATION_STARTED         ()                        one of our tiles starts being rotated, authority
--                                                      only: a pickup now is a rotation (LW_Devices)
--   ROTATION_ENDED           ()                        the rotation is over (LW_Devices)
--   COVERAGE_CHANGED         (square)                  authority: invalidate the demand of the
--                                                      inverters covering the square (LW_Demand)
--   SQUARE_OBJECTS_CHANGED   (square)                  authority: re-apply the circuits to the
--                                                      objects of the square (LW_Circuits);
--                                                      always emitted AFTER COVERAGE_CHANGED
--   ANCHOR_CHANGING          (anchor, id)              before the power of an anchor changes:
--                                                      settle the fridge food (LW_FridgeAging)
--   ANCHOR_VISUALS           (anchor, id)              client: refresh the powered squares
--                                                      (LW_AnchorVisuals)
--   CHUNK_LOADED             (chunk)                   a chunk was loaded (LW_FridgeAging index)
--
-- Subscribers run in registration order; emit does not catch errors; a subscriber added
-- during an emit runs from the next emit on. Subscribe with a closure that looks the
-- module up when the event fires, so a module replaced later is still reached.

LiveWire = LiveWire or {}

local Events = LiveWire.Events or {}
LiveWire.Events = Events

local NAMES = {
    "REGISTRY_RESET", "TOPOLOGY_CHANGED", "GRID_RELEASED", "JOURNAL_ENTRY", "INVERTER_REMOVED",
    "SQUARE_CHANGED", "DEVICE_PLACED", "DEVICE_PICKED_UP", "ROTATION_STARTED", "ROTATION_ENDED",
    "COVERAGE_CHANGED", "SQUARE_OBJECTS_CHANGED",
    "ANCHOR_CHANGING", "ANCHOR_VISUALS", "CHUNK_LOADED",
}
local known = {}
for i = 1, #NAMES do
    Events[NAMES[i]] = NAMES[i]
    known[NAMES[i]] = true
end

local listeners = Events.listeners or {}
Events.listeners = listeners

local function check(name)
    if not known[name] then error("LiveWire.Events: unknown event " .. tostring(name), 3) end
end

-- Register `fn` for `name`. The same function registered twice for the same name runs once.
function Events.on(name, fn)
    check(name)
    if type(fn) ~= "function" then error("LiveWire.Events.on: handler must be a function", 2) end
    local list = listeners[name]
    if not list then
        list = {}
        listeners[name] = list
    end
    for i = 1, #list do
        if list[i] == fn then return end
    end
    list[#list + 1] = fn
end

-- Unregister `fn` (no effect when it was not registered).
function Events.off(name, fn)
    check(name)
    local list = listeners[name]
    if not list then return end
    for i = 1, #list do
        if list[i] == fn then
            table.remove(list, i)
            return
        end
    end
end

-- Call every subscriber of `name` with the given arguments, in registration order.
function Events.emit(name, ...)
    check(name)
    local list = listeners[name]
    if not list then return end
    local n = #list
    local snapshot = {}
    for i = 1, n do snapshot[i] = list[i] end
    for i = 1, n do snapshot[i](...) end
end
