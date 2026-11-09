"""Offline test: a chunk load never leaves an anchor purged (embedded Lua 5.1, pip install lupa).

The engine purges generator positions on the loaded chunk and on every chunk within
+/- generatorChunkRange of it, a square (IsoGenerator.chunkLoaded, IsoGenerator.java:593-603).
That range is 2 until an IsoGenerator exists in the session, then GeneratorTileRange / 8 + 1
(IsoGenerator.java:67, 115-119). The engine is modelled here; this proves the Lua handler
re-applies the anchor for every load that can purge it, not the engine itself.
Run: python3 -I tests/test_anchor_purge.py
"""
import os
import unittest

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHARED = os.path.join(ROOT, "Contents", "mods", "batman_LiveWire", "42.21", "media", "lua",
                      "shared", "LiveWire")
ANCHOR = os.path.join(SHARED, "LW_Anchor.lua")
BUS = os.path.join(SHARED, "LW_EventBus.lua")
COVERAGE = os.path.join(SHARED, "LW_Coverage.lua")  # the disc lives there (D-32)
EXTENSION = os.path.join(SHARED, "LW_Extension.lua")  # Coverage is built on it

STUBS = r"""
function require() end
function isClient() return false end
function isServer() return false end
function instanceof() return false end
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = function() end }
    rawset(t, k, e); return e end })
local MD = {}
ModData = {
    getOrCreate = function(k) MD[k] = MD[k] or {}; return MD[k] end,
    add = function(k, v) MD[k] = v end, request = function() end,
}
RANGE = 20
LiveWire = {
    ANCHOR_KEY = "LiveWireAnchors",
    posKey = function(x, y, z) return x .. "," .. y .. "," .. z end,
    Config = { tileRange = function() return RANGE end, verticalRange = function() return 3 end },
    Compat = { addLoadChunk = function(fn) LOAD_CHUNK = fn end },
}

-- Engine model: chunks by "cx,cy", each with its generator position list.
CHUNKS = {}
local function chunkAt(cx, cy)
    local key = cx .. "," .. cy
    local c = CHUNKS[key]
    if c then return c end
    local sq = { getX = function() return cx * 8 end, getY = function() return cy * 8 end,
                 getObjects = function() return { size = function() return 0 end } end }
    c = { cx = cx, cy = cy, pos = {} }
    function c:addGeneratorPos(x, y, z) self.pos[x .. "," .. y .. "," .. z] = true end
    function c:removeGeneratorPos(x, y, z) self.pos[x .. "," .. y .. "," .. z] = nil end
    function c:getMinLevel() return 0 end
    function c:getMaxLevel() return 0 end
    function c:getGridSquare(i, j, z) if i == 0 and j == 0 then return sq end end
    CHUNKS[key] = c
    return c
end
function getCell()
    return { getChunkForGridSquare = function(_, x, y)
        return chunkAt(math.floor(x / 8), math.floor(y / 8)) end }
end

-- IsoGenerator.chunkLoaded: purge the square of +/- g chunks, then LoadChunk fires.
function engineLoad(cx, cy, g)
    for dy = -g, g do
        for dx = -g, g do
            local c = CHUNKS[(cx + dx) .. "," .. (cy + dy)]
            if c then c.pos = {} end
        end
    end
    LOAD_CHUNK(chunkAt(cx, cy))
end

-- Every chunk touched by the disc must carry the anchor position.
function missing(a)
    local R = RANGE
    for cy = math.floor((a.y - R) / 8), math.floor((a.y + R) / 8) do
        for cx = math.floor((a.x - R) / 8), math.floor((a.x + R) / 8) do
            if LiveWire.Anchor.touches(cx, cy, a, R)
                and not chunkAt(cx, cy).pos[a.x .. "," .. a.y .. "," .. a.z] then
                return cx .. "," .. cy
            end
        end
    end
    return nil
end

-- Try every anchor position in its chunk and every chunk load around it.
function sweep(g)
    local a = { x = 0, y = 0, z = 0, on = true }
    ModData.getOrCreate(LiveWire.ANCHOR_KEY).inv = a
    local span = math.floor(RANGE / 8) + g + 2
    for ax = 0, 7 do
        for ay = 0, 7 do
            a.x, a.y = 800 + ax, 800 + ay
            CHUNKS = {}
            LiveWire.Anchor.apply(a, true)
            for ly = 100 - span, 100 + span do
                for lx = 100 - span, 100 + span do
                    engineLoad(lx, ly, g)
                    local gap = missing(a)
                    if gap then
                        return string.format("anchor %d,%d load %d,%d purge %d left chunk %s unpowered",
                            a.x, a.y, lx, ly, g, gap)
                    end
                end
            end
        end
    end
    return nil
end
"""


def load():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUBS)
    for path in (BUS, EXTENSION, COVERAGE, ANCHOR):
        with open(path, encoding="utf-8") as f:
            lua.execute(f.read())
    return lua


class AnchorPurge(unittest.TestCase):
    def check(self, rng, purge):
        lua = load()
        lua.execute("RANGE = %d" % rng)
        self.assertIsNone(lua.eval("sweep(%d)" % purge))

    def test_default_range_without_generator(self):
        self.check(20, 2)

    def test_default_range_with_a_vanilla_generator(self):
        # The player's backup generator sets generatorChunkRange to 20 / 8 + 1 = 3.
        self.check(20, 3)

    def test_small_range_keeps_engine_default(self):
        # generatorChunkRange stays 2 without a generator even when 4 / 8 + 1 = 1.
        self.check(4, 2)

    def test_large_range(self):
        self.check(40, 40 // 8 + 1)

    def test_far_chunk_is_ignored(self):
        lua = load()
        lua.execute("A = { x = 804, y = 804, z = 0, on = true }")
        self.assertFalse(lua.eval("LiveWire.Anchor.purgedBy(A, 100 + 7, 100, 20)"))
        self.assertTrue(lua.eval("LiveWire.Anchor.purgedBy(A, 100 + 6, 100 + 6, 20)"))


if __name__ == "__main__":
    unittest.main()
