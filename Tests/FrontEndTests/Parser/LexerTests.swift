import FrontEnd
import XCTest

final class LexerTests: XCTestCase {

  func testLineComments() throws {
    let input: SourceFile = """
      Hello # comment
      World
      """
    var lexer = Lexer(tokenizing: input)
    try assertNext(from: &lexer, is: .name)
    try assertNext(from: &lexer, is: .name)
    XCTAssertNil(lexer.next())
  }

  func testIndentation() throws {
    let input: SourceFile = """
      one
          # comment
        two three

          four
        five
      """
    var lexer = Lexer(tokenizing: input)
    try assertNext(from: &lexer, is: .name)
    try assertNext(from: &lexer, is: .indentation)
    try assertNext(from: &lexer, is: .indentation)
    try assertNext(from: &lexer, is: .name)
    try assertNext(from: &lexer, is: .name)
    try assertNext(from: &lexer, is: .indentation)
    try assertNext(from: &lexer, is: .indentation)
    try assertNext(from: &lexer, is: .name)
    try assertNext(from: &lexer, is: .dedentation)
    try assertNext(from: &lexer, is: .dedentation)
    try assertNext(from: &lexer, is: .name)
    try assertNext(from: &lexer, is: .dedentation)
    try assertNext(from: &lexer, is: .dedentation)
    XCTAssertNil(lexer.next())
  }

  func testDelimiters() throws {
    var lexer = Lexer(tokenizing: "([])\\")
    try assertNext(from: &lexer, is: .leftParenthesis)
    try assertNext(from: &lexer, is: .leftBracket)
    try assertNext(from: &lexer, is: .rightBracket)
    try assertNext(from: &lexer, is: .rightParenthesis)
    try assertNext(from: &lexer, is: .backslash)
    XCTAssertNil(lexer.next())
  }

  func testError() throws {
    var lexer = Lexer(tokenizing: "\0.")
    try assertNext(from: &lexer, is: .error)
    try assertNext(from: &lexer, is: .dot)
    XCTAssertNil(lexer.next())
  }

  func testBooleanLiteral() throws {
    var lexer = Lexer(tokenizing: "true false")
    try assertNext(from: &lexer, is: .booleanLiteral, withValue: "true")
    try assertNext(from: &lexer, is: .booleanLiteral, withValue: "false")
    XCTAssertNil(lexer.next())
  }

