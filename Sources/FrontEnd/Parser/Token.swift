/// A terminal symbol of the syntactic grammar.
public struct Token: Hashable, Sendable {

  /// The tag of a token.
  public enum Tag: UInt8, Sendable {

    // Identifiers
    case name

    // Reserved keywords
    case `catch`
    case def
    case `do`
    case `else`
    case `false`
    case `for`
    case `if`
    case `is`
    case `import`
    case infix
    case `inout`
    case postfix
    case prefix
    case `return`
    case `struct`
    case `throw`
    case trait
    case `true`
    case `var`
    case `where`

    // Scalar literals
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
    case leftBrace
    case rightBrace
    case leftBracket
    case rightBracket
    case leftParenthesis
    case rightParenthesis

    // Errors
    case error
    case invalidIndentation
    case unterminatedBlockComment
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
    (tag.rawValue >= Tag.catch.rawValue) && (tag.rawValue <= Tag.where.rawValue)
  }

  /// Returns a lambda accepting a token and returning `true` iff that token has tag `tag`.
  public static func hasTag(_ tag: Tag) -> (Token) -> Bool {
    { (t) in t.tag == tag }
  }

}
