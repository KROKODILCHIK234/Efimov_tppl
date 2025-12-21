local script_path = arg[0] or ""
local script_dir = script_path:match("(.*/)") or "./"
package.path = script_dir .. "?.lua;" .. script_dir .. "?/?.lua;" .. 
               script_dir .. "../?.lua;" .. script_dir .. "../?/?.lua;" .. 
               package.path

-- test_runner.lua
local function describe(desc, func)
    print("Suite: " .. desc)
    func()
end

local function it(desc, func)
    io.write("  Test: " .. desc .. " ... ")
    local status, err = pcall(func)
    if status then
        print("PASS")
    else
        print("FAIL")
        print("    " .. err)
    end
end

local assert = {}
assert.are = {}

function assert.are.equal(expected, actual)
    if expected ~= actual then
        error("Expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

-- Global shims
_G.describe = describe
_G.it = it
_G.assert = assert

-- Run tests
require("test_protocol")
