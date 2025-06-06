import FrontEnd
import XCTest

final class FileNameTests: XCTestCase {

  func testDescription() {
    XCTAssertEqual(FileName.local(.init(filePath: "/foo/bar")).description, "/foo/bar")
    XCTAssertEqual(FileName.virtual(1234).description, "virtual://ya")
  }

  func testLexicographicallyPrecedes() {
    let f1 = FileName.local(.init(filePath: "/foo/bar"))
    let f2 = FileName.local(.init(filePath: "/foo/ham"))
    XCTAssert(f1.lexicographicallyPrecedes(f2))
    XCTAssertFalse(f2.lexicographicallyPrecedes(f1))
    XCTAssertFalse(f1.lexicographicallyPrecedes(f1))

    let f3 = FileName.virtual(1234)
    let f4 = FileName.virtual(1235)
    XCTAssert(f3.lexicographicallyPrecedes(f4))
    XCTAssertFalse(f4.lexicographicallyPrecedes(f3))
    XCTAssertFalse(f3.lexicographicallyPrecedes(f3))

    XCTAssert(f1.lexicographicallyPrecedes(f3))
    XCTAssertFalse(f3.lexicographicallyPrecedes(f1))
  }

  func testGNUPath() {
    let f = FileName.local(.init(filePath: "/foo/bar"))

    XCTAssertEqual(f.gnuPath(relativeTo: URL(filePath: "/foo")), "bar")
    XCTAssertEqual(f.gnuPath(relativeTo: URL(filePath: "/foo/bar")), ".")
    XCTAssertEqual(f.gnuPath(relativeTo: URL(filePath: "/ham")), "../foo/bar")
    XCTAssertEqual(f.gnuPath(relativeTo: URL(filePath: "/foo/bar/ham")), "..")

    XCTAssertNil(f.gnuPath(relativeTo: URL.init(string: "https://abc.ch")!))
  }

}
