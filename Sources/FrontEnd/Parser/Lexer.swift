/// The tokens of a source file.
public struct Lexer: IteratorProtocol, Sequence {

  /// The source file being tokenized.
  public let source: SourceFile

  /// The current position of the lexer in `source`.
  public private(set) var position: SourceFile.Index

  /// The current level of indentation.
  private var indentation: Int

  /// A stack of tokens that have been scanned but not produced yet.
  private var prefetched: [Token] = []

  /// `true` iff `position` is at the start or the character immediately before is a newline.
  private var isAtLineStart: Bool

  /// Creates an instance enumerating the tokens in `source`.
  public init(tokenizing source: SourceFile) {
    self.source = source
    self.position = source.startIndex
    self.indentation = 0
    self.isAtLineStart = true
  }

  /// Advances to the next token and returns it, or returns `nil` if no next token exists.
  public mutating func next() -> Token? {
    discardWhitespacesAndComments()
    if let t = prefetched.popLast() { return t }

    guard let head = peek() else {
      if indentation > 0 {
        indentation -= 1
        return .init(tag: .dedentation, site: .empty(at: .init(position, in: source)))
      } else {
        return nil
      }
    }

    if let t = takeNumericLiteral() {
      return t
    } else if head == "\"" {
      return takeStringLiteral()
    } else if head == "`" {
      return takeBackquotedIdentifier()
    } else if head.isIdentifierHead {
      return takeKeywordOrIdentifier()
    } else if head.isOperator {
      return takeOperator()
    } else {
      return takePunctuation()
    }
  }

  /// Consumes and returns a numeric literal iff one can be scanned from the character stream.
  private mutating func takeNumericLiteral() -> Token? {
    let p = take("-") ?? position

    guard let h = peek(), h.isDecimalDigit else {
      position = p
      return nil
    }

    // Is the literal is non-decimal?
    if let i = take("0") {
      let isEmpty: Bool

      switch peek() {
      case .some("x"):
        discard()
        isEmpty = takeDigitSequence(\.isHexDigit).isEmpty
      case .some("o"):
        discard()
        isEmpty = takeDigitSequence(\.isOctalDigit).isEmpty
      case .some("b"):
        discard()
        isEmpty = takeDigitSequence(\.isBinaryDigit).isEmpty
      default:
        isEmpty = true
      }

      if !isEmpty {
        // Non-decimal number literals cannot have an exponent.
        return .init(tag: .integerLiteral, site: span(p ..< position))
      } else {
        position = i
      }
    }

    // Read the integer part.
    let q = take(while: { (c) in c.isDecimalDigit || (c == "_") }).endIndex

    // Is there a fractional part?
    if let i = take(".") {
      if takeDigitSequence(\.isDecimalDigit).isEmpty {
        position = i
        return .init(tag: .integerLiteral, site: span(p ..< q))
      }
    }

    // Is there an exponent?
    if let i = take("e") ?? take("E") {
      _ = take("+") ?? take("-")
      if takeDigitSequence(\.isDecimalDigit).isEmpty {
        position = i
      }
    }

    // No fractional part and no exponent.
    if position == q {
      return .init(tag: .integerLiteral, site: span(p ..< position))
    } else {
      return .init(tag: .floatingPointLiteral, site: span(p ..< position))
    }
  }

  /// Consumes and returns the longest sequence that start with a digit and then contains either
  /// digits or the underscore, using `isDigit` to determine whether a character is a digit.
  private mutating func takeDigitSequence(_ isDigit: (Character) -> Bool) -> Substring {
    if let h = peek(), isDigit(h) {
      return take(while: { (c) in isDigit(c) || (c == "_") })
    } else {
      return source.text[position ..< position]
    }
  }

  /// Consumes and returns a string literal.
  private mutating func takeStringLiteral() -> Token {
    let start = position
    discard()

    var escape = false
    while position < source.endIndex {
      if !escape && (take("\"") != nil) {
        return .init(tag: .stringLiteral, site: span(start ..< position))
      } else if take("\\") != nil {
        escape = !escape
      } else {
        discard()
        escape = false
      }
    }

    return .init(tag: .unterminatedStringLiteral, site: span(start ..< position))
  }

  /// Consumes and returns an indentifier in backquotes.
  private mutating func takeBackquotedIdentifier() -> Token {
    // The start position is *after* the backquote.
    discard()
    let start = position

    while position < source.endIndex {
      let end = position
      if take("`") != nil {
        let t: Token.Tag = (start != end) ? .name : .error
        return .init(tag: t, site: span(start ..< end))
      } else {
        discard()
      }
    }

    return .init(tag: .unterminatedBackquotedIdentifier, site: span(start ..< position))
  }

  /// Consumes and returns a keyword or identifier.
  private mutating func takeKeywordOrIdentifier() -> Token {
    let word = take(while: \.isIdentifierTail)

    let tag: Token.Tag
    switch word {
    case "_": tag = .underscore
    case "as": tag = .as
    case "break": tag = .break
    case "case": tag = .case
    case "catch": tag = .catch
    case "continue": tag = .continue
    case "defer": tag = .defer
    case "do": tag = .do
    case "else": tag = .else
    case "false": tag = .booleanLiteral
    case "for": tag = .for
    case "fun": tag = .fun
    case "if": tag = .if
    case "is": tag = .is
    case "import": tag = .import
    case "in": tag = .in
    case "infix": tag = .infix
    case "inout": tag = .inout
    case "let": tag = .let
    case "match": tag = .match
    case "postfix": tag = .postfix
    case "prefix": tag = .prefix
    case "return": tag = .return
    case "struct": tag = .struct
    case "subscript": tag = .subscript
    case "throw": tag = .throw
    case "trait": tag = .trait
    case "true": tag = .booleanLiteral
    case "try": tag = .try
    case "var": tag = .var
    case "where": tag = .where
    case "while": tag = .while
    default: tag = .name
    }

    assert(!word.isEmpty)
    return .init(tag: tag, site: span(word.startIndex ..< word.endIndex))
  }

