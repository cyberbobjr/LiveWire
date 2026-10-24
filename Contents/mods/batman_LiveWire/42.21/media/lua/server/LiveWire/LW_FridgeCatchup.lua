-- Live Wire: fridge and freezer food of a chunk that was unloaded while an inverter
-- anchor covering it changed state (authority only). Food.updateAge ages the whole
-- time since lastAged with the power of the moment (Food.java:668-706), so a bank
-- that ran empty (or came back) during the absence would count the whole absence
-- warm (or cold). Called first by LW_ChunkSync.onLoadChunk: the absence is
-- replayed segment by segment from the private power history (LW_PowerHistory),
-- with the vanilla rules (Food.updateFreezing then Food.updateAge).
if isClient() then return end

LiveWire = LiveWire or {}

local FC = {}
LiveWire.FridgeCatchup = FC

local CHUNK = 8
local FRIDGE = { 0.4, 0.3, 0.2, 0.1, 0.03, 0.0 }  -- Food.getFridgeFactor (Food.java:642-651)
local ROT = { 1.7, 1.4, 1.0, 0.7, 0.4 }           -- Food.getFoodRotSpeed (Food.java:653-661)
FC.FREEZE_PER_HOUR = 100 / 4                      -- 4 h to freeze (Food.java:757-761)
FC.THAW_HOURS = 1.5                               -- 1.5 h to thaw, x2 in a powered fridge (:762-768)

local function option(name, default)
    local opts = getSandboxOptions()
    local o = opts and opts:getOptionByName(name)
    if o then return o:getValue() end
    return default
end

-- Power state of anchor `a` at world hour t.
local function onAt(a, t)
    local on = a.log0 == true
    local log = a.log
    local lo, hi = 1, #log
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if log[mid].t <= t then on = log[mid].on == true; lo = mid + 1
        else hi = mid - 1 end
    end
    return on
end

