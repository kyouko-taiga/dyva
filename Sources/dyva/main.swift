import FrontEnd

//let f: SourceFile = """
//  trait P
//  struct S1(x, y)
//  struct S2(x, y) is P
//  struct S3(x, y) is P where
//    fun f(x) = x
//
//  fun foo(x, y,) = x
//  fun bar(x) where
//    get = x
//    set(y) =
//      x
//  fun ham() where get set(x)
//  """

let f: SourceFile = #"""
  struct Pair(x, y) is P where
    fun first(self) =
      self.x
    fun second(self) =
      self.x
    subscript _(self) = self.x

  fun zero(x, y, u) =
    while case let a = x, a && b do hello()
    defer foo[x, y]
    let xs = [[1], [1 : "2"], [:], []]
    let ys = (1,) is (Int,)

  fun first() =
    var x = \(foo, bar) in
      defer koala()
      try
        foo
      catch
        case _ do abc

    1-- + ++1
    2 + 2 * 1
    x is Int

    fun g() =
      var f = \(x) in x
      xs.map(f)

  #  struct S where
  #    extractor cons(self, m) =
  #      if self.condition do m.match(1, [1, 2]) else m.fail

  fun f(from x : inout, to y) =
    var x = if true do
      g(x: 1) + 2
    else match xs
      case .foo(var x) do y
      case let x as Int do z
      case _ do z.fun
      #statement2
  """#

var p = Program()
let (_, s) = p.addSource(f)
print(p.show(s))
print(p.diagnostics)
