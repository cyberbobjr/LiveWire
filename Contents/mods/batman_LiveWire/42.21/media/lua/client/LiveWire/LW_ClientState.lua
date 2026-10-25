-- Live Wire: client state (snapshots received from the server) and translated
-- player messages.
if isServer() then return end

LiveWire = LiveWire or {}

local Client = LiveWire.Client or {}
LiveWire.Client = Client

Client.snapshots = {}   -- inverter id -> snapshot
local soloCache = {}
local soloRegistry = nil
local accessed = {}
Client.CACHE_LIMIT = 64
Client.CACHE_TTL_MS = 5 * 60 * 1000
Client.bankView = nil -- only the currently open bank, no world-sized battery cache
local bankSeq = 0
Client.deviceView = nil -- only one individual LCD; no cache of visited devices
local deviceSeq = 0

local function forget(id)
    Client.snapshots[id], soloCache[id], accessed[id] = nil, nil, nil
end
-- A reopened panel must obtain an authority snapshot, including current demand
-- readiness, even when its network revision has not changed while away.
function Client.discardSnapshot(id)
    if type(id) == "string" then forget(id) end
end
function Client.prune()
    local now, count = getTimestampMs(), 0
    local oldest, oldestAt
    for id, at in pairs(accessed) do
        if now < at or now - at >= Client.CACHE_TTL_MS then forget(id)
        else
            count = count + 1
            if not oldestAt or at < oldestAt then oldest, oldestAt = id, at end
        end
    end
    -- Insertion adds at most one entry. No growing list of previously visited grids.
    if count > Client.CACHE_LIMIT then forget(oldest) end
end
local function touch(id)
    accessed[id] = getTimestampMs()
end
function Client.clearSession()
    Client.bankView = nil
    Client.deviceView = nil
    Client.snapshots, soloCache, accessed, soloRegistry = {}, {}, {}, nil
    for _, name in ipairs({ "BreakerPanel", "InverterPanel", "BankPanel", "ConnectionPanel", "DevicePanel" }) do
        local panel = LiveWire[name]
        if panel and panel.instance then panel.instance:close(true) end
    end
    if LiveWire.NetworkView then LiveWire.NetworkView.hide() end
end

-- Presentation only: device health is separate from stored battery health/charge.
function Client.equipmentCondition(cond)
    local value = type(cond) == "number" and cond == cond
        and tostring(math.floor(LiveWire.clamp(cond, 0, 100) + 0.5)) or "--"
    return getText("IGUI_LW_EquipmentCondition", value)
end

function Client.readDevice(id)
    if not isClient() then
        local dev = LiveWire.Registry and LiveWire.Registry.device(id)
        return dev and LiveWire.DeviceView.snapshot(dev)
    end
    deviceSeq = deviceSeq % 1000000000 + 1
    if not Client.deviceView or Client.deviceView.device ~= id then
        Client.deviceView = { device = id, seq = deviceSeq - 1 }
    end
    Client.send(LiveWire.Protocol.C_READ_DEVICE, { device = id, seq = deviceSeq })
end

function Client.readBank(id)
    if not isClient() then
        local bank = LiveWire.Registry and LiveWire.Registry.device(id)
        return bank and LiveWire.Batteries.snapshot(bank)
    end
    bankSeq = bankSeq % 1000000000 + 1
    if not Client.bankView or Client.bankView.device ~= id then
        Client.bankView = { device = id, seq = 0 }
    end
    Client.send(LiveWire.Protocol.C_READ_BANK, { device = id, seq = bankSeq })
end

-- Arguments that are translation keys are translated here, on the client.
local function translateArg(a)
    if type(a) == "string" and (string.find(a, "^IGUI_") or string.find(a, "^Tooltip_")) then
        return getText(a)
    end
    return tostring(a)
end

function Client.text(key, args)
    local t = {}
    for i = 1, #(args or {}) do t[i] = translateArg(args[i]) end
    return getText(key, t[1], t[2], t[3], t[4], t[5])
end

function Client.showNotify(player, key, args, bad)
    if not player or not key then return end
    local text = Client.text(key, args)
    if bad then
        HaloTextHelper.addBadText(player, text)
    else
        HaloTextHelper.addText(player, text)
    end
