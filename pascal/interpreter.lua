-local INTEGER = 'INTEGER'
local PLUS = 'PLUS'
local MINUS = 'MINUS'
local MUL = 'MUL'
local DIV = 'DIV'
local LPAREN = 'LPAREN'
local RPAREN = 'RPAREN'
local ID = 'ID'
local ASSIGN = 'ASSIGN'
local BEGIN = 'BEGIN'
local END = 'END'
local SEMI = 'SEMI'
local DOT = 'DOT'
local EOF = 'EOF'

local Token = {}
Token.__index = Token

function Token:new(type, value)
    local token = {type = type, value = value}
    setmetatable(token, Token)
    return token
end

local RESERVED_KEYWORDS = {
    BEGIN = Token:new(BEGIN, 'BEGIN'),
    END = Token:new(END, 'END')
}

local Lexer = {}
Lexer.__index = Lexer

function Lexer:new(text)
    local lexer = {
        text = text,
        pos = 1,
        current_char = text:sub(1, 1)
    }
    setmetatable(lexer, Lexer)
    return lexer
end

function Lexer:error()
    error('Invalid character')
end

function Lexer:advance()
    self.pos = self.pos + 1
    if self.pos > #self.text then
        self.current_char = nil
    else
        self.current_char = self.text:sub(self.pos, self.pos)
    end
end

function Lexer:peek()
    local peek_pos = self.pos + 1
    if peek_pos > #self.text then
        return nil
    else
        return self.text:sub(peek_pos, peek_pos)
    end
end

function Lexer:skip_whitespace()
    while self.current_char and self.current_char:match('%s') do
        self:advance()
    end
end

function Lexer:integer()
    local result = ''
    while self.current_char and self.current_char:match('%d') do
        result = result .. self.current_char
        self:advance()
    end
    return tonumber(result)
end

function Lexer:_id()
    local result = ''
    while self.current_char and self.current_char:match('%w') do
        result = result .. self.current_char
        self:advance()
    end
    
    local upper_result = result:upper()
    local token = RESERVED_KEYWORDS[upper_result]
    if token then
        return Token:new(token.type, token.value)
    else
        return Token:new(ID, upper_result)
    end
end

function Lexer:get_next_token()
    while self.current_char do
        if self.current_char:match('%s') then
            self:skip_whitespace()
        elseif self.current_char:match('%d') then
            return Token:new(INTEGER, self:integer())
        elseif self.current_char:match('%a') then
            return self:_id()
        elseif self.current_char == ':' and self:peek() == '=' then
            self:advance()
            self:advance()
            return Token:new(ASSIGN, ':=')
        elseif self.current_char == ';' then
            self:advance()
            return Token:new(SEMI, ';')
        elseif self.current_char == '.' then
            self:advance()
            return Token:new(DOT, '.')
        elseif self.current_char == '+' then
            self:advance()
            return Token:new(PLUS, '+')
        elseif self.current_char == '-' then
            self:advance()
            return Token:new(MINUS, '-')
        elseif self.current_char == '*' then
            self:advance()
            return Token:new(MUL, '*')
        elseif self.current_char == '/' then
            self:advance()
            return Token:new(DIV, '/')
        elseif self.current_char == '(' then
            self:advance()
            return Token:new(LPAREN, '(')
        elseif self.current_char == ')' then
            self:advance()
            return Token:new(RPAREN, ')')
        else
            self:error()
        end
    end

    return Token:new(EOF, nil)
end

local BinOp = {}
BinOp.__index = BinOp

function BinOp:new(left, op, right)
    local node = {left = left, op = op, right = right}
    setmetatable(node, BinOp)
    return node
end

local Num = {}
Num.__index = Num

function Num:new(token)
    local node = {token = token, value = token.value}
    setmetatable(node, Num)
    return node
end

local UnaryOp = {}
UnaryOp.__index = UnaryOp

function UnaryOp:new(op, expr)
    local node = {op = op, expr = expr}
    setmetatable(node, UnaryOp)
    return node
end

local Compound = {}
Compound.__index = Compound

function Compound:new()
    local node = {children = {}}
    setmetatable(node, Compound)
    return node
end

local Assign = {}
Assign.__index = Assign

function Assign:new(left, op, right)
    local node = {left = left, op = op, right = right}
    setmetatable(node, Assign)
    return node
end

local Var = {}
Var.__index = Var

function Var:new(token)
    local node = {token = token, value = token.value}
    setmetatable(node, Var)
    return node
end

local NoOp = {}
NoOp.__index = NoOp

function NoOp:new()
    local node = {}
    setmetatable(node, NoOp)
    return node
end

local Parser = {}
Parser.__index = Parser

function Parser:new(lexer)
    local parser = {
        lexer = lexer,
        current_token = lexer:get_next_token()
    }
    setmetatable(parser, Parser)
    return parser
end

function Parser:error()
    error('Invalid syntax')
end

function Parser:eat(token_type)
    if self.current_token.type == token_type then
        self.current_token = self.lexer:get_next_token()
    else
        self:error()
    end
end

