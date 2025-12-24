local socket = require("socket")
local protocol = require("best_program.protocol")

local Connection = {}
Connection.__index = Connection

function Connection.new(host, port, parser_type, on_data_callback)
    local self = setmetatable({}, Connection)
    self.host = host
    self.port = port
    self.parser_type = parser_type 
    self.on_data = on_data_callback
    
    self.sock = nil
    self.state = "DISCONNECTED"
    self.buffer = ""
    self.last_activity = 0
    self.reconnect_timer = 0
    
    self.expected_size = (parser_type == 1) and protocol.PACKET_SIZE_1 or protocol.PACKET_SIZE_2
    
    return self
end

function Connection:connect()
    self.sock = socket.tcp()
    self.sock:settimeout(0) 
    local res, err = self.sock:connect(self.host, self.port)
    if res or err == "timeout" then
        self.state = "CONNECTING"
        self.last_activity = os.time()
        print("Connecting to " .. self.port .. "...")
    else
        print("Failed to connect to " .. self.port .. ": " .. tostring(err))
        self.state = "WAITING_RETRY"
        self.reconnect_timer = os.time() + 2
    end
end

function Connection:disconnect()
    if self.sock then
        self.sock:close()
    end
    self.sock = nil
    self.state = "DISCONNECTED"
    self.buffer = ""
end

function Connection:update()
    if self.state == "WAITING_RETRY" then
        if os.time() > self.reconnect_timer then
            self:connect()
        end
        return
    end

    if self.state == "DISCONNECTED" then
        self:connect()
        return
    end
    
    -- Check for timeouts
    local timeout = 5 -- 5 seconds timeout
    local delta = os.time() - self.last_activity
    if delta > timeout then
        print(string.format("Timeout on port %d (State: %s). Reconnecting...", self.port, self.state))
        self:disconnect()
        return
    end
    
    if self.state == "CONNECTING" then
        local readable, writable = socket.select(nil, {self.sock}, 0)
        if writable[self.sock] then
            print("Connected to " .. self.port)
            self.state = "HANDSHAKE"
            self.last_activity = os.time()
            self:send("isu_pt")
        end
    end
    
    if self.state == "HANDSHAKE" then
        local chunk, err, partial = self.sock:receive("*a")
        if chunk or (partial and #partial > 0) then
             self.last_activity = os.time()
             local data = chunk or partial
             self.buffer = self.buffer .. data
             if string.find(self.buffer, "granted") then
                 print("Auth success on " .. self.port)
                 self.buffer = "" 
                 self.state = "READY"
             end
        end
    elseif self.state == "READY" then
             self:send("get")
             self.state = "REQUESTING"
    end
    
    if self.state == "REQUESTING" then
        local chunk, err, partial = self.sock:receive("*a") 
        if not chunk then
            if err == "timeout" then
                if partial and #partial > 0 then
                    self.last_activity = os.time()
                    self.buffer = self.buffer .. partial
                end
            elseif err == "closed" then
                print("Connection closed by server " .. self.port)
                self:disconnect()
                return
            else
                print("Error reading " .. self.port .. ": " .. err)
                self:disconnect()
                return
            end
        else
            self.last_activity = os.time()
            self.buffer = self.buffer .. chunk
        end
        
        if #self.buffer >= self.expected_size then
            local data = string.sub(self.buffer, 1, self.expected_size)
            self.buffer = string.sub(self.buffer, self.expected_size + 1)
            
            self.on_data(self.parser_type, data)
            self.state = "READY" 
        end
    end
end

function Connection:send(data)
    if not self.sock then return end
    local i, err = self.sock:send(data)
    if not i then
        print("Send error " .. self.port .. ": " .. err)
        self:disconnect()
    else
        self.last_activity = os.time()
    end
end

return Connection
