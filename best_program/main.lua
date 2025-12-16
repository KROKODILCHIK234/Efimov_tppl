-- Настройка путей для поиска модулей
-- Позволяет запускать программу как из корневой директории, так и из best_program
local script_path = arg[0] or ""
local script_dir = script_path:match("(.*/)") or "./"
-- Добавляем текущую директорию скрипта и родительскую директорию в пути поиска
package.path = script_dir .. "?.lua;" .. script_dir .. "?/?.lua;" .. 
               script_dir .. "../?.lua;" .. script_dir .. "../?/?.lua;" .. 
               package.path

local socket = require("socket")
io.stdout:setvbuf('no')

-- Загрузка модулей (пробуем с префиксом best_program, затем без префикса)
local Connection, protocol
local ok1, conn = pcall(require, "best_program.connection")
local ok2, prot = pcall(require, "best_program.protocol")
if ok1 and ok2 then
    Connection = conn
    protocol = prot
else
    -- Если не получилось, пробуем без префикса (для запуска из best_program)
    Connection = require("connection")
    protocol = require("protocol")
end

-- Определяем путь к выходному файлу (в той же директории, где находится скрипт)
local OUTPUT_FILE = script_dir .. "data.txt"
io.stdout:setvbuf('no')

local file = io.open(OUTPUT_FILE, "a+")
if not file then
    print("Error opening file " .. OUTPUT_FILE)
    os.exit(1)
end

local function format_time(timestamp_micros)
    local seconds = math.floor(timestamp_micros / 1000000)
    return os.date("!%Y-%m-%d %H:%M:%S", seconds)
end

local function on_data(parser_type, data)
    local timestamp, offset
    timestamp, offset = protocol.parse_int64(data, 1)
    
    local line = ""
    local date_str = format_time(timestamp)
    
    local checksum = protocol.checksum(data)
    local received_checksum = string.byte(data, #data)
    local calc_checksum = protocol.checksum(string.sub(data, 1, #data - 1))
    
    if received_checksum ~= calc_checksum then
        print(string.format("Checksum mismatch! Received %d, Calc %d. Ignoring packet.", received_checksum, calc_checksum))
        return
    end

    if parser_type == 1 then
        local temp, pressure
        temp, offset = protocol.parse_float32(data, offset)
        pressure, offset = protocol.parse_int16(data, offset)
        
        line = string.format("%s Server1 Temp: %.2f, Pressure: %d\n", date_str, temp, pressure)
        
    elseif parser_type == 2 then
        local x, y, z
        x, offset = protocol.parse_int32(data, offset)
        y, offset = protocol.parse_int32(data, offset)
        z, offset = protocol.parse_int32(data, offset)
        
        line = string.format("%s Server2 X: %d, Y: %d, Z: %d\n", date_str, x, y, z)
    end
    
    print("Writing: " .. line:sub(1, -2))
    file:write(line)
    file:flush()
end

local host = arg[1] or "95.163.237.76"
local c1 = Connection.new(host, 5123, 1, on_data)
local c2 = Connection.new(host, 5124, 2, on_data)

local connections = {c1, c2}

print("Starting data collection...")
print("Press Ctrl+C to stop...")
local running = true

-- Обработка сигнала для корректного завершения
-- Используем защищенный вызов для обработки прерываний
local function cleanup()
    print("\nShutting down...")
    running = false
end

-- Попытка установить обработчик сигнала (опционально, если доступен posix)
local ok, posix = pcall(require, "posix")
if ok and posix.signal then
    posix.signal(posix.SIGINT, cleanup)
    posix.signal(posix.SIGTERM, cleanup)
end

for _, c in ipairs(connections) do
    c:connect()
end

while running do
    local read_sockets = {}
    local any_connected = false
    
    for _, c in ipairs(connections) do
        c:update()
        if c.sock and c.state ~= "DISCONNECTED" then
            table.insert(read_sockets, c.sock)
            any_connected = true
        end
    end
    
    if #read_sockets > 0 then
        socket.select(read_sockets, nil, 0.05)
    else
        socket.sleep(0.1)
    end
end

-- Корректное закрытие соединений
print("Closing connections...")
for _, c in ipairs(connections) do
    c:disconnect()
end

file:close()
print("Program stopped. Data saved to " .. OUTPUT_FILE)
