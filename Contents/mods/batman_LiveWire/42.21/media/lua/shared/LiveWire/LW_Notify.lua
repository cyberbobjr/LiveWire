-- Live Wire: player messages. The authority sends translation KEYS; the client
-- translates, because a dedicated server does not load mod translations
-- (knowledge/api-42-21.md:145-150).

LiveWire = LiveWire or {}

-- args: list of strings or numbers for %1, %2...
function LiveWire.notify(player, key, args, bad)
    if not player then return end
    if isServer() then
        sendServerCommand(player, LiveWire.MODULE, LiveWire.Protocol.S_NOTIFY,
            { key = key, args = args or {}, bad = bad == true })
    elseif LiveWire.Client and LiveWire.Client.showNotify then
        LiveWire.Client.showNotify(player, key, args or {}, bad == true)
    end
end

-- Notify every online player within `radius` tiles of (x, y, z).
function LiveWire.notifyNear(x, y, z, radius, key, args, bad)
    local players
    if isServer() then
        players = getOnlinePlayers()
    else
        players = IsoPlayer.getPlayers()
    end
    if not players then return end
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p and not p:isDead() then
            local dx, dy = p:getX() - x, p:getY() - y
            if dx * dx + dy * dy <= radius * radius and math.abs(p:getZ() - z) < 3 then
                LiveWire.notify(p, key, args, bad)
            end
        end
    end
end
