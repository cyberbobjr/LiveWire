-- Live Wire: the management software, drawn as a computer application inside a
-- rectangle of any host UI element: our own computer screen (LW_SoftwareScreen.lua)
-- or the screen of the Computer Mod / Laptop Mod (LW_ComputerMod.lua). Same
-- application everywhere. The host calls app:draw(ui, x, y, w, h) from its render
-- and app:onMouseDown(mx, my) with coordinates local to the same UI element.
-- Data: the inverter snapshot (LW_ClientState.lua); commands are re-checked by the
-- server.
if isServer() then return end
require "LiveWire/LW_NetworkName"

LiveWire = LiveWire or {}

local App = {}
App.__index = App
LiveWire.SoftwareApp = App

local RESUBSCRIBE_MS = 60 * 1000

-- Palette of the application (dark desktop software).
local C = {
    bg = { 0.09, 0.11, 0.13 }, panel = { 0.14, 0.17, 0.20 }, panel2 = { 0.18, 0.21, 0.25 },
    line = { 0.28, 0.33, 0.38 }, text = { 0.88, 0.91, 0.93 }, dim = { 0.58, 0.63, 0.68 },
    accent = { 0.30, 0.78, 0.95 }, green = { 0.32, 0.85, 0.42 }, blue = { 0.35, 0.60, 0.95 },
    amber = { 0.98, 0.72, 0.20 }, red = { 0.95, 0.32, 0.25 }, bar = { 0.06, 0.07, 0.08 },
}

local TABS = {
    { id = "consumers", key = "IGUI_LW_App_Tab_Consumers" },
    { id = "forecast", key = "IGUI_LW_App_Tab_Forecast" },
    { id = "events", key = "IGUI_LW_App_Tab_Events" },
    { id = "overview", key = "IGUI_LW_App_Tab_Overview" },
    { id = "batteries", key = "IGUI_LW_App_Tab_Batteries" },
    { id = "sources", key = "IGUI_LW_App_Tab_Sources" },
    { id = "house", key = "IGUI_LW_App_Tab_House" },
    { id = "history", key = "IGUI_LW_App_Tab_History" },
    { id = "equipment", key = "IGUI_LW_App_Tab_Equipment" },
}

local function T(key, ...) return getText(key, ...) end
local function fh(font) return getTextManager():getFontHeight(font) end
local function tw(font, s) return getTextManager():MeasureStringX(font, s) end

-- options: header = false when the host already shows the title (Computer Mod).
function App.new(player, inverterId, options)
    local o = setmetatable({}, App)
    o.header = not (options and options.header == false)
    o.player = player
    o.inverterId = inverterId
    o.tab = "overview"
    o.buttons = {}
    o.lastSubscribe = 0
    return o
end