end

-- Snapshot for an inverter: single player reads the authority directly.
function Client.snapshot(inverterId)
    if type(inverterId) ~= "string" then return nil end
    if not isClient() and LiveWire.Registry and LiveWire.Registry.ready then
        local inv = LiveWire.Registry.device(inverterId)
        local grid = inv and inv.grid and LiveWire.Registry.grid(inv.grid)
        if soloRegistry ~= LiveWire.Registry.data then
            soloRegistry, soloCache, accessed = LiveWire.Registry.data, {}, {}
            Client.snapshots = {}
        end
        if not grid then forget(inverterId); return nil end
        local cur = soloCache[inverterId]
        if not cur or cur.grid ~= grid or cur.rev ~= grid.rev then
            cur = { grid = grid, rev = grid.rev, snapshot = LiveWire.Sim.snapshot(grid) }
            soloCache[inverterId] = cur
            touch(inverterId)
            Client.prune()
        end
        touch(inverterId)
        return cur.snapshot
    end
    if Client.snapshots[inverterId] then touch(inverterId) end
    return Client.snapshots[inverterId]
end

-- Font of the LCD screens (inverter panel, computer boot). UIFont.Code
-- (zomboidCode.fnt) has no CJK or Thai glyphs in any language, so these languages use
-- UIFont.Small, which has a font per language (vanilla list: ISLcdBar.unsupported).
local NO_CODE_FONT = { CH = true, CN = true, JP = true, KO = true, TH = true }
local lcdFontCache = nil

function Client.lcdFont()
    if not lcdFontCache then
        local lang = Translator and Translator.getLanguage and Translator.getLanguage()
        local name = lang and tostring(lang:name()) or ""
        if NO_CODE_FONT[name] or not UIFont.Code then
            lcdFontCache = UIFont.Small
        else
            lcdFontCache = UIFont.Code
        end
    end
    return lcdFontCache
end

function Client.send(command, args)
    local player = getPlayer()
    if player then sendClientCommand(player, LiveWire.MODULE, command, args or {}) end
end

local function onServerCommand(module, command, args)
    if module ~= LiveWire.MODULE then return end
    args = args or {}
    local P = LiveWire.Protocol
    if command == P.S_SNAPSHOT then
        local inv = args.inverter
        if type(inv) == "table" and type(inv.id) == "string" then
            local cur = Client.snapshots[inv.id]
            if not cur or (args.rev or 0) >= (cur.rev or 0) then
                Client.snapshots[inv.id] = args
                touch(inv.id)
                Client.prune()
            end
        end
    elseif command == P.S_DEVICE then
        local view = Client.deviceView
        if view and args.device == view.device and type(args.seq) == "number"
            and args.seq > view.seq and args.seq <= deviceSeq then
            view.seq, view.snapshot = args.seq, args
        end
    elseif command == P.S_BANK then
        local view = Client.bankView
        if view and args.device == view.device and type(args.seq) == "number"
            and args.seq > view.seq and args.seq <= bankSeq then
            view.seq, view.snapshot = args.seq, args
        end
    elseif command == P.S_NOTIFY then
        local list = {}
        if type(args.args) == "table" then
            for i = 1, 5 do
                if args.args[i] ~= nil then list[i] = args.args[i] end
            end
        end
        Client.showNotify(getPlayer(), args.key, list, args.bad == true)
    elseif command == P.S_BEEP then
        if LiveWire.Beep then LiveWire.Beep.play(args.x, args.y, args.z) end
    end
end

Events.OnServerCommand.Add(onServerCommand)

-- Power bank button icon in the loot window: reuse the vanilla military crate icon
-- (ContainerButtonIcons is read by type, ISInventoryPage.lua:1498-1499).
local function onGameStart()
    if ContainerButtonIcons and ContainerButtonIcons.militarycrate then
        ContainerButtonIcons.livewirepowerbank = ContainerButtonIcons.militarycrate
    end
end
Events.OnGameStart.Add(onGameStart)
Events.EveryOneMinute.Add(Client.prune)
Events.OnDisconnect.Add(Client.clearSession)
Events.OnMainMenuEnter.Add(Client.clearSession)
