-- Live Wire: client state (snapshots received from the server) and translated
-- player messages.
if isServer() then return end

LiveWire = LiveWire or {}

local Client = LiveWire.Client or {}
LiveWire.Client = Client

Client.snapshots = {}   -- inverter id -> snapshot
local soloCache = {}
local soloRegistry = nil

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
    if not isClient() and LiveWire.Registry and LiveWire.Registry.ready then
        local inv = LiveWire.Registry.device(inverterId)
        local grid = inv and inv.grid and LiveWire.Registry.grid(inv.grid)
        if soloRegistry ~= LiveWire.Registry.data then
            soloRegistry, soloCache = LiveWire.Registry.data, {}
        end
        if not grid then soloCache[inverterId] = nil; return nil end
        local cur = soloCache[inverterId]
        if not cur or cur.grid ~= grid or cur.rev ~= grid.rev then
            cur = { grid = grid, rev = grid.rev, snapshot = LiveWire.Sim.snapshot(grid) }
            soloCache[inverterId] = cur
        end
        return cur.snapshot
    end
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
    sendClientCommand(getPlayer(), LiveWire.MODULE, command, args or {})
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
            end
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
