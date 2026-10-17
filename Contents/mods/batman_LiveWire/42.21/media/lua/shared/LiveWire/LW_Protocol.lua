-- Live Wire: client/server command names and argument validation (shared).

LiveWire = LiveWire or {}

local Protocol = {}
LiveWire.Protocol = Protocol

-- Client -> server.
Protocol.C_SUBSCRIBE = "subscribe"
Protocol.C_UNSUBSCRIBE = "unsubscribe"
Protocol.C_UNLINK = "unlink"
Protocol.C_SET_INVERTER = "setInverter"
Protocol.C_RESET = "reset"
Protocol.C_RENAME = "rename"
Protocol.C_REQUEST_ANCHORS = "requestAnchors"

-- Server -> client.
Protocol.S_SNAPSHOT = "snapshot"
Protocol.S_NOTIFY = "notify"
Protocol.S_REFUSE = "refuse"
Protocol.S_ANCHORS = "anchors"
Protocol.S_BEEP = "beep"

Protocol.MAX_NAME = 24
Protocol.MAX_STRING = 32

function Protocol.isId(v, prefix)
    if type(v) ~= "string" or #v > Protocol.MAX_STRING then return false end
    return string.match(v, "^" .. prefix .. "%d+$") ~= nil
end

function Protocol.isDeviceId(v) return Protocol.isId(v, "d") end
function Protocol.isGridId(v) return Protocol.isId(v, "g") end

function Protocol.isBool(v) return v == true or v == false end

-- Keep printable characters only; cut to max length.
function Protocol.cleanName(v)
    if type(v) ~= "string" then return nil end
    local s = string.gsub(v, "[%c]", "")
    if #s > Protocol.MAX_NAME then s = string.sub(s, 1, Protocol.MAX_NAME) end
    return s
end