  /// Consumes and returns an operator.
  private mutating func takeOperator() -> Token {
    let start = position
    let text = take(while: \.isOperator)
    let tag: Token.Tag
    switch text {
    case "=": tag = .assign
    case "=>": tag = .thickArrow
    default: tag = .operator
    }
    return .init(tag: tag, site: span(start ..< position))
  }

  /// Consumes and returns a punctuation token or parenthesized operator if possible; otherwise
  /// consumes a single character and returns an error token.
  private mutating func takePunctuation() -> Token {
    let start = position
    let tag: Token.Tag
    switch take() {
    case "[": tag = .leftBracket
    case "]": tag = .rightBracket
    case "(": tag = .leftParenthesis
    case ")": tag = .rightParenthesis
    case "@": tag = .at
    case ",": tag = .comma
    case ";": tag = .semicolon
    case ":": tag = .colon
    case ".": tag = .dot
    case "\\": tag = .backslash
    default: tag = .error
    }
    return .init(tag: tag, site: span(start ..< position))
  }

  /// Consumes and returns the next character.
  private mutating func take() -> Character {
    defer { position = source.index(after: position) }
    return source[position]
  }

  /// Returns the next character without consuming it or `nil` if all the input has been consumed.
  private func peek() -> Character? {
    position != source.endIndex ? source[position] : nil
  }

  /// Returns `true` iff the next character satisfies `predicate`.
  private func next(is predicate: (Character) -> Bool) -> Bool {
    peek().map(predicate) ?? false
  }

  /// Discards all whitespaces and comments preceding the next token or newline, prefeteching
  /// identation and dedentation tokens.
  private mutating func discardWhitespacesAndComments() {
    while position != source.endIndex {
      if isAtLineStart {
        let prefix = take(while: { (c) in c.isWhitespace && !c.isNewline })

        // Is the prefix significant?
        if next(is: \.isNewline) || (take("#") != nil) {
          discard(while: { (c) in !c.isNewline })
          if next(is: \.isNewline) {
            discard()
          }
          continue
        }

        let a = Array(prefix.indices)
        if indentation > a.count {
          let s = SourceSpan.empty(at: .init(position, in: source))
          for _ in 0 ..< (indentation - a.count) {
            prefetched.append(.init(tag: .dedentation, site: s))
          }
        } else if indentation < a.count {
          for p in a[indentation...].reversed() {
            let s = SourceSpan(p ..< source.text.index(after: p), in: source)
            prefetched.append(.init(tag: .indentation, site: s))
          }
        }

        indentation = a.count
        isAtLineStart = false
      }

      else if source[position].isNewline {
        discard()
        isAtLineStart = true
      } else if source[position].isWhitespace {
        discard()
      } else if take("#") != nil {
        discard(while: { (c) in !c.isNewline })
      } else {
        break
      }
    }
  }

  /// Discards `count` characters.
  private mutating func discard(_ count: Int = 1) {
    position = source.index(position, offsetBy: count)
  }

  /// Discards characters until `predicate` isn't satisfied or all the input has been consumed.
  private mutating func discard(while predicate: (Character) -> Bool) {
    _ = take(while: predicate)
  }

  /// Returns the longest prefix of the input whose characters all satisfy `predicate` and advances
  /// the position of `self` until after that prefix.
  private mutating func take(while predicate: (Character) -> Bool) -> Substring {
    let start = position
    while (position != source.endIndex) && predicate(source[position]) {
      position = source.index(after: position)
    }
    return source.text[start ..< position]
  }

  /// If the input starts with `prefix`, returns the current position and advances to the position
  /// until after `prefix`. Otherwise, returns `nil`.
  private mutating func take(_ prefix: String) -> String.Index? {
    var newPosition = position
    for c in prefix {
      if newPosition == source.endIndex || source[newPosition] != c { return nil }
      newPosition = source.index(after: newPosition)
    }
    defer { position = newPosition }
    return position
  }

  /// Returns a source span covering `range`.
  private func span(_ range: Range<String.Index>) -> SourceSpan {
    .init(range, in: source)
  }

}

extension Character {

  /// `true` iff `self` is a letter or the underscore.
  fileprivate var isIdentifierHead: Bool {
    self.isLetter || self == "_"
  }

  /// `true` iff `self` is a letter, a decimal digit, or the underscore.
  fileprivate var isIdentifierTail: Bool {
    self.isIdentifierHead || self.isDecimalDigit
  }

  /// `true` iff `self` may be part of an operator.
  fileprivate var isOperator: Bool {
    "<>=+-*/%&|!?^~".contains(self)
  }

  /// `true` iff `self` is a decimal digit.
  fileprivate var isDecimalDigit: Bool {
    asciiValue.map({ (ascii) in (0x30 ... 0x39) ~= ascii }) ?? false
  }

  /// `true` iff `self` is an octal digit.
  fileprivate var isOctalDigit: Bool {
    asciiValue.map({ (ascii) in (0x30 ... 0x37) ~= ascii }) ?? false
  }

  /// `true` iff `self` is a binary digit.
  fileprivate var isBinaryDigit: Bool {
    (self == "0") || (self == "1")
  }

}
