import Testing
import Utilities

struct HashingTests {

  @Test func combineInt() {
    var h1 = FNV()
    h1.combine(42)
    h1.combine(1337)

    var h2 = FNV()
    h2.combine(42)
    h2.combine(1337)
    #expect(h1.state == h2.state)

    h2.combine(23)
    #expect(h1.state != h2.state)
  }

  @Test func combineString() {
    var h1 = FNV()
    h1.combine("a")
    h1.combine("bcd")

    var h2 = FNV()
    h2.combine("a")
    h2.combine("bcd")
    #expect(h1.state == h2.state)

    h2.combine("xy")
    #expect(h1.state != h2.state)
  }

}
