local protocol = {}

local function byte(data, i)
    return string.byte(data, i) or 0
end

function protocol.parse_float32(data, offset)
    local b1, b2, b3, b4 = string.byte(data, offset, offset + 3)
    if not b1 then return 0, offset + 4 end
    
    local sign = (b1 > 127) and -1 or 1
    local expo = (b1 % 128) * 2 + math.floor(b2 / 128)
    local mant = (b2 % 128) * 65536 + b3 * 256 + b4
    
    if expo == 0 then
        return 0, offset + 4 
    elseif expo == 255 then
        return 0, offset + 4 
    end
    
    local val = sign * (1 + mant / 8388608) * math.pow(2, expo - 127)
    return val, offset + 4
end

function protocol.parse_int64(data, offset)
    local b1, b2, b3, b4, b5, b6, b7, b8 = string.byte(data, offset, offset + 7)
    if not b1 then return 0, offset + 8 end
    
    local negative = false
    if b1 > 127 then
        negative = true
    end
    
    local high = b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
    local low = b5 * 16777216 + b6 * 65536 + b7 * 256 + b8
    
    if negative then
         b1, b2, b3, b4 = 255-b1, 255-b2, 255-b3, 255-b4
         b5, b6, b7, b8 = 255-b5, 255-b6, 255-b7, 255-b8
         
         high = b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
         low = b5 * 16777216 + b6 * 65536 + b7 * 256 + b8
         local val = (high * 4294967296 + low) + 1
         return -val, offset + 8
    else
        local val = high * 4294967296 + low
        return val, offset + 8
    end
end

function protocol.parse_int32(data, offset)
    local b1, b2, b3, b4 = string.byte(data, offset, offset + 3)
    if not b1 then return 0, offset + 4 end
    
    local val = b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
    if val > 2147483647 then
        val = val - 4294967296
    end
    return val, offset + 4
end

function protocol.parse_int16(data, offset)
    local b1, b2 = string.byte(data, offset, offset + 1)
    if not b1 then return 0, offset + 2 end
    
    local val = b1 * 256 + b2
    if val > 32767 then
        val = val - 65536
    end
    return val, offset + 2
end

function protocol.checksum(data)
    local sum = 0
    for i = 1, #data do
        sum = (sum + string.byte(data, i)) % 256
    end
    return sum
end

return protocol
