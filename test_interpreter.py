
import unittest
from interpreter import Lexer, Parser, Interpreter, INTEGER, PLUS, MINUS, MUL, DIV, LPAREN, RPAREN, ID, ASSIGN, BEGIN, END, SEMI, DOT, EOF

class TestLexer(unittest.TestCase):
    def test_tokens(self):
        text = 'BEGIN x := 2 + 3; END.'
        lexer = Lexer(text)
        token = lexer.get_next_token()
        self.assertEqual(token.type, BEGIN)
        token = lexer.get_next_token()
        self.assertEqual(token.type, ID)
        self.assertEqual(token.value, 'X')
        token = lexer.get_next_token()
        self.assertEqual(token.type, ASSIGN)
        token = lexer.get_next_token()
        self.assertEqual(token.type, INTEGER)
        self.assertEqual(token.value, 2)
        token = lexer.get_next_token()
        self.assertEqual(token.type, PLUS)
        token = lexer.get_next_token()
        self.assertEqual(token.type, INTEGER)
        self.assertEqual(token.value, 3)
        token = lexer.get_next_token()
        self.assertEqual(token.type, SEMI)
        token = lexer.get_next_token()
        self.assertEqual(token.type, END)
        token = lexer.get_next_token()
        self.assertEqual(token.type, DOT)
        token = lexer.get_next_token()
        self.assertEqual(token.type, EOF)

class TestInterpreter(unittest.TestCase):
    def test_example_1(self):
        text = """
        BEGIN
        END.
        """
        lexer = Lexer(text)
        parser = Parser(lexer)
        interpreter = Interpreter(parser)
        interpreter.interpret()
        self.assertEqual(interpreter.GLOBAL_SCOPE, {})

    def test_example_2(self):
        text = """
        BEGIN
            x:= 2 + 3 * (2 + 3);
            y:= 2 / 2 - 2 + 3 * ((1 + 1) + (1 + 1));
        END.
        """
        lexer = Lexer(text)
        parser = Parser(lexer)
        interpreter = Interpreter(parser)
        interpreter.interpret()
        self.assertEqual(interpreter.GLOBAL_SCOPE['X'], 17)
        # y = 1 - 2 + 3 * 4 = -1 + 12 = 11
        self.assertEqual(interpreter.GLOBAL_SCOPE['Y'], 11)

    def test_example_3(self):
        text = """
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
        """
        lexer = Lexer(text)
        parser = Parser(lexer)
        interpreter = Interpreter(parser)
        interpreter.interpret()
        self.assertEqual(interpreter.GLOBAL_SCOPE['Y'], 2)
        self.assertEqual(interpreter.GLOBAL_SCOPE['A'], 3)
        # b = 10 + 3 + 10 * 2 / 4 = 13 + 20 / 4 = 13 + 5 = 18
        self.assertEqual(interpreter.GLOBAL_SCOPE['B'], 18)
        # c = 3 - 18 = -15
        self.assertEqual(interpreter.GLOBAL_SCOPE['C'], -15)
        self.assertEqual(interpreter.GLOBAL_SCOPE['X'], 11)

    def test_arithmetic_precedence(self):
        text = """
        BEGIN
            x := 14 + 2 * 3 - 6 / 2;
        END.
        """
        # x = 14 + 6 - 3 = 17
        lexer = Lexer(text)
        parser = Parser(lexer)
        interpreter = Interpreter(parser)
        interpreter.interpret()
        self.assertEqual(interpreter.GLOBAL_SCOPE['X'], 17)

if __name__ == '__main__':
    unittest.main()
