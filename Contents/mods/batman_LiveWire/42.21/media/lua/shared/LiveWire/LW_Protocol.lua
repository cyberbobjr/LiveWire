-- Live Wire: client/server command names and argument validation (shared).

LiveWire = LiveWire or {}

local Protocol = {}
LiveWire.Protocol = Protocol

-- Client -> server.
Protocol.C_SUBSCRIBE = "subscribe"
Protocol.C_UNSUBSCRIBE = "unsubscribe"
Protocol.C_UNLINK = "unlink"
Protocol.C_UNCOUPLE = "uncouple"
Protocol.C_UNLINK_BARREL = "unlinkBarrel"
Protocol.C_SET_INVERTER = "setInverter"
Protocol.C_RESET = "reset"
Protocol.C_RESET_BREAKER = "resetBreaker"
Protocol.C_ACK_ALARM = "ackAlarm"
Protocol.C_RENAME = "rename"
Protocol.C_DEBUG = "debug"
Protocol.C_ADOPT = "adopt"
Protocol.C_RESUME_BACKUP = "resumeBackup"
Protocol.C_SET_BRAKE = "setBrake"
Protocol.C_SET_CIRCUIT = "setCircuit"
Protocol.C_READ_BANK = "readBank"
Protocol.C_READ_DEVICE = "readDevice"
Protocol.C_READ_SERVICES = "readCircuitServices"

-- Server -> client.
Protocol.S_SNAPSHOT = "snapshot"
Protocol.S_NOTIFY = "notify"
Protocol.S_BEEP = "beep"
Protocol.S_BANK = "bank"
Protocol.S_DEVICE = "device"
Protocol.S_SERVICE = "circuitService"
Protocol.S_SERVICES = "circuitServices"

Protocol.MAX_NAME = 24
Protocol.MAX_STRING = 32
Protocol.MAX_COORD = 1000000  -- |x|, |y| bound of a position argument
Protocol.MIN_LEVEL = -32      -- floors of a position argument (the engine range)
Protocol.MAX_LEVEL = 31

function Protocol.isId(v, prefix)
    if type(v) ~= "string" or #v > Protocol.MAX_STRING then return false end
    return string.match(v, "^" .. prefix .. "%d+$") ~= nil
end

function Protocol.isDeviceId(v) return Protocol.isId(v, "d") end

function Protocol.isBool(v) return v == true or v == false end

-- Position argument { x, y, z } of a command: whole numbers (numbers or numeric
-- strings, rounded down), finite and inside the world bounds. Returns x, y, z, or nil
-- when `args` is not a table or a coordinate is missing, not a number or out of range.
function Protocol.parsePos(args)
    if type(args) ~= "table" then return nil end
    local x, y, z = tonumber(args.x), tonumber(args.y), tonumber(args.z)
    if not x or not y or not z then return nil end
    if x ~= x or y ~= y or z ~= z then return nil end
    if math.abs(x) > Protocol.MAX_COORD or math.abs(y) > Protocol.MAX_COORD
        or z < Protocol.MIN_LEVEL or z > Protocol.MAX_LEVEL then
        return nil
    end
    return math.floor(x), math.floor(y), math.floor(z)
end

-- Keep printable characters only; cut to max length.
function Protocol.cleanName(v)
    if type(v) ~= "string" then return nil end
    local s = string.gsub(v, "[%c]", "")
    if #s > Protocol.MAX_NAME then s = string.sub(s, 1, Protocol.MAX_NAME) end
    return s
end
