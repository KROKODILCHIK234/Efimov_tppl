local socket = require("socket")

local host = "127.0.0.1"
local port1 = 5123
local port2 = 5124

local server1 = assert(socket.bind(host, port1))
local server2 = assert(socket.bind(host, port2))

server1:settimeout(0)
server2:settimeout(0)

print("Mock servers listening on " .. host .. " ports " .. port1 .. ", " .. port2)

local clients = {}

local function handle_client(client, server_port)
    client:settimeout(0)

    local meta = clients[client]
    if not meta then
        meta = {state = "WAIT_KEY", port = server_port, buffer = ""}
        clients[client] = meta
    end
    
    local data, err, partial = client:receive("*a")
    if partial and #partial > 0 then print("Server recv partial on "..server_port..": "..partial) end
    if data then print("Server recv data on "..server_port..": "..data) end
    if data or (err == "timeout" and partial and #partial > 0) then
        local chunk = data or partial
        meta.buffer = meta.buffer .. chunk
        
        if meta.state == "WAIT_KEY" then
            if meta.buffer == "isu_pt" then
                print("Client on "..server_port.." authorized.")
                client:send("granted")
                meta.state = "WAIT_CMD"
                meta.buffer = ""
            end
        elseif meta.state == "WAIT_CMD" then
            if meta.buffer == "get" then
                print("Client on "..server_port.." requested data.")
                meta.buffer = ""
                
                local response

                local ts = "\000\000\000\232\212\165\016\000"
                if server_port == 5123 then

                    local payload = ts .. "\063\192\000\000" .. "\000\100"
                    
                    local sum = 0
                    for i=1, #payload do sum = (sum + string.byte(payload, i)) % 256 end
                    response = payload .. string.char(sum)
                else

                    local payload = ts .. "\000\000\000\001" .. "\000\000\000\002" .. "\000\000\000\003"

                    local sum = 0
                    for i=1, #payload do sum = (sum + string.byte(payload, i)) % 256 end
                    response = payload .. string.char(sum)
                end
                
                client:send(response)
            end
        end
    elseif err == "closed" then
        print("Client disconnected from " .. server_port)
        clients[client] = nil
        client:close()
    end
end

while true do
    local read_list = {server1, server2}
    for c, _ in pairs(clients) do
        table.insert(read_list, c)
    end
    
    local ready = socket.select(read_list, nil, 0.1)
    
    for _, s in ipairs(ready) do
        if s == server1 then
            local client = server1:accept()
            if client then 
                print("New connection on 5123")
                handle_client(client, 5123) 
            end
        elseif s == server2 then
            local client = server2:accept()
            if client then 
                print("New connection on 5124")
                handle_client(client, 5124) 
            end
        else

            local meta = clients[s]
            if meta then
                handle_client(s, meta.port)
            end
        end
    end
end
