local inspect = require('inspect') -- A library to pretty print tables, for debugging
local CowInterpreter = require('cow.interpreter')

local function read_file(path)
    local file = io.open(path, "rb") -- Open in binary mode
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content:gsub("\r\n", "\n")
end

describe("CowInterpreter", function()

    it("should build a jump map for loops", function()
        local code = "moo MOO moo moo MOO MOO"
        local interpreter = CowInterpreter:new(code)
        interpreter:_parse_code()
        interpreter:_build_jump_map()
        assert.are.same({[1]=2, [2]=1, [3]=6, [4]=5, [5]=4, [6]=3}, interpreter.jump_map)
    end)
    
    it("should handle mismatched moo gracefully", function()
        local code = "moo moo MOO"
        local interpreter = CowInterpreter:new(code)
        assert.is_true(pcall(function() interpreter:execute() end))
    end)

    describe("Instructions", function()
        it("MoO should increment memory cell", function()
            local interpreter = CowInterpreter:new("MoO MoO")
            interpreter:execute()
            assert.are.equal(2, interpreter.memory[0])
        end)

        it("MOo should decrement memory cell", function()
            local interpreter = CowInterpreter:new("MoO MoO MOo")
            interpreter:execute()
            assert.are.equal(1, interpreter.memory[0])
        end)

        it("moO should move memory pointer forward", function()
            local interpreter = CowInterpreter:new("moO MoO")
            interpreter:execute()
            assert.are.equal(1, interpreter.mem_ptr)
            assert.are.equal(1, interpreter.memory[1])
        end)

        it("mOo should move memory pointer backward", function()
            local interpreter = CowInterpreter:new("moO mOo MoO")
            interpreter:execute()
            assert.are.equal(0, interpreter.mem_ptr)
            assert.are.equal(1, interpreter.memory[0])
        end)

        it("OOO should zero the current cell", function()
            local interpreter = CowInterpreter:new("MoO MoO OOO")
            interpreter:execute()
            assert.are.equal(0, interpreter.memory[0])
        end)

        it("MMM should copy to/from register", function()
            local interpreter = CowInterpreter:new("MoO MoO MMM")
            interpreter:execute()
            assert.are.equal(2, interpreter.register)
            assert.are.equal(2, interpreter.memory[0])
            
            local interpreter2 = CowInterpreter:new("MoO MoO MMM OOO MMM")
            interpreter2:execute()
            assert.are.equal(nil, interpreter2.register)
            assert.are.equal(2, interpreter2.memory[0])
        end)

        it("OOM should output value as number string", function()
            local interpreter = CowInterpreter:new("MoO MoO MoO OOM")
            local output = interpreter:execute()
            assert.are.equal("3", output)
        end)

        it("Moo should output value as character if not zero", function()
            local code = ("MoO "):rep(65) .. "Moo"
            local interpreter = CowInterpreter:new(code)
            local output = interpreter:execute()
            assert.are.equal("A", output)
        end)

        it("Moo should read character if cell is zero", function()
            local interpreter = CowInterpreter:new("Moo", "B")
            interpreter:execute()
            assert.are.equal(66, interpreter.memory[0]) -- ASCII for 'B'
        end)

        it("oom should read a number", function()
            local interpreter = CowInterpreter:new("oom", "123")
            interpreter:execute()
            assert.are.equal(123, interpreter.memory[0])
        end)

        it("oom should do nothing if input is not a number", function()
            local interpreter = CowInterpreter:new("oom", "abc")
            interpreter:execute()
            assert.are.equal(0, interpreter.memory[0]) -- Should remain at its initial value
        end)

        it("mOO should execute instruction", function()
            -- Set cell 0 to 2, then mOO will execute 2nd instruction (MoO)
            local code = "MoO MoO mOO"
            local interpreter = CowInterpreter:new(code)
            interpreter:execute()
            -- 1. MoO -> mem[0] = 1
            -- 2. MoO -> mem[0] = 2
            -- 3. mOO -> mem[0] is 2, executes instr 2 (MoO), mem[0] becomes 3
            assert.are.equal(3, interpreter.memory[0])
        end)

        it("Moo should do nothing if cell is 0 and input is empty", function()
            local interpreter = CowInterpreter:new("Moo", "")
            interpreter:execute()
            assert.are.equal(0, interpreter.memory[0]) -- Should remain at its initial value
        end)

        it("loops correctly", function()
            local code = "MoO MoO MoO moo MOo MOO"
            local interpreter = CowInterpreter:new(code)
            interpreter:execute()
            assert.are.equal(0, interpreter.memory[0])
        end)
    end)

    describe("Simple example file", function()
        it("should interpret echo.cow correctly", function()
            local code = read_file("cow/examples/echo.cow")
            assert.is_not_nil(code, "echo.cow not found")
            local interpreter = CowInterpreter:new(code, "A")
            local output = interpreter:execute()
            assert.are.equal("A", output)
        end)
    end)

    describe("Provided (broken) Example files", function()
        it("should interpret hello.cow correctly", function()
            pending("Provided hello.cow file is syntactically incorrect and produces wrong output")
            local code = read_file("cow/examples/hello.cow")
            assert.is_not_nil(code, "hello.cow not found")
            local interpreter = CowInterpreter:new(code)
            local output = interpreter:execute()
            assert.are.equal("Hello, World!\n", output)
        end)

        it("should interpret fib.cow correctly", function()
            pending("Provided fib.cow file is syntactically incorrect and produces wrong output")
            local code = read_file("cow/examples/fib.cow")
            assert.is_not_nil(code, "hello.cow not found")
            local interpreter = CowInterpreter:new(code)
            local output = interpreter:execute()
            assert.are.equal("1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, ...", output)
        end)
    end)
end)
