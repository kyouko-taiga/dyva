/// A terminal symbol of the syntactic grammar.
public struct Token: Hashable, Sendable {

  /// The tag of a token.
  public enum Tag: UInt8, Sendable {

    // Identifiers
    case name
    case underscore

    // Reserved keywords
    case `as`
    case `break`
    case `case`
    case `catch`
    case `continue`
    case `defer`
    case `do`
    case `else`
    case `for`
    case fun
    case `if`
    case `is`
    case `import`
    case `in`
    case infix
    case `inout`
    case `let`
    case match
    case postfix
    case prefix
    case `return`
    case `struct`
    case `subscript`
    case `throw`
    case trait
    case `try`
    case `var`
    case `where`
    case `while`

    // Scalar literals
    case booleanLiteral
    case integerLiteral
    case floatingPointLiteral
    case stringLiteral

    // Operators
    case assign
    case thickArrow
    case `operator`

    // Punctuation
    case comma
    case dot
    case colon
    case semicolon
    case at
    case indentation
    case dedentation

    // Delimiters
    case leftBracket
    case rightBracket
    case leftParenthesis
    case rightParenthesis
    case backslash

    // Errors
    case error
    case unterminatedBackquotedIdentifier
    case unterminatedStringLiteral

  }

  /// The tag of the token.
  public let tag: Tag

  /// The site from which `self` was extracted.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(tag: Tag, site: SourceSpan) {
    self.tag = tag
    self.site = site
  }

  /// The text of this token.
  public var text: Substring { site.text }

  /// `true` iff `self` is a reserved keyword.
  public var isKeyword: Bool {
    (tag.rawValue >= Tag.as.rawValue) && (tag.rawValue <= Tag.while.rawValue)
  }

  /// `true` iff `self` is an operator notation.
  public var isOperatorNotation: Bool {
    switch tag {
    case .infix, .postfix, .prefix:
      return true
    default:
      return false
    }
  }

  /// `true` iff `self` is a valid argument label.
  public var isArgumentLabel: Bool {
    (tag == .name) || isKeyword
  }

  /// Returns a lambda accepting a token and returning `true` iff that token has tag `tag`.
  public static func hasTag(_ tag: Tag) -> (Token) -> Bool {
    { (t) in t.tag == tag }
  }

}
