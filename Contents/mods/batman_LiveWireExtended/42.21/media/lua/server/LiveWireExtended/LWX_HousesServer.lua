if isClient() then return end
-- LiveWire Extended: boards already in the map's buildings, on the authority (D-40, D-42).
-- When every room of a building is loaded for the first time in a session, the draw of
-- LWX_Houses decides (seeded by the building, nothing stored). A building reuses its vanilla
-- wall electrical box (inside, or weatherproof on its facade, D-62) when it has one; otherwise
-- a drawn building gets an Extended board on a free north wall of its ground floor. Buildings
-- made by players (userDefined) get none. The square keeps a mark (its own ModData, saved with the chunk) so that a board picked up is
-- never put back. The board is inert and outside every registry until a player links it to an
-- inverter: then, once, its breakers and per-room points are created (no label) and the
-- building is served (D-37).
require "LiveWireExtended/LWX_Houses"
require "LiveWireExtended/LWX_PointsServer"

local X = LiveWire.Extended
local H, P, B, PT, Ad = X.Houses, X.Panel, X.Breakers, X.Points, X.Adapters
local HS = {}
X.HousesServer = HS

HS.MAX_SQUARES = 2000      -- larger buildings (malls, factories) are skipped
HS.HOUSE_KEY = "LWXHouse"   -- object ModData: building key of a house board
HS.SQUARE_MARK = "LWXHouseBoard"
local done = {}             -- session: building keys already handled

local function roomRects(def, fn)
    local rooms = def:getRooms()
    for i = 0, rooms:size() - 1 do
        local room = rooms:get(i)
        local rects = room:getRects()
        for j = 0, rects:size() - 1 do fn(room, rects:get(j)) end
    end
end

local function size(def)
    local n = 0
    roomRects(def, function(_, r) n = n + r:getW() * r:getH() end)
    return n
end

local function loaded(def)
    local cell, ok = getCell(), true
    roomRects(def, function(room, r)
        local z = room:getZ()
        if not cell:getGridSquare(r:getX(), r:getY(), z)
            or not cell:getGridSquare(r:getX() + r:getW() - 1, r:getY() + r:getH() - 1, z) then ok = false end
    end)
    return ok
end

-- Each loaded room square of the building, in a stable order (rooms, then rectangles).
local function eachSquare(def, fn)
    local cell = getCell()
    roomRects(def, function(room, r)
        for y = r:getY(), r:getY() + r:getH() - 1 do
            for x = r:getX(), r:getX() + r:getW() - 1 do
                local sq = cell:getGridSquare(x, y, room:getZ())
                if sq then fn(sq, room) end
            end
        end
    end)
end

local function isHeavy(o)
    return (instanceof(o, "IsoStove") and not o:isMicrowave()) or instanceof(o, "IsoClothingDryer")
        or instanceof(o, "IsoCombinationWasherDryer") or instanceof(o, "IsoStackedWasherDryer")
end