-- Power timeline of a square between t0 and t1: list of { d = hours, p = powered },
-- or nil when no covering anchor changed state in the interval (vanilla is right).
local function timeline(anchors, t0, t1, shutH)
    local cuts = { t0 }
    local changed = false
    for i = 1, #anchors do
        local log = anchors[i].log
        for j = 1, #log do
            local t = log[j].t
            if t > t0 and t < t1 then
                cuts[#cuts + 1] = t
                changed = true
            end
        end
    end
    if not changed then return nil end
    if shutH > t0 and shutH < t1 then cuts[#cuts + 1] = shutH end
    cuts[#cuts + 1] = t1
    table.sort(cuts)
    local out = {}
    for i = 1, #cuts - 1 do
        local a, b = cuts[i], cuts[i + 1]
        if b > a then
            local mid = (a + b) / 2
            local p = mid < shutH  -- public grid still on (Food.java:691-697)
            for k = 1, #anchors do
                if not p and onAt(anchors[k], mid) then p = true end
            end
            out[#out + 1] = { d = b - a, p = p }
        end
    end
    return out
end

-- New age, freezing time and frozen flag of one food item over the timeline.
local function replay(food, inFreezer, segs, ff, rot)
    local ft = food:getFreezingTime()
    local frozen = food:isFrozen()
    local canFreeze = food:canBeFrozen()
    local hours = 0
    for i = 1, #segs do
        local d, p = segs[i].d, segs[i].p
        local factor = 1
        if p then factor = ff end
        if canFreeze and inFreezer and p then
            -- Powered freezer: freezes in 4 h, no ageing once frozen.
            if not frozen then
                local h = math.min(d, (100 - ft) / FC.FREEZE_PER_HOUR)
                hours = hours + h * factor
            end
            ft = math.min(100, ft + d * FC.FREEZE_PER_HOUR)
            if ft >= 100 then frozen = true end
        elseif canFreeze and ft > 0 then
            -- Thawing: unpowered freezer, or a fridge (twice slower when powered).
            local thaw = FC.THAW_HOURS
            if p and not inFreezer then thaw = thaw * 2 end
            local rate = 100 / thaw
            local h = 0
            if frozen then h = math.min(d, ft / rate) end
            ft = math.max(0, ft - d * rate)
            if ft <= 0 then frozen = false end
            hours = hours + (d - h) * factor
        elseif not frozen then
            hours = hours + d * factor
        end
    end
    return food:getAge() + hours * rot / 24, ft, frozen
end

local function apply(food, now, age, ft, frozen)
    food:setLastAged(now)
    -- lastFrozenUpdate has no setter: let updateAge consume the freezing interval;
    -- it does not age the item since lastAged == now (Food.java:671-673).
    food:updateAge()
    food:setFreezingTime(ft)
    food:setFrozen(frozen)
    food:setAge(age)
end

local function foods(container, out)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if instanceof(it, "Food") then
            out[#out + 1] = it
        elseif instanceof(it, "InventoryContainer") then
            local inner = it:getInventory()
            if inner then foods(inner, out) end
        end
    end
    return out
end

-- Returns the number of food items aged.
function FC.onLoadChunk(chunk)
    local cx, cy = LiveWire.Anchor.chunkCoords(chunk)
    if not cx then return 0 end
    local R = LiveWire.Config.tileRange()
    local V = LiveWire.Config.verticalRange()
    local list = {}
    local registry = LiveWire.Registry
    local history = registry and registry.data and registry.data.powerHistory or LiveWire.Anchor.table()
    for _, a in pairs(history) do
        if type(a.log) == "table" and #a.log > 0 and LiveWire.Anchor.touches(cx, cy, a, R) then
            list[#list + 1] = a
        end
    end
    if #list == 0 then return 0 end
    local now = getGameTime():getWorldAgeHours()
    local ff = FRIDGE[option("FridgeFactor", 3)] or 0.2
    local rot = ROT[option("FoodRotSpeed", 3)] or 1.0
    local shutH = -1
    local opts = getSandboxOptions()
    local days = opts and opts:getElecShutModifier() or -1
    if days > -1 then shutH = days * 24 end
    local exteriorOk = option("AllowExteriorGenerator", true)
    local R2 = R * R
    local n = 0
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for i = 0, CHUNK * CHUNK - 1 do
            local sq = chunk:getGridSquare(i % CHUNK, math.floor(i / CHUNK), z)
            if sq and (exteriorOk or not sq:getProperties():has(IsoFlagType.exterior)) then
                local cover = nil
                for k = 1, #list do
                    local a = list[k]
                    local dx, dy = sq:getX() - a.x, sq:getY() - a.y
                    if dx * dx + dy * dy <= R2 and math.abs(z - a.z) <= V then
                        cover = cover or {}
                        cover[#cover + 1] = a
                    end
                end
                if cover then
                    local timelines = {} -- foods on this square often share lastAged
                    local objs = sq:getObjects()
                    for oi = 0, objs:size() - 1 do
                        local o = objs:get(oi)
                        for c = 0, o:getContainerCount() - 1 do
                            local cont = o:getContainerByIndex(c)
                            if cont and (cont:isFridge() or cont:isFreezer()) then
                                local inFreezer = cont:isFreezer()
                                local items = foods(cont, {})
                                for f = 1, #items do
                                    local food = items[f]
                                    local last = food:getLastAged()
                                    if last >= 0 and last < now then
                                        local segs = timelines[last]
                                        if segs == nil then
                                            segs = timeline(cover, last, now, shutH)
                                            timelines[last] = segs or false
                                        end
                                        if segs then
                                            local age, ft, frozen = replay(food, inFreezer, segs, ff, rot)
                                            apply(food, now, age, ft, frozen)
                                            n = n + 1
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if n > 0 then
        LiveWire.log("aged " .. tostring(n) .. " fridge food item(s) of a reloaded chunk along the inverter power log")
    end
    return n
end
