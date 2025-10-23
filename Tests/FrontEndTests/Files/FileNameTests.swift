import FrontEnd
import Testing

import struct Foundation.URL

struct FileNameTests {

  @Test func description() {
    #expect(FileName.local(.init(filePath: "/foo/bar")).description == "/foo/bar")
    #expect(FileName.virtual(1234).description == "virtual://ya")
  }

  @Test func lexicographicallyPrecedes() {
    let f1 = FileName.local(.init(filePath: "/foo/bar"))
    let f2 = FileName.local(.init(filePath: "/foo/ham"))
    #expect(f1.lexicographicallyPrecedes(f2))
    #expect(!f2.lexicographicallyPrecedes(f1))
    #expect(!f1.lexicographicallyPrecedes(f1))

    let f3 = FileName.virtual(1234)
    let f4 = FileName.virtual(1235)
    #expect(f3.lexicographicallyPrecedes(f4))
    #expect(!f4.lexicographicallyPrecedes(f3))
    #expect(!f3.lexicographicallyPrecedes(f3))

    #expect(f1.lexicographicallyPrecedes(f3))
    #expect(!f3.lexicographicallyPrecedes(f1))
  }

  @Test func gnuPath() {
    let f = FileName.local(.init(filePath: "/foo/bar"))

    #expect(f.gnuPath(relativeTo: URL(filePath: "/foo")) == "bar")
    #expect(f.gnuPath(relativeTo: URL(filePath: "/foo/bar")) == ".")
    #expect(f.gnuPath(relativeTo: URL(filePath: "/ham")) == "../foo/bar")
    #expect(f.gnuPath(relativeTo: URL(filePath: "/foo/bar/ham")) == "..")

    #expect(f.gnuPath(relativeTo: URL.init(string: "https://abc.ch")!) == nil)
  }

}