-- Points of each room of the building and of the cellars under it (X.Buildings.group):
-- { key = roomDefKey, points = { { key, heavy, x, y, z, adapter } } }.
function HS.collect(def)
    local byRoom, order, seen = {}, {}, {}
    for _, part in ipairs(X.Buildings.group(def)) do eachSquare(part, function(sq, room)
        local rkey = room:getX() .. "," .. room:getY() .. "," .. room:getZ()  -- RoomDef
        local r = byRoom[rkey]
        if not r then
            r = { key = rkey, points = {} }
            byRoom[rkey] = r
            order[#order + 1] = r
        end
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            local a = Ad.find(o)
            local key = a and Ad.identity(o)
            if key and not seen[key] and a.id ~= "terminal" and a.id ~= "livewire" then
                seen[key] = true
                r.points[#r.points + 1] = { key = key, heavy = isHeavy(o), x = sq:getX(), y = sq:getY(),
                    z = sq:getZ(), adapter = a.id }
            end
        end
    end) end
    return order
end

-- Create the prewired breakers and points of a linked house board (once).
function HS.prewire(record, boardKey, rooms)
    if record.prewired then return false end
    local plan = H.plan(rooms, record.size)
    local info = {}
    for _, r in ipairs(rooms) do
        for _, p in ipairs(r.points) do info[p.key] = p end
    end
    local pos, points = 1, PT.table()
    record.slots = {}
    for _, s in ipairs(plan.slots) do
        local t = B.TYPES[s.type]
        local slot = { type = s.type, pos = pos, poles = t.poles, amps = t.amps, volts = t.volts,
            label = "", off = false, tripped = false, points = {} }
        for _, key in ipairs(s.points) do
            local p = info[key]
            if p and not points[key] then
                points[key] = { board = boardKey, pos = pos, x = p.x, y = p.y, z = p.z, adapter = p.adapter }
                slot.points[key] = true
            end
        end
        record.slots[#record.slots + 1] = slot
        pos = pos + t.poles
    end
    record.prewired = true
    return true
end

-- A house board linked for the first time: prewire it from its building.
local previousLink = P.kind.onLink
P.kind.onLink = function(record, dev, key, obj)
    if previousLink then previousLink(record, dev, key, obj) end
    local house = obj and obj:hasModData() and obj:getModData()[HS.HOUSE_KEY]
    if not house then return end
    record.house = house
    -- the site the board serves (inside, or across the wall of a weatherproof box) is that house
    local site = P.siteOf(record)
    if not site or site.kind ~= "building" or X.Sites.key(site) ~= house then return end
    if not HS.prewire(record, key, HS.collect(site.def)) then return end
    PT.regionsChanged()
    X.log("house board " .. key .. " of " .. tostring(house) .. " prewired: " .. #record.slots .. " breakers")
end

-- Bare north-wall square (H.bareWall) for an Extended board, or nil: lowest floor first,
-- then the room a real house would use (H.roomRank: garage, utility room, entrance).
local function wallSquare(def)
    local best, bestZ, bestRank
    eachSquare(def, function(sq, room)
        local z, rank = room:getZ(), H.roomRank(room:getName())
        local better = not bestZ or z < bestZ or (z == bestZ and rank < bestRank)
        if better and H.bareWall(sq) and not P.onSquare(sq) then
            best, bestZ, bestRank = sq, z, rank
        end
    end)
    return best
end

local function sheetIndex(modules)
    if modules > 16 then return 12 elseif modules > 8 then return 10 end
    return 8
end

-- Vanilla box of the map hanging on the facade: on a square just outside a room, against a
-- wall whose other side is a room of this building (X.Panel.acrossWall).
local function facadeBox(def)
    local inside, cell, found = {}, getCell(), nil
    roomRects(def, function(room, r)
        local z = room:getZ()
        for y = r:getY(), r:getY() + r:getH() - 1 do
            for x = r:getX(), r:getX() + r:getW() - 1 do inside[x .. "," .. y .. "," .. z] = true end
        end
    end)
    roomRects(def, function(room, r)
        local z = room:getZ()
        for y = r:getY() - 1, r:getY() + r:getH() do
            for x = r:getX() - 1, r:getX() + r:getW() do
                local sq = not found and not inside[x .. "," .. y .. "," .. z] and cell:getGridSquare(x, y, z)
                local objs = sq and sq:getObjects()
                for i = 0, objs and objs:size() - 1 or -1 do
                    local o = objs:get(i)
                    local spr = o:getSprite()
                    local dx, dy = P.acrossWall(spr and spr:getName())
                    if dx and inside[(x + dx) .. "," .. (y + dy) .. "," .. z] then found = o end
                end
            end
        end
    end)
    return found
end

function HS.handle(def)
    local key = X.Buildings.key(def)
    if done[key] then return end
    -- built by players (enclosure, room editor): no board of the map there
    if def:isUserDefined() then done[key] = true; return end
    if size(def) > HS.MAX_SQUARES then done[key] = true; return end
    if not loaded(def) then return end
    done[key] = true
    local existing, marked
    eachSquare(def, function(sq)
        -- hasModData first: getModData would create an empty table on every square of the building
        if sq:hasModData() and sq:getModData()[HS.SQUARE_MARK] then marked = true end
        local o = P.onSquare(sq)
        if o and not existing then existing = o end
    end)
    if marked then return end
    existing = existing or facadeBox(def)
    if existing then
        existing:getModData()[HS.HOUSE_KEY] = key
        existing:transmitModData()
        existing:getSquare():getModData()[HS.SQUARE_MARK] = 1
        X.log("house board: vanilla box of " .. key .. " reused")
        return
    end
    -- a house with an electrical box of the map always has its board; the draw only decides
    -- where an Extended board is added
    if not H.drawn(key) then return end
    local sq = wallSquare(def)
    if not sq then return end
    local name = X.Terminal.SHEET .. "_" .. sheetIndex(H.modules(H.plan(HS.collect(def))))
    local o = IsoObject.new(getCell(), sq, getSprite(name))
    o:getModData()[HS.HOUSE_KEY] = key
    sq:getModData()[HS.SQUARE_MARK] = 1
    sq:transmitAddObjectToSquare(o, -1)
    X.log("house board placed in " .. key .. " at " .. sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ())
end

-- Buildings touched by a loaded chunk (ground floor squares with a room).
function HS.onLoadChunk(chunk)
    local seen = {}
    for i = 0, 63 do
        local sq = chunk:getGridSquare(i % 8, math.floor(i / 8), 0)
        if sq and sq:getRoom() then
            local def = getWorld():getMetaGrid():getBuildingAt(sq:getX(), sq:getY(), 0)
            if def and not seen[def] then
                seen[def] = true
                HS.handle(def)
            end
        end
    end
end

Events.LoadChunk.Add(HS.onLoadChunk)
