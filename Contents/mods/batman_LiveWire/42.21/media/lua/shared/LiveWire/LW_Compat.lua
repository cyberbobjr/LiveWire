-- Live Wire: optional mods detected at start-up.
--   Computer Mod (id ComputerModkum, Workshop 3725497089) and its Laptop addon
--   (id ComputerModLaptop, Workshop 3798992436): the management software can be
--   installed on their computers (LW_ComputerMod.lua).
--   Let Me Drive! (id LetMeDrive, Workshop 3805307651): the chunk handlers that
--   must not be deferred are registered past its event queue (Compat.addLoadChunk).

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

-- Register a LoadChunk handler that must run inside the engine's own event call,
-- never a frame later. The engine purges our generator positions in the middle of
-- IsoChunk.doLoadGridsquare -- for the arriving chunk AND its neighbours within
-- generatorChunkRange (IsoGenerator.java:593-603, IsoChunk.java:4785-4797) -- and
-- fires LoadChunk only at the end of that same method (IsoChunk.java:3612).
-- Food.updateAge then applies the WHOLE elapsed absence with the power state of
-- the moment and writes lastAged (Food.java:668-712), so a handler that runs one
-- frame late leaves a base-wide area unpowered and the fridge catch-up with
-- nothing left to correct (LW_FridgeCatchup.lua).
--
-- Let Me Drive! (id LetMeDrive) replaces the Events.LoadChunk table at load and
-- queues the handlers of every mod loaded after it, a few milliseconds per tick.
-- It exposes LetMeDrive.Gate.addRaw, which registers through the event's original
-- Add, so the handler lands in the engine's own list and is never queued. Its own
-- exemption for generator squares cannot cover us: it tests a real IsoGenerator
-- object, and our anchors are positions without one.
--
-- A capability test, not a mod-list test: without that mod the table does not
-- exist and this is the plain Events.LoadChunk.Add of before, at no cost. Safe in
-- both load orders, since the gate captures the event when its own file runs: a
-- plain Add made before that already lands in the engine's list.
local chunkAdd  -- nil: not resolved yet. false: plain Events.LoadChunk.Add.

function Compat.addLoadChunk(fn)
    if chunkAdd == nil then
        chunkAdd = false
        local lmd = rawget(_G, "LetMeDrive")
        local gate = type(lmd) == "table" and lmd.Gate
        if type(gate) == "table" and type(gate.addRaw) == "function" then
            chunkAdd = gate.addRaw
            -- print, not LiveWire.log: LW_Core loads after the files that require
            -- this one (files load in lower-case path order).
            print("[LiveWire] Let Me Drive! detected: chunk power handlers "
                .. "registered on the engine event so they are never deferred")
        end
    end
    if chunkAdd then chunkAdd("LoadChunk", fn) else Events.LoadChunk.Add(fn) end
end
