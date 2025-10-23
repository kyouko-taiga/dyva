import FrontEnd
import Testing

struct SourceSpanTests {

  @Test func initRegionIn() {
    let f: SourceFile = "Hello."
    let i = f.startIndex
    let s = SourceSpan(i ..< f.index(i, offsetBy: 2), in: f)
    #expect(s.region == i ..< f.index(i, offsetBy: 2))
  }

  @Test func start() {
    let f: SourceFile = "Hello."
    let s = f.span
    #expect(s.start == .init(f.startIndex, in: f))
  }

  @Test func end() {
    let f: SourceFile = "Hello."
    let s = f.span
    #expect(s.end == .init(f.endIndex, in: f))
  }

  @Test func intesects() {
    let f: SourceFile = "Hello."

    let i0 = f.startIndex
    let i1 = f.index(i0, offsetBy: 2)
    let i2 = f.index(i0, offsetBy: 4)
    let i3 = f.index(i0, offsetBy: 6)

    let s0 = SourceSpan(i0 ..< i1, in: f)  // He
    let s1 = SourceSpan(i2 ..< i3, in: f)  // o.

    #expect(s0.intersects(f.span))
    #expect(s1.intersects(f.span))
    #expect(!s0.intersects(s1))

    let g: SourceFile = "Bye."
    #expect(!f.span.intersects(g.span))
  }

  @Test func intersection() {
    let f: SourceFile = "Hello."
    let g: SourceFile = "Bye."

    let i0 = f.startIndex
    let i1 = f.index(i0, offsetBy: 2)
    let i2 = f.index(i0, offsetBy: 4)
    let i3 = f.index(i0, offsetBy: 6)

    let s0 = SourceSpan(i0 ..< i2, in: f)  // Hell
    let s1 = SourceSpan(i1 ..< i2, in: f)  // ll
    let s2 = SourceSpan(i1 ..< i3, in: f)  // llo.

    #expect(s0.intersection(s0) == s0)
    #expect(s0.intersection(s1) == s1)
    #expect(s0.intersection(s2) == s1)
    #expect(s0.intersection(g.span) == .empty(at: s0.end))

    #expect(s1.intersection(s0) == s1)
    #expect(s1.intersection(s1) == s1)
    #expect(s1.intersection(s2) == s1)
    #expect(s1.intersection(g.span) == .empty(at: s1.end))

    #expect(s2.intersection(s0) == s1)
    #expect(s2.intersection(s1) == s1)
    #expect(s2.intersection(s2) == s2)
    #expect(s2.intersection(g.span) == .empty(at: s2.end))

    let s3 = SourceSpan(i0 ..< i1, in: f)  // He
    let s4 = SourceSpan(i2 ..< i3, in: f)  // o.

    #expect(s3.intersection(s4) == .empty(at: s3.end))
  }

  @Test func extendedToCover() {
    let f: SourceFile = "Hello."
    let i0 = f.startIndex
    let i1 = f.index(i0, offsetBy: 2)
    let i2 = f.index(i0, offsetBy: 4)
    let i3 = f.index(i0, offsetBy: 6)

    let s = SourceSpan(i1 ..< i2, in: f)
    #expect(s.extended(toCover: .init(i0 ..< i2, in: f)).region == i0 ..< i2)
    #expect(s.extended(toCover: .init(i1 ..< i3, in: f)).region == i1 ..< i3)
    #expect(s.extended(toCover: .init(i0 ..< i3, in: f)).region == i0 ..< i3)
  }

  @Test func extendedUpTo() {
    let f: SourceFile = "Hello."
    let i0 = f.startIndex
    let i1 = f.index(i0, offsetBy: 2)
    let i2 = f.index(i0, offsetBy: 4)

    let s = SourceSpan(i0 ..< i1, in: f)
    #expect(s.extended(upTo: i0).region == i0 ..< i1)
    #expect(s.extended(upTo: i1).region == i0 ..< i1)
    #expect(s.extended(upTo: i2).region == i0 ..< i2)
  }

  @Test func empty() {
    let f: SourceFile = "Hello."
    let p = SourcePosition(f.startIndex, in: f)
    let s = SourceSpan.empty(at: p)
    #expect(s.region == f.startIndex ..< f.startIndex)
  }

  @Test func description() {
    let f: SourceFile = "Hello."
    #expect(f.span.description == "virtual://1ssiyy33rbj6z:1.1-7")
    let g: SourceFile = "A\nB"
    #expect(g.span.description == "virtual://3ahohnnbwwf82:1.1-2:2")
  }

}
