import FrontEnd
import Testing

import class Foundation.FileManager

struct SourceFileTests {

  @Test func virtualNames() {
    let f: SourceFile = "Hello."
    let g: SourceFile = "Hello."
    let h: SourceFile = "Bye."
    #expect(f.name == g.name)
    #expect(f.name != h.name)
  }

  @Test func virtualText() {
    let f: SourceFile = "Hello."
    #expect(f.text == "Hello.")
  }

  @Test func localText() throws {
    try FileManager.default.withTemporaryFile(containing: "Hello.") { (u) in
      let f = try SourceFile(contentsOf: u)
      #expect(f.text == "Hello.")
    }
  }

  @Test func span() {
    let f: SourceFile = "Hello."
    #expect(f.span.region == f.text.startIndex ..< f.text.endIndex)
  }

  @Test func subscriptBySpan() {
    let f: SourceFile = "Hello."
    #expect(f[f.span] == "Hello.")
  }

  @Test func lineIndex() throws {
    let f = SourceFile.helloWorld
    try #require(f.lineCount == 2)
    #expect(f.line(1).text.dropLast() == "Hello,")  // Handles newlines on Windows.
    #expect(f.line(2).text == "World!")
  }

  @Test func lineContaining() throws {
    let f = SourceFile.helloWorld
    let i1 = try #require(f.text.firstIndex(of: ","))
    #expect(f.line(containing: i1).number == 1)
    let i2 = try #require(f.text.firstIndex(of: "!"))
    #expect(f.line(containing: i2).number == 2)
  }

  @Test func lineAndColumnNumbers() {
    let f = SourceFile.helloWorld
    let p1 = SourcePosition(f.startIndex, in: f)
    #expect(p1.lineAndColumn.line == 1)
    #expect(p1.lineAndColumn.column == 1)

    let p2 = SourcePosition(f.endIndex, in: f)
    #expect(p2.lineAndColumn.line == 2)
    #expect(p2.lineAndColumn.column == 7)
  }

  @Test func lineDescription() {
    let f = SourceFile.helloWorld
    let l = f.line(containing: f.text.startIndex)
    #expect(l.description == "virtual://350c8wstjkie0:1")
  }

  @Test func positionDescrption() throws {
    let f = SourceFile.helloWorld
    let i1 = try #require(f.text.firstIndex(of: ","))
    let p1 = SourcePosition(i1, in: f)
    #expect(p1.description == "virtual://350c8wstjkie0:1:6")
    let i2 = try #require(f.text.firstIndex(of: "!"))
    let p2 = SourcePosition(i2, in: f)
    #expect(p2.description == "virtual://350c8wstjkie0:2:6")
  }

}

extension SourceFile {

  fileprivate static let helloWorld: Self = """
    Hello,
    World!
    """

}
