import Utilities

/// The expression of a string literal.
public struct StringLiteral: Expression {

  /// The string value of the literal, with escapes handled.
  public let string: String

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(site: SourceSpan) throws {
    self.site = site
    self.string = try StringLiteral.parseValue(site)
  }

  /// The value of the literal.
  public var rawValue: Substring {
    site.text
  }

  /// The raw string value of the literal, which translates escapes, newlines, ... into its real representation.
  /// Throws if the string contains an invalid escape.
  static func parseValue(_ site: SourceSpan) throws -> String {
    let rawValue = site.text
    var result = ""
    let startStringIndex = rawValue.startIndex
    let endStringIndex = rawValue.index(before: rawValue.endIndex)
    assert(rawValue[startStringIndex] == "\"" && rawValue[endStringIndex] == "\"")
    let string = rawValue[startStringIndex..<endStringIndex]
    var iterator = string.startIndex
    while true {
      iterator = string.index(after: iterator)
      let item = rawValue[iterator]
      if item == "\"" {
        break
      }
      if item != "\\" {  // not an escape
        result.append(item)
        continue
      }
      let chrIndex = string.index(after: iterator)
      assert(chrIndex != string.endIndex)
      switch string[chrIndex] {
      case "n":
        result.append("\n")
      case "t":
        result.append("\t")
      case "r":
        result.append("\r")
      case "\\":
        result.append("\\")
      case "\"":
        result.append("\"")
      case _:
        throw Diagnostic(
          .error,
          "unknown escape",
          at: .init(iterator..<string.index(after: chrIndex), in: site.source)
        )
      // case "u":  // unicode literal // TODO
      //   let startIndex = string.index(after: iterator)
      //   let endIndex =
      //     try string.index(startIndex, offsetBy: 4, limitedBy: string.endIndex)
      //     ?? Diagnostic(
      //       .error, "expected valid unicode escape \\u{XXXX}",
      //       at: .init(iterator..<string.endIndex, in: site.source))
      //   let hex =
      //     try UInt32.init(string[startIndex..<endIndex], radix: 16)
      //     ?? Diagnostic(
      //       .error, "expected valid unicode escape \\u{XXXX}",
      //       at: .init(iterator..<string.endIndex, in: site.source))
      //   let character = Character(content: .init())
      }
      iterator = string.index(after: chrIndex)
    }
    return result
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    rawValue.description
  }

}