  func testDecimalIntegerLiteral() throws {
    var lexer = Lexer(tokenizing: "0 001 42 00 1_234 1_2__34__ -1 -a")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "001")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "42")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "00")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "1_234")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "1_2__34__")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "-1")
    try assertNext(from: &lexer, is: .operator, withValue: "-")
    try assertNext(from: &lexer, is: .name, withValue: "a")
  }

  func testHexadecimalIntegerLiteral() throws {
    var lexer = Lexer(tokenizing: "0x0123 0xabcdef 0x1__0_a_ 0xg 0x -0x1")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0x0123")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0xabcdef")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0x1__0_a_")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0")
    try assertNext(from: &lexer, is: .name, withValue: "xg")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0")
    try assertNext(from: &lexer, is: .name, withValue: "x")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "-0x1")
  }

  func testOctalIntegerLiteral() throws {
    var lexer = Lexer(tokenizing: "0o0123 0o1__0_6_ 0o8 0o -0o1")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0o0123")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0o1__0_6_")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0")
    try assertNext(from: &lexer, is: .name, withValue: "o8")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0")
    try assertNext(from: &lexer, is: .name, withValue: "o")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "-0o1")
  }

  func testBinaryIntegerLiteral() throws {
    var lexer = Lexer(tokenizing: "0b01 0b1__0_1_ 0b8 0b -0b1")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0b01")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0b1__0_1_")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0")
    try assertNext(from: &lexer, is: .name, withValue: "b8")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "0")
    try assertNext(from: &lexer, is: .name, withValue: "b")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "-0b1")
  }

  func testFloatingPointerLiteral() throws {
    var lexer = Lexer(tokenizing: "0.0 0_.0_ 0.1__2_ 1e1_000 1.12e+1_3 3.45E-6 1. 1.x 1e -1e2")
    try assertNext(from: &lexer, is: .floatingPointLiteral, withValue: "0.0")
    try assertNext(from: &lexer, is: .floatingPointLiteral, withValue: "0_.0_")
    try assertNext(from: &lexer, is: .floatingPointLiteral, withValue: "0.1__2_")
    try assertNext(from: &lexer, is: .floatingPointLiteral, withValue: "1e1_000")
    try assertNext(from: &lexer, is: .floatingPointLiteral, withValue: "1.12e+1_3")
    try assertNext(from: &lexer, is: .floatingPointLiteral, withValue: "3.45E-6")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "1")
    try assertNext(from: &lexer, is: .dot)
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "1")
    try assertNext(from: &lexer, is: .dot)
    try assertNext(from: &lexer, is: .name, withValue: "x")
    try assertNext(from: &lexer, is: .integerLiteral, withValue: "1")
    try assertNext(from: &lexer, is: .name, withValue: "e")
    try assertNext(from: &lexer, is: .floatingPointLiteral, withValue: "-1e2")
  }

  func testStringLiteral() throws {
    var lexer = Lexer(tokenizing: #""" "a 0+ " "a\nb" "a\"" "abc "#)
    try assertNext(from: &lexer, is: .stringLiteral, withValue: #""""#)
    try assertNext(from: &lexer, is: .stringLiteral, withValue: #""a 0+ ""#)
    try assertNext(from: &lexer, is: .stringLiteral, withValue: #""a\nb""#)
    try assertNext(from: &lexer, is: .stringLiteral, withValue: #""a\"""#)
    try assertNext(from: &lexer, is: .unterminatedStringLiteral, withValue: #""abc "#)
  }

  func testIdentifier() throws {
    var lexer = Lexer(tokenizing: "a _a _0 \u{3042}\u{3042} _")
    try assertNext(from: &lexer, is: .name, withValue: "a")
    try assertNext(from: &lexer, is: .name, withValue: "_a")
    try assertNext(from: &lexer, is: .name, withValue: "_0")
    try assertNext(from: &lexer, is: .name, withValue: "\u{3042}\u{3042}")
    try assertNext(from: &lexer, is: .underscore, withValue: "_")
    XCTAssertNil(lexer.next())
  }

  func testBackquotedIdentifier() throws {
    var lexer = Lexer(tokenizing: "`a` `fun` `a b` `` `")
    try assertNext(from: &lexer, is: .name, withValue: "a")
    try assertNext(from: &lexer, is: .name, withValue: "fun")
    try assertNext(from: &lexer, is: .name, withValue: "a b")
    try assertNext(from: &lexer, is: .error)
    try assertNext(from: &lexer, is: .unterminatedBackquotedIdentifier)
    XCTAssertNil(lexer.next())
  }

  func testKeywords() throws {
    let input: SourceFile = """
      as break case catch continue defer do else for fun if is import in infix inout let match \
      postfix prefix return struct subscript throw trait try var where while
      """
    var lexer = Lexer(tokenizing: input)
    try assertNext(from: &lexer, is: .as)
    try assertNext(from: &lexer, is: .break)
    try assertNext(from: &lexer, is: .case)
    try assertNext(from: &lexer, is: .catch)
    try assertNext(from: &lexer, is: .continue)
    try assertNext(from: &lexer, is: .defer)
    try assertNext(from: &lexer, is: .do)
    try assertNext(from: &lexer, is: .else)
    try assertNext(from: &lexer, is: .for)
    try assertNext(from: &lexer, is: .fun)
    try assertNext(from: &lexer, is: .if)
    try assertNext(from: &lexer, is: .is)
    try assertNext(from: &lexer, is: .import)
    try assertNext(from: &lexer, is: .in)
    try assertNext(from: &lexer, is: .infix)
    try assertNext(from: &lexer, is: .inout)
    try assertNext(from: &lexer, is: .let)
    try assertNext(from: &lexer, is: .match)
    try assertNext(from: &lexer, is: .postfix)
    try assertNext(from: &lexer, is: .prefix)
    try assertNext(from: &lexer, is: .return)
    try assertNext(from: &lexer, is: .struct)
    try assertNext(from: &lexer, is: .subscript)
    try assertNext(from: &lexer, is: .throw)
    try assertNext(from: &lexer, is: .trait)
    try assertNext(from: &lexer, is: .try)
    try assertNext(from: &lexer, is: .var)
    try assertNext(from: &lexer, is: .where)
    try assertNext(from: &lexer, is: .while)
    XCTAssertNil(lexer.next())
  }

  func testOperator() throws {
    var lexer = Lexer(tokenizing: "<= ++ & &&& == +* *+")
    try assertNext(from: &lexer, is: .operator, withValue: "<=")
    try assertNext(from: &lexer, is: .operator, withValue: "++")
    try assertNext(from: &lexer, is: .operator, withValue: "&")
    try assertNext(from: &lexer, is: .operator, withValue: "&&&")
    try assertNext(from: &lexer, is: .operator, withValue: "==")
    try assertNext(from: &lexer, is: .operator, withValue: "+*")
    try assertNext(from: &lexer, is: .operator, withValue: "*+")
    XCTAssertNil(lexer.next())
  }

  func testPunctuation() throws {
    var lexer = Lexer(tokenizing: "@,.: ; (+")
    try assertNext(from: &lexer, is: .at)
    try assertNext(from: &lexer, is: .comma)
    try assertNext(from: &lexer, is: .dot)
    try assertNext(from: &lexer, is: .colon)
    try assertNext(from: &lexer, is: .semicolon)
    try assertNext(from: &lexer, is: .leftParenthesis)
    try assertNext(from: &lexer, is: .operator)
    XCTAssertNil(lexer.next())
  }

}

private func assertNext(
  from lexer: inout Lexer, is expected: Token.Tag, withValue text: String? = nil,
  file: StaticString = #file, line: UInt = #line
) throws {
  let next = try XCTUnwrap(lexer.next())
  XCTAssertEqual(next.tag, expected, file: (file), line: line)
  if let s = text {
    XCTAssertEqual(String(next.text), s, file: (file), line: line)
  }
}
