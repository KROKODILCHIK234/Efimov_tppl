local interpreter = require('interpreter')

describe("Pascal Interpreter", function()
    describe("Lexer", function()
        it("should tokenize basic assignment", function()
            local text = 'BEGIN x := 2 + 3; END.'
            local lexer = interpreter.Lexer:new(text)
            
            local token = lexer:get_next_token()
            assert.equals('BEGIN', token.type)
            
            token = lexer:get_next_token()
            assert.equals('ID', token.type)
            assert.equals('X', token.value)
            
            token = lexer:get_next_token()
            assert.equals('ASSIGN', token.type)
        end)
    end)

    describe("Interpreter", function()
        it("should handle empty program (Example 1)", function()
            local text = [[
                BEGIN
                END.
            ]]
            local result = interpreter.interpret(text)
            assert.are.same({}, result)
        end)

        it("should handle complex expressions (Example 2)", function()
            local text = [[
                BEGIN
                    x:= 2 + 3 * (2 + 3);
                    y:= 2 / 2 - 2 + 3 * ((1 + 1) + (1 + 1));
                END.
            ]]
            local result = interpreter.interpret(text)
            assert.equals(17, result.X)
            assert.equals(11, result.Y)
        end)

        it("should handle nested blocks (Example 3)", function()
            local text = [[
                BEGIN
                    y := 2;
                    BEGIN
                        a := 3;
                        a := a;
                        b := 10 + a + 10 * y / 4;
                        c := a - b
                    END;
                    x := 11;
                END.
            ]]
            local result = interpreter.interpret(text)
            assert.equals(2, result.Y)
            assert.equals(3, result.A)
            assert.equals(18, result.B)
            assert.equals(-15, result.C)
            assert.equals(11, result.X)
        end)

        it("should handle arithmetic precedence", function()
            local text = [[
                BEGIN
                    x := 14 + 2 * 3 - 6 / 2;
                END.
            ]]
            local result = interpreter.interpret(text)
            assert.equals(17, result.X)
        end)

        it("should handle unary operators", function()
            local text = [[
                BEGIN
                    x := -5;
                    y := +10;
                    z := -x + y;
                END.
            ]]
            local result = interpreter.interpret(text)
            assert.equals(-5, result.X)
            assert.equals(10, result.Y)
            assert.equals(15, result.Z)
        end)
    end)
end)
