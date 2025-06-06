import FrontEnd

let f: SourceFile = """
  struct S(x, y, z) where
    def f(self) = x
  """
var l = Lexer(tokenizing: f)
print(Array(l).map(\.tag))