function Parser:factor()
    local token = self.current_token
    if token.type == PLUS then
        self:eat(PLUS)
        return UnaryOp:new(token, self:factor())
    elseif token.type == MINUS then
        self:eat(MINUS)
        return UnaryOp:new(token, self:factor())
    elseif token.type == INTEGER then
        self:eat(INTEGER)
        return Num:new(token)
    elseif token.type == LPAREN then
        self:eat(LPAREN)
        local node = self:expr()
        self:eat(RPAREN)
        return node
    else
        return self:variable()
    end
end

function Parser:term()
    local node = self:factor()

    while self.current_token.type == MUL or self.current_token.type == DIV do
        local token = self.current_token
        if token.type == MUL then
            self:eat(MUL)
        elseif token.type == DIV then
            self:eat(DIV)
        end

        node = BinOp:new(node, token, self:factor())
    end

    return node
end

function Parser:expr()
    local node = self:term()

    while self.current_token.type == PLUS or self.current_token.type == MINUS do
        local token = self.current_token
        if token.type == PLUS then
            self:eat(PLUS)
        elseif token.type == MINUS then
            self:eat(MINUS)
        end

        node = BinOp:new(node, token, self:term())
    end

    return node
end

function Parser:program()
    local node = self:compound_statement()
    self:eat(DOT)
    return node
end

function Parser:compound_statement()
    self:eat(BEGIN)
    local nodes = self:statement_list()
    self:eat(END)

    local root = Compound:new()
    for _, node in ipairs(nodes) do
        table.insert(root.children, node)
    end

    return root
end

function Parser:statement_list()
    local node = self:statement()
    local results = {node}

    while self.current_token.type == SEMI do
        self:eat(SEMI)
        table.insert(results, self:statement())
    end

    if self.current_token.type == ID then
        self:error()
    end

    return results
end

function Parser:statement()
    if self.current_token.type == BEGIN then
        return self:compound_statement()
    elseif self.current_token.type == ID then
        return self:assignment_statement()
    else
        return self:empty()
    end
end

function Parser:assignment_statement()
    local left = self:variable()
    local token = self.current_token
    self:eat(ASSIGN)
    local right = self:expr()
    return Assign:new(left, token, right)
end

function Parser:variable()
    local node = Var:new(self.current_token)
    self:eat(ID)
    return node
end

function Parser:empty()
    return NoOp:new()
end

function Parser:parse()
    local node = self:program()
    if self.current_token.type ~= EOF then
        self:error()
    end
    return node
end

local Interpreter = {}
Interpreter.__index = Interpreter

function Interpreter:new(parser)
    local interpreter = {
        parser = parser,
        GLOBAL_SCOPE = {}
    }
    setmetatable(interpreter, Interpreter)
    return interpreter
end

function Interpreter:visit(node)
    local node_type = getmetatable(node)
    
    if node_type == BinOp then
        return self:visit_BinOp(node)
    elseif node_type == Num then
        return self:visit_Num(node)
    elseif node_type == UnaryOp then
        return self:visit_UnaryOp(node)
    elseif node_type == Compound then
        return self:visit_Compound(node)
    elseif node_type == Assign then
        return self:visit_Assign(node)
    elseif node_type == Var then
        return self:visit_Var(node)
    elseif node_type == NoOp then
        return self:visit_NoOp(node)
    else
        error('No visit method for node type')
    end
end

function Interpreter:visit_BinOp(node)
    if node.op.type == PLUS then
        return self:visit(node.left) + self:visit(node.right)
    elseif node.op.type == MINUS then
        return self:visit(node.left) - self:visit(node.right)
    elseif node.op.type == MUL then
        return self:visit(node.left) * self:visit(node.right)
    elseif node.op.type == DIV then
        return math.floor(self:visit(node.left) / self:visit(node.right))
    end
end

function Interpreter:visit_Num(node)
    return node.value
end

function Interpreter:visit_UnaryOp(node)
    if node.op.type == PLUS then
        return self:visit(node.expr)
    elseif node.op.type == MINUS then
        return -self:visit(node.expr)
    end
end

function Interpreter:visit_Compound(node)
    for _, child in ipairs(node.children) do
        self:visit(child)
    end
end

function Interpreter:visit_Assign(node)
    local var_name = node.left.value
    self.GLOBAL_SCOPE[var_name] = self:visit(node.right)
end

function Interpreter:visit_Var(node)
    local var_name = node.value
    local val = self.GLOBAL_SCOPE[var_name]
    if val == nil then
        error(string.format("Variable '%s' not found", var_name))
    end
    return val
end

function Interpreter:visit_NoOp(node)
end

function Interpreter:interpret()
    local tree = self.parser:parse()
    if tree then
        self:visit(tree)
    end
    return self.GLOBAL_SCOPE
end


local function interpret(text)
    local lexer = Lexer:new(text)
    local parser = Parser:new(lexer)
    local interpreter = Interpreter:new(parser)
    return interpreter:interpret()
end

return {
    interpret = interpret,
    Lexer = Lexer,
    Parser = Parser,
    Interpreter = Interpreter,
    Token = Token
}
