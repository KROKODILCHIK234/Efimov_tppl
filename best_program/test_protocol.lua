local protocol = require("best_program.protocol")

describe("Protocol", function()
  
  it("parses int64", function()

    local zero = "\000\000\000\000\000\000\000\000"
    local val, offset = protocol.parse_int64(zero, 1)
    assert.are.equal(0, val)
    assert.are.equal(9, offset)

    local one = "\000\000\000\000\000\000\000\001"
    val, _ = protocol.parse_int64(one, 1)
    assert.are.equal(1, val)
    
    local ts = "\000\006\041\085\165\212\072\000"
    val, _ = protocol.parse_int64(ts, 1)
    assert.are.equal(1734297691375616, val)
    

    local neg = "\255\255\255\255\255\255\255\255"
    val, _ = protocol.parse_int64(neg, 1)
    assert.are.equal(-1, val)
  end)

  it("parses int32", function()
  
    local one = "\000\000\000\001"
    local val, off = protocol.parse_int32(one, 1)
    assert.are.equal(1, val)
    assert.are.equal(5, off)
    
    local neg = "\255\255\255\255"
    val, _ = protocol.parse_int32(neg, 1)
    assert.are.equal(-1, val)
  end)

  it("parses int16", function()

    local one = "\000\001"
    local val, off = protocol.parse_int16(one, 1)
    assert.are.equal(1, val)
    assert.are.equal(3, off)

    local neg = "\255\255"
    val, _ = protocol.parse_int16(neg, 1)
    assert.are.equal(-1, val)
  end)

  it("parses float32", function()

    local zero = "\000\000\000\000"
    local val, off = protocol.parse_float32(zero, 1)
    assert.are.equal(0, val)
    assert.are.equal(5, off)
    
    local one_point_five = "\063\192\000\000"
    val, _ = protocol.parse_float32(one_point_five, 1)
    assert.are.equal(1.5, val)

    local neg_two_point_five = "\192\032\000\000"
    val, _ = protocol.parse_float32(neg_two_point_five, 1)
    assert.are.equal(-2.5, val)
  end)

  it("calculates checksum", function()
    local data = "\001\002\255"
    local sum = protocol.checksum(data)
    assert.are.equal(2, sum)
  end)

end)