-- Position of the computer the software runs on (self.computer, set by the host), sent
-- with the commands so that the server accepts them from the linked computer (C02).
function App:via()
    local c = self.computer
    local sq = c and c.getSquare and c:getSquare()
    if not sq then return nil end
    return { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
end

function App:snapshot()
    return self.inverterId and LiveWire.Client.snapshot(self.inverterId) or nil
end

-- Called by the host every frame: keep the server sending snapshots.
function App:update()
    if not isClient() or not self.inverterId then return end
    local now = getTimestampMs()
    if now - self.lastSubscribe >= RESUBSCRIBE_MS then
        self.lastSubscribe = now
        LiveWire.Client.send(LiveWire.Protocol.C_SUBSCRIBE, { inverter = self.inverterId, via = self:via() })
    end
end

function App:close()
    self.detailSnapshot, self.detailRows, self.detailTab = nil, nil, nil
    if isClient() and self.inverterId then
        LiveWire.Client.send(LiveWire.Protocol.C_UNSUBSCRIBE, { inverter = self.inverterId })
    end
end

-------------------------------------------------------------------------------
-- Drawing helpers (ui = the host ISUIElement)
-------------------------------------------------------------------------------
local function rect(ui, x, y, w, h, c, a)
    ui:drawRect(x, y, w, h, a or 1, c[1], c[2], c[3])
end

local function border(ui, x, y, w, h, c, a)
    ui:drawRectBorder(x, y, w, h, a or 1, c[1], c[2], c[3])
end

-- Cut `s` with "..." so that it fits in maxW pixels (no stencil: it would clear
-- the clipping of the host screen).
local function fit(s, font, maxW)
    if not maxW or tw(font, s) <= maxW then return s end
    local dots = "..."
    local n = #s
    -- Kahlua strings are UTF-16 code units: cutting never splits an accented letter.
    while n > 0 and tw(font, string.sub(s, 1, n) .. dots) > maxW do n = n - 1 end
    return string.sub(s, 1, n) .. dots
end
App.fit = fit

local function text(ui, s, x, y, c, font, maxW)
    font = font or UIFont.Small
    ui:drawText(fit(s, font, maxW), x, y, c[1], c[2], c[3], 1, font)
end

local function textRight(ui, s, x, y, c, font, maxW)
    font = font or UIFont.Small
    ui:drawTextRight(fit(s, font, maxW), x, y, c[1], c[2], c[3], 1, font)
end

function App:button(ui, x, y, w, h, label, action, style)
    local mx, my = ui:getMouseX(), ui:getMouseY()
    local over = mx >= x and mx < x + w and my >= y and my < y + h
    local bg = C.panel2
    if style == "on" then bg = { 0.15, 0.40, 0.20 } elseif style == "off" then bg = { 0.42, 0.14, 0.12 }
    elseif style == "active" then bg = { 0.12, 0.32, 0.42 } end
    rect(ui, x, y, w, h, bg, over and 1 or 0.9)
    border(ui, x, y, w, h, over and C.accent or C.line)
    local font = UIFont.Small
    label = fit(label, font, w - 6)
    text(ui, label, x + (w - tw(font, label)) / 2, y + (h - fh(font)) / 2, C.text, font)
    self.buttons[#self.buttons + 1] = { x = x, y = y, w = w, h = h, action = action }
end

local function bar(ui, x, y, w, h, frac, c)
    rect(ui, x, y, w, h, C.bar)
    local f = LiveWire.clamp(frac or 0, 0, 1)
    if f > 0 then rect(ui, x + 1, y + 1, (w - 2) * f, h - 2, c) end
    border(ui, x, y, w, h, C.line)
end

local function card(ui, x, y, w, h, title)
    rect(ui, x, y, w, h, C.panel)
    border(ui, x, y, w, h, C.line)
    if title then
        text(ui, title, x + 8, y + 4, C.dim, UIFont.Small, w - 16)
        return y + 4 + fh(UIFont.Small) + 3
    end
    return y + 6
end

local function led(ui, x, y, c)
    rect(ui, x, y, 10, 10, c)
    border(ui, x, y, 10, 10, { 0.02, 0.02, 0.02 })
end

local function stateColour(st)
    if st == "on" or st == "ok" then return C.green end
    if st == "tripped" or st == "broken" or st == "ringing" then return C.red end
    return C.amber
end

-------------------------------------------------------------------------------
-- Pages
-------------------------------------------------------------------------------
function App:drawOverview(ui, x, y, w, h, snap)
    local inv = snap.inverter
    local nominal = 0
    for i = 1, #snap.sources do nominal = nominal + (snap.sources[i].nominal or 0) end
    local scale = math.max(inv.maxW or 0, nominal, snap.production or 0, snap.demand or 0, 1)
    local small = UIFont.Small
    local sh = fh(small)
    local gap = 6
    local leftW = math.floor((w - gap) * 0.6)
    local rightW = w - leftW - gap
    -- Large figures when there is room, medium ones on a small screen.
    local big = UIFont.Large
    local barH = 12
    local function powerH(f) return sh + 7 + 2 * (fh(f) + 2 + barH + 6) + sh + 6 end
    local function storeH(f) return sh + 7 + fh(f) + 2 + barH + 6 + sh + 6 end
    if powerH(big) + storeH(big) + gap > h then big = UIFont.Medium end
    local compact = powerH(big) + storeH(big) + gap > h
    if compact then barH = 8 end
    local bh2 = fh(big)

    -- Production / consumption on the same scale.
    local ch = powerH(big)
    if compact then ch = ch - sh end
    local cy = card(ui, x, y, leftW, ch, T("IGUI_LW_App_Power"))
    local valueW = tw(big, "0000 W") + 4
    local labelW = leftW - 20 - valueW
    text(ui, T("IGUI_LW_App_Production"), x + 10, cy + (bh2 - sh) / 2, C.dim, small, labelW)
    textRight(ui, tostring(snap.production) .. " W", x + leftW - 10, cy, C.green, big)
    cy = cy + bh2 + 2
    bar(ui, x + 10, cy, leftW - 20, barH, snap.production / scale, C.green)
    cy = cy + barH + 6
    local loadC = C.blue
    local f = (inv.maxW or 0) > 0 and snap.demand / inv.maxW or 0
    if f > 0.9 then loadC = C.red elseif f > 0.7 then loadC = C.amber end
    text(ui, T("IGUI_LW_App_Load"), x + 10, cy + (bh2 - sh) / 2, C.dim, small, labelW)
    textRight(ui, tostring(snap.demand) .. " W", x + leftW - 10, cy, loadC, big)
    cy = cy + bh2 + 2
    bar(ui, x + 10, cy, leftW - 20, barH, snap.demand / scale, loadC)
    cy = cy + barH + 6
    if not compact then text(ui, T("IGUI_LW_App_Scale", scale, inv.maxW), x + 10, cy, C.dim, small, leftW - 20) end

    -- Batteries: what is left of the height.
    local by = y + ch + gap
    local bh = y + h - by
    local cy2 = card(ui, x, by, leftW, bh, T("IGUI_LW_App_Storage"))
    if snap.capacity and snap.capacity > 0 then
        local frac = snap.stock / snap.capacity
        local c = frac < 0.2 and C.red or (frac < 0.5 and C.amber or C.green)
        local pct = tostring(math.floor(frac * 100 + 0.5)) .. " %"
        textRight(ui, pct, x + leftW - 10, cy2, c, big)
        text(ui, string.format("%.2f / %.2f kWh", snap.stock, snap.capacity), x + 10, cy2 + (bh2 - sh) / 2,
            C.text, small, leftW - 30 - tw(big, pct))
        cy2 = cy2 + bh2 + 2
        bar(ui, x + 10, cy2, leftW - 20, barH, frac, c)
        cy2 = cy2 + barH + 5
        if cy2 + sh <= by + bh - 3 then
            local line
            if snap.autonomyH then
                line = T("IGUI_LW_Autonomy", math.floor(snap.autonomyH + 0.5))
            else
                line = T("IGUI_LW_Forecast_Surplus")
            end
            text(ui, line, x + 10, cy2, C.dim, small, leftW - 20)
        end
    else
        text(ui, T("IGUI_LW_NoBattery"), x + 10, cy2, C.dim, small, leftW - 20)
    end

    -- Inverter control.
    local rx = x + leftW + gap
    local ry = card(ui, rx, y, rightW, h, T("IGUI_LW_App_Inverter"))
    local inner = rightW - 20
    local st = inv.state
    led(ui, rx + 10, ry + (sh - 10) / 2, stateColour(st))
    local stKey = "IGUI_LW_State_" .. tostring(st)
    if st == "on" and not inv.powered then stKey = "IGUI_LW_State_idle" end
    text(ui, T(stKey), rx + 26, ry, C.text, small, inner - 16)
    ry = ry + sh + 4
    text(ui, T("IGUI_LW_App_Condition", inv.cond), rx + 10, ry, C.dim, small, inner)
    ry = ry + sh + 2
    bar(ui, rx + 10, ry, inner, 8, (inv.cond or 0) / 100, inv.cond < 30 and C.red or C.green)
    ry = ry + 14
    -- Coupled inverters: one line, when the card keeps room for it and its button.
    if snap.coupled and ry + sh + 4 + sh + 10 <= y + h then
        text(ui, T("IGUI_LW_App_Coupled", snap.coupled.n, snap.coupled.total), rx + 10, ry, C.dim, small, inner)
        ry = ry + sh + 4
    end
    local btnH = sh + 10
    if st == "on" then
        self:button(ui, rx + 10, ry, inner, btnH, T("ContextMenu_LW_TurnOff"), "off", "off")
    else
        self:button(ui, rx + 10, ry, inner, btnH, T("ContextMenu_LW_TurnOn"), "on", "on")
    end
    ry = ry + btnH + 5
    if st == "tripped" then
        self:button(ui, rx + 10, ry, inner, btnH, T("ContextMenu_LW_Reset"), "reset")
        ry = ry + btnH + 5
    end
    -- Alerts, as many as fit.
    rect(ui, rx + 10, ry, inner, 1, C.line)
    ry = ry + 5
    local bottom = y + h - 4
    local alerts = 0
    local function alert(s, c)
        if ry + sh > bottom then return end
        text(ui, s, rx + 10, ry, c, small, inner)
        ry = ry + sh + 2
        alerts = alerts + 1
    end
    if snap.breaker and snap.breaker.state == "tripped" then alert(T("IGUI_LW_App_BreakerTripped"), C.red) end
    if snap.alarm and snap.alarm.on then alert(T("IGUI_LW_Alarm_On"), C.red) end
    if f > 0.9 then alert(T("IGUI_LW_Alert_Overload"), C.amber) end
    if (snap.extra or 0) > 0 then alert(T("IGUI_LW_TooManyBatteries", snap.extra), C.amber) end
    if alerts == 0 then alert(T("IGUI_LW_App_NoAlert"), C.green) end
end

function App:drawBatteries(ui, x, y, w, h, snap)
    local cy = card(ui, x, y, w, h, T("IGUI_LW_Section_Batteries", snap.banks or 0))
    if not snap.batteries or #snap.batteries == 0 then
        text(ui, T("IGUI_LW_NoBattery"), x + 10, cy, C.dim)
        return
    end
    for i = 1, #snap.batteries do
        local bt = snap.batteries[i]
        local item = getScriptManager():FindItem(bt.model)
        local name = item and item:getDisplayName() or bt.model
        local right = T("IGUI_LW_App_BatteryState", math.floor(bt.charge * 100 + 0.5), bt.cond)
        textRight(ui, right, x + w - 10, cy, C.dim)
        text(ui, name, x + 10, cy, C.text, UIFont.Small, w - 30 - tw(UIFont.Small, right))
        cy = cy + fh(UIFont.Small) + 2
        bar(ui, x + 10, cy, w - 20, 10, bt.charge, bt.cond < 30 and C.amber or C.green)
        cy = cy + 16
        if cy > y + h - 20 then break end
    end
    if snap.lost and snap.lost > 0.0005 then
        text(ui, T("IGUI_LW_Lost", string.format("%.2f", snap.lost)), x + 10, y + h - fh(UIFont.Small) - 6, C.amber)
    end
end

function App:drawSources(ui, x, y, w, h, snap)
    local cy = card(ui, x, y, w, h, T("IGUI_LW_Sources"))
    local fams = { { "solar", "IGUI_LW_Family_Solar" }, { "wind", "IGUI_LW_Family_Wind" },
                   { "hydro", "IGUI_LW_Family_Hydro" } }
    for _, fam in ipairs(fams) do
        local n, wsum = 0, 0
        for i = 1, #snap.sources do
            if snap.sources[i].kind == fam[1] then n = n + 1; wsum = wsum + snap.sources[i].w end
        end
        text(ui, T(fam[2]), x + 10, cy, C.accent)
        textRight(ui, T("IGUI_LW_App_FamilyTotal", n, wsum), x + w - 10, cy, C.text)
        cy = cy + fh(UIFont.Small) + 2
        for i = 1, #snap.sources do
            local s = snap.sources[i]
            if s.kind == fam[1] and cy < y + h - 16 then
                local line = T("IGUI_LW_Model_" .. s.model)
                if s.kind == "solar" and (s.snow or 0) > 0.05 then
                    line = line .. " " .. T("IGUI_LW_Snow", math.floor(s.snow * 100 + 0.5))
                end
                local barW = math.min(100, math.floor(w * 0.22))
                local right = T("IGUI_LW_App_SourceState", s.w, s.cond)
                local rightW = tw(UIFont.Small, right)
                text(ui, line, x + 22, cy, s.cond <= 0 and C.red or C.text, UIFont.Small, w - 50 - barW - rightW)
                local nom = math.max(1, s.nominal or 1)
                bar(ui, x + w - 20 - rightW - barW, cy + 3, barW, 8, s.w / nom, C.green)
                textRight(ui, T("IGUI_LW_App_SourceState", s.w, s.cond), x + w - 10, cy, C.dim)
                cy = cy + fh(UIFont.Small) + 2
            end
        end
        cy = cy + 4
    end
end

function App:drawHouse(ui, x, y, w, h, snap)
    local cy = card(ui, x, y, w, h, T("IGUI_LW_Section_House"))
    text(ui, T("IGUI_LW_LCD_Range", snap.coverage and snap.coverage.radius or 20,
        snap.coverage and snap.coverage.floors or 3), x + 10, cy, C.dim, UIFont.Small, w - 20)
    cy = cy + fh(UIFont.Small) + 6
    local ap = snap.appliances or {}
    if #ap == 0 then text(ui, T("IGUI_LW_NoAppliance"), x + 10, cy, C.dim) end
    local maxW = 1
    for i = 1, #ap do maxW = math.max(maxW, ap[i].w) end
    for i = 1, #ap do
        if cy > y + h - 18 then break end
        local barW = math.min(110, math.floor(w * 0.22))
        local right = T("IGUI_LW_App_ApplianceState", ap[i].n, ap[i].w)
        local rightW = tw(UIFont.Small, right)
        text(ui, T("IGUI_LW_Appliance_" .. ap[i].cat), x + 10, cy, C.text, UIFont.Small, w - 40 - barW - rightW)
        bar(ui, x + w - 20 - rightW - barW, cy + 3, barW, 8, ap[i].w / maxW, C.blue)
        textRight(ui, T("IGUI_LW_App_ApplianceState", ap[i].n, ap[i].w), x + w - 10, cy, C.dim)
        cy = cy + fh(UIFont.Small) + 3
    end
end

function App:details(snap)
    if self.detailSnapshot == snap and self.detailTab == self.tab then return self.detailRows end
    local rows = {}
    if self.tab == "consumers" then
        for _, r in ipairs(snap.consumers or {}) do
            rows[#rows + 1] = T("IGUI_LW_ConsumerLine", T("IGUI_LW_Appliance_" .. r.cat), r.w, r.x, r.y, r.z)
        end
    elseif self.tab == "events" then
        for i = #(snap.events or {}), 1, -1 do
            local e = snap.events[i]
            local tod = e.tod or e.t % 24
            local minute = math.floor((tod * 60) % 60)
            rows[#rows + 1] = T("IGUI_LW_EventTime", math.floor(e.t / 24), math.floor(tod),
                string.format("%02d", minute), LiveWire.Client.text(e.key, e.args))
        end
    else
        rows[#rows + 1] = T("IGUI_LW_ForecastEstimate")
        if not snap.forecast then rows[#rows + 1] = T("IGUI_LW_Computer_NoHistory") end
        for _, r in ipairs(snap.forecast or {}) do
            rows[#rows + 1] = T("IGUI_LW_ForecastDay", r.offset,
                string.format("%.2f", r.total), string.format("%.2f", r.demand))
            rows[#rows + 1] = T("IGUI_LW_ForecastFamilies", string.format("%.2f", r.solar),
                string.format("%.2f", r.wind), string.format("%.2f", r.hydro))
            rows[#rows + 1] = T(r.sufficient and "IGUI_LW_ForecastEnough" or "IGUI_LW_ForecastBackup")
        end
    end
    self.detailSnapshot, self.detailTab, self.detailRows = snap, self.tab, rows
    return rows
end

function App:drawDetails(ui, x, y, w, h, snap)
    local cy = card(ui, x, y, w, h, T("IGUI_LW_App_Tab_" .. (self.tab == "events" and "Events"
        or self.tab == "forecast" and "Forecast" or "Consumers")))
    local rows = self:details(snap)
    local pageSize = math.max(1, math.floor((h - (cy - y) - 38) / (fh(UIFont.Small) + 4)))
    local page = math.min(self.detailPage or 0, math.max(0, math.ceil(#rows / pageSize) - 1))
    self.detailPage = page
    for i = page * pageSize + 1, math.min(#rows, (page + 1) * pageSize) do
        text(ui, rows[i], x + 10, cy, C.text, UIFont.Small, w - 20)
        cy = cy + fh(UIFont.Small) + 4
    end
    self:button(ui, x + 10, y + h - 30, 40, 24, "<", "detailPrev")
    self:button(ui, x + 58, y + h - 30, 40, 24, ">", "detailNext")
end

local function graph(ui, x, y, w, h, values, max, c, label)
    rect(ui, x, y, w, h, C.bar)
    border(ui, x, y, w, h, C.line)
    text(ui, label, x + 4, y + 2, C.dim)
    local n = #values
    if n == 0 then return end
    local slot = w / math.max(n, 24)
    for k = 1, n do
        local f = LiveWire.clamp((values[k] or 0) / math.max(max, 0.0001), 0, 1)
        local hh = math.floor(f * (h - 4) + 0.5)
        if hh > 0 then rect(ui, x + (k - 1) * slot + 1, y + h - 2 - hh, math.max(1, slot - 1), hh, c) end
    end
end

function App:drawHistory(ui, x, y, w, h, snap)
    local cy = card(ui, x, y, w, h, T("IGUI_LW_App_Tab_History"))
    local hist = snap.history
    if not snap.computer then
        text(ui, T("IGUI_LW_Computer_None"), x + 10, cy, C.dim, UIFont.Small, w - 20)
        return
    end
    if not hist or #hist == 0 then
        text(ui, T("IGUI_LW_Computer_NoHistory"), x + 10, cy, C.dim)
        return
    end
    local prod, dem, stock = {}, {}, {}
    local peak = 1
    for i = 1, #hist do
        prod[i], dem[i] = hist[i].p or 0, hist[i].d or 0
        stock[i] = math.max(0, hist[i].s or 0)
        peak = math.max(peak, prod[i], dem[i])
    end
    local gh = math.floor((h - (cy - y) - 40) / 3)
    graph(ui, x + 10, cy, w - 20, gh, prod, peak, C.green, T("IGUI_LW_History_Production", #hist, peak))
    graph(ui, x + 10, cy + gh + 6, w - 20, gh, dem, peak, C.blue, T("IGUI_LW_History_Demand"))
    graph(ui, x + 10, cy + 2 * (gh + 6), w - 20, gh, stock, 1, C.amber, T("IGUI_LW_History_Stock"))
    local fy = cy + 3 * (gh + 6)
    if snap.dawnH and snap.capacity and snap.capacity > 0 then
        local dawn = math.floor(snap.dawnH + 0.5)
        if not snap.autonomyH then
            text(ui, T("IGUI_LW_Forecast_Surplus"), x + 10, fy, C.green)
        elseif snap.autonomyH >= snap.dawnH then
            text(ui, T("IGUI_LW_Forecast_Holds", dawn), x + 10, fy, C.green)
        else
            text(ui, T("IGUI_LW_Forecast_Short", math.floor(snap.autonomyH + 0.5), dawn), x + 10, fy, C.amber)
        end
    end
end

function App:drawEquipment(ui, x, y, w, h, snap)
    local cy = card(ui, x, y, w, h, T("IGUI_LW_Options"))
    local nameH = fh(UIFont.Small) + 10
    self:button(ui, x + 10, cy, w - 20, nameH, T("ContextMenu_LW_RenameNetwork"), "rename")
    cy = cy + nameH + 8
    local function row(name, stateText, c)
        led(ui, x + 10, cy + 3, c)
        text(ui, name, x + 26, cy, C.text)
        textRight(ui, stateText, x + w - 10, cy, C.dim)
        cy = cy + fh(UIFont.Small) + 4
    end
    if snap.breaker then
        row(T("IGUI_LW_Model_Breaker"), T("IGUI_LW_State_" .. tostring(snap.breaker.state)), stateColour(snap.breaker.state))
    end
    if snap.alarm then
        row(T("IGUI_LW_Model_BatteryAlarm"), T(snap.alarm.on and "IGUI_LW_Alarm_On" or "IGUI_LW_Alarm_Armed"),
            snap.alarm.on and C.red or C.green)
    end
    local bk = snap.backup
    if bk then
        local bad = bk.state == "nofuel" or bk.state == "unplugged" or bk.state == "broken"
        row(T("IGUI_LW_Model_BackupGenerator"), T("IGUI_LW_Backup_" .. tostring(bk.state)) .. ", " .. bk.w .. " W",
            bad and C.red or (bk.state == "running" and C.green or C.amber))
        local fuel = (bk.maxFuel or 0) > 0 and bk.fuel / bk.maxFuel or 0
        text(ui, T("IGUI_LW_Backup_Fuel", math.floor(fuel * 100 + 0.5)), x + 26, cy, C.dim)
        cy = cy + fh(UIFont.Small) + 2
        bar(ui, x + 26, cy, w - 36, 8, fuel, C.amber)
        cy = cy + 14
        text(ui, T("IGUI_LW_Backup_Thresholds", bk.start, bk.stop), x + 26, cy, C.dim)
        cy = cy + fh(UIFont.Small) + 4
    end
    if snap.computer then
        row(T("IGUI_LW_Model_ManagementComputer"), snap.computer.powered and T("IGUI_LW_State_on") or T("IGUI_LW_State_off"),
            snap.computer.powered and C.green or C.amber)
    end
    if snap.pumps then
        text(ui, T("IGUI_LW_App_Pumps", tostring(snap.pumps.n), tostring(snap.pumps.flow)), x + 10, cy, C.text)
        cy = cy + fh(UIFont.Small) + 4
    end
    if not snap.breaker and not snap.alarm and not bk and not snap.computer and not snap.pumps then
        text(ui, T("IGUI_LW_None"), x + 10, cy, C.dim)
    end
end

-------------------------------------------------------------------------------
-- Application frame (inside the host rectangle)
-------------------------------------------------------------------------------
function App:draw(ui, x, y, w, h)
    self.buttons = {}
    rect(ui, x, y, w, h, C.bg)
    local snap = self:snapshot()
    local ty = y + 6
    if self.header then
        -- Header: product name and network.
        local hh = fh(UIFont.Medium) + 10
        rect(ui, x, y, w, hh, { 0.06, 0.20, 0.26 })
        text(ui, T("IGUI_LW_App_Name"), x + 10, y + 5, C.text, UIFont.Medium)
        if snap and snap.name and snap.name ~= "" then
            textRight(ui, snap.name, x + w - 10, y + 7, C.dim)
        end
        ty = y + hh + 6
    end
    -- Tabs: natural width, or shared equally when the screen is narrow.
    local tabH = fh(UIFont.Small) + 8
    local avail = w - 16
    local function totalWidth(short)
        local t = 0
        for _, tab in ipairs(TABS) do t = t + tw(UIFont.Small, T(tab.key .. (short and "_Short" or ""))) + 14 + 4 end
        return t
    end
    local short = totalWidth(false) > avail
    local shared = short and totalWidth(true) > avail
    local tx = x + 8
    for _, tab in ipairs(TABS) do
        local label = T(tab.key .. (short and "_Short" or ""))
        local bw = tw(UIFont.Small, label) + 14
        if shared then bw = math.floor(avail / #TABS) - 4 end
        self:button(ui, tx, ty, bw, tabH, label, "tab:" .. tab.id, self.tab == tab.id and "active" or nil)
        tx = tx + bw + 4
    end
    local cy = ty + tabH + 8
    local ch = y + h - cy - 8
    if not self.inverterId then
        text(ui, T("IGUI_LW_NoInverterForSoftware"), x + 12, cy, C.dim)
        return
    end
    if not snap then
        text(ui, T("IGUI_LW_Waiting"), x + 12, cy, C.dim)
        return
    end
    local cx, cw = x + 8, w - 16
    if self.tab == "events" or self.tab == "forecast" or self.tab == "consumers" then self:drawDetails(ui, cx, cy, cw, ch, snap)
    elseif self.tab == "overview" then self:drawOverview(ui, cx, cy, cw, ch, snap)
    elseif self.tab == "batteries" then self:drawBatteries(ui, cx, cy, cw, ch, snap)
    elseif self.tab == "sources" then self:drawSources(ui, cx, cy, cw, ch, snap)
    elseif self.tab == "house" then self:drawHouse(ui, cx, cy, cw, ch, snap)
    elseif self.tab == "history" then self:drawHistory(ui, cx, cy, cw, ch, snap)
    else self:drawEquipment(ui, cx, cy, cw, ch, snap) end
end

-- Returns true when the click hit one of the application's buttons.
function App:onMouseDown(mx, my)
    for i = #self.buttons, 1, -1 do
        local b = self.buttons[i]
        if mx >= b.x and mx < b.x + b.w and my >= b.y and my < b.y + b.h then
            self:act(b.action)
            return true
        end
    end
    return false
end

function App:act(action)
    local P = LiveWire.Protocol
    if string.sub(action, 1, 4) == "tab:" then
        self.tab = string.sub(action, 5)
        self.detailPage = 0
    elseif action == "detailPrev" then self.detailPage = math.max(0, (self.detailPage or 0) - 1)
    elseif action == "detailNext" then self.detailPage = (self.detailPage or 0) + 1
    elseif action == "on" or action == "off" then
        LiveWire.Client.send(P.C_SET_INVERTER, { inverter = self.inverterId, on = action == "on", via = self:via() })
        self.lastSubscribe = 0
    elseif action == "reset" then
        LiveWire.Client.send(P.C_RESET, { inverter = self.inverterId, via = self:via() })
        self.lastSubscribe = 0
    elseif action == "rename" then
        local snap = self:snapshot()
        LiveWire.NetworkName.open(getPlayer(), self.inverterId, snap and snap.name or "", self:via())
    end
    getSoundManager():playUISound("UIActivateButton")
end
