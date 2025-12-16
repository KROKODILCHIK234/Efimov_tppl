local CowInterpreter = {}
CowInterpreter.__index = CowInterpreter

local VALID_COMMANDS = {
    "MoO", "MOo", "moO", "mOo", "moo", "MOO", "OOM", "oom", "mOO", "Moo", "OOO", "MMM"
}

function CowInterpreter:new(code, input_str)
    local obj = {
        code = code,
        instructions = {},
        jump_map = {},
        memory = { [0] = 0 },
        mem_ptr = 0,
        instr_ptr = 1,
        register = nil,
        input = input_str or "",
        input_ptr = 1,
        output = ""
    }
    setmetatable(obj, self)
    return obj
end

function CowInterpreter:_parse_code()
    for word in self.code:gmatch("%S+") do
        for _, cmd in ipairs(VALID_COMMANDS) do
            if word == cmd then
                table.insert(self.instructions, cmd)
                break
            end
        end
    end
end

function CowInterpreter:_build_jump_map()
    local stack = {}
    for i, instr in ipairs(self.instructions) do
        if instr == "moo" then
            table.insert(stack, i)
        elseif instr == "MOO" then
            if #stack > 0 then
                local start_index = table.remove(stack)
                self.jump_map[start_index] = i
                self.jump_map[i] = start_index
            end
        end
    end
end

function CowInterpreter:_get_mem()
    return self.memory[self.mem_ptr] or 0
end

function CowInterpreter:_set_mem(value)
    self.memory[self.mem_ptr] = value
end

function CowInterpreter:execute()
    self:_parse_code()
    self:_build_jump_map()

    while self.instr_ptr <= #self.instructions do
        local instr = self.instructions[self.instr_ptr]

        if instr == "MoO" then
            self:_set_mem(self:_get_mem() + 1)
        elseif instr == "MOo" then
            self:_set_mem(self:_get_mem() - 1)
        elseif instr == "moO" then
            self.mem_ptr = self.mem_ptr + 1
        elseif instr == "mOo" then
            self.mem_ptr = self.mem_ptr - 1
        elseif instr == "moo" then
            if self:_get_mem() == 0 then
                self.instr_ptr = self.jump_map[self.instr_ptr] or self.instr_ptr
            end
        elseif instr == "MOO" then
            if self.jump_map[self.instr_ptr] and self:_get_mem() ~= 0 then
                self.instr_ptr = self.jump_map[self.instr_ptr]
            end
        elseif instr == "OOM" then
            self.output = self.output .. tostring(self:_get_mem())
        elseif instr == "oom" then
            local num_str = self.input:sub(self.input_ptr):match("^-?%d+")
            if num_str then
                self:_set_mem(tonumber(num_str))
                self.input_ptr = self.input_ptr + #num_str
            end
        elseif instr == "Moo" then
            if self:_get_mem() == 0 then
                if self.input_ptr <= #self.input then
                    self:_set_mem(string.byte(self.input, self.input_ptr))
                    self.input_ptr = self.input_ptr + 1
                end
            else
                local val = self:_get_mem()
                if val >= 0 and val <= 255 then
                    self.output = self.output .. string.char(val)
                end
            end
        elseif instr == "OOO" then
            self:_set_mem(0)
        elseif instr == "MMM" then
            if self.register == nil then
                self.register = self:_get_mem()
            else
                self:_set_mem(self.register)
                self.register = nil
            end
        elseif instr == "mOO" then
            local target_idx = self:_get_mem()
            if target_idx > 0 and target_idx <= #self.instructions then
                local target_instr = self.instructions[target_idx]
                -- Replicating logic for non-control-flow instructions
                if target_instr == "MoO" then self:_set_mem(self:_get_mem() + 1)
                elseif target_instr == "MOo" then self:_set_mem(self:_get_mem() - 1)
                elseif target_instr == "moO" then self.mem_ptr = self.mem_ptr + 1
                elseif target_instr == "mOo" then self.mem_ptr = self.mem_ptr - 1
                elseif target_instr == "OOM" then self.output = self.output .. tostring(self:_get_mem())
                elseif target_instr == "Moo" then
                    if self:_get_mem() == 0 then
                        if self.input_ptr <= #self.input then
                            self:_set_mem(string.byte(self.input, self.input_ptr))
                            self.input_ptr = self.input_ptr + 1
                        end
                    else
                        local val = self:_get_mem()
                        if val >= 0 and val <= 255 then self.output = self.output .. string.char(val) end
                    end
                elseif target_instr == "OOO" then self:_set_mem(0)
                elseif target_instr == "MMM" then
                    if self.register == nil then self.register = self:_get_mem()
                    else self:_set_mem(self.register); self.register = nil end
                end
            end
        end
        self.instr_ptr = self.instr_ptr + 1
    end

    return self.output
end


return CowInterpreter
