local interpreter = require('interpreter')

print("Testing Pascal Interpreter in Lua")
print("==================================\n")

print("Test 1: Empty program")
local text1 = [[
BEGIN
END.
]]
local result1 = interpreter.interpret(text1)
print("Result:", next(result1) == nil and "{}" or "ERROR")
print()


print("Test 2: Complex expressions")
local text2 = [[
BEGIN
    x:= 2 + 3 * (2 + 3);
    y:= 2 / 2 - 2 + 3 * ((1 + 1) + (1 + 1));
END.
]]
local result2 = interpreter.interpret(text2)
print("x =", result2.X, "(expected: 17)")
print("y =", result2.Y, "(expected: 11)")
print()


print("Test 3: Nested blocks")
local text3 = [[
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
local result3 = interpreter.interpret(text3)
print("y =", result3.Y, "(expected: 2)")
print("a =", result3.A, "(expected: 3)")
print("b =", result3.B, "(expected: 18)")
print("c =", result3.C, "(expected: -15)")
print("x =", result3.X, "(expected: 11)")
print()


print("Test 4: Arithmetic precedence")
local text4 = [[
BEGIN
    x := 14 + 2 * 3 - 6 / 2;
END.
]]
local result4 = interpreter.interpret(text4)
print("x =", result4.X, "(expected: 17)")
print()

print("All tests completed!")
