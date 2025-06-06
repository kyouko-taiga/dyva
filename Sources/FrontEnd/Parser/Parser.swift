import Utilities

/// The parsing of a source file.
public struct Parser {

  /// The tokens in the input.
  private var tokens: Lexer

  /// The position immediately after the last consumed token.
  private var position: SourcePosition

  /// The current indentation.
  private var indententation: [SourceSpan] = []

  /// `true` iff the parser is recognizing the subpattern of a binfing pattern.
  private var isParsingBindingSubpattern: Bool = false

  /// The next token to consume, if already extracted from the source.
  private var lookahead: Token? = nil

  /// Parses the contents of `source` into `file`.
  internal static func parse(_ source: SourceFile, into file: inout Program.SourceContainer) {
    var parser = Parser(
      tokens: Lexer(tokenizing: source),
      position: SourcePosition(source.startIndex, in: source))

    do {
      try parser.parseTopLevelDeclarations(in: &file)
    } catch let e as Diagnostic {
      file.addDiagnostic(e)
    } catch {
      unreachable()
    }
  }

  // MARK: Declarations

  /// Parses the top-level declarations of a file.
  private mutating func parseTopLevelDeclarations(
    in file: inout Program.SourceContainer
  ) throws {
    assert(file.roots.isEmpty, "syntax tree is not empty")
    var roots: [DeclarationIdentity] = []
    while peek() != nil {
      try roots.append(parseDeclaration(in: &file))
    }
    swap(&file.roots, &roots)
  }

  /// Parses a top-level declaration.
  private mutating func parseDeclaration(
    in file: inout Program.SourceContainer
  ) throws -> DeclarationIdentity {
    let head = try peek() ?? expected("declaration")
    switch head.tag {
    case .fun, .subscript:
      return try .init(parseFunctionDeclaration(in: &file))
    case .struct:
      return try .init(parseStructDeclaration(in: &file))
    case .trait:
      return try .init(parseTraitDeclaration(in: &file))
    case .var, .let, .inout:
      return try .init(parseBindingDeclaration(as: .unconditional, in: &file))
    default:
      throw unexpected(head)
    }
  }

  /// Parses a binding declaration.
  private mutating func parseBindingDeclaration(
    as role: BindingDeclaration.Role, in file: inout Program.SourceContainer
  ) throws -> BindingDeclaration.ID {
    let start = nextTokenStart()
    let pattern = try parseBindingPattern(in: &file)
    let initializer = try parseOptionalInitializerExpression(in: &file)

    let end = initializer.map({ (i) in file[i].site.end }) ?? file[pattern].site.end
    let site = SourceSpan(from: start, to: end)

    return file.insert(
      BindingDeclaration(role: role, pattern: pattern, initializer: initializer, site: site))
  }

  /// Parses a function declaration.
  private mutating func parseFunctionDeclaration(
    in file: inout Program.SourceContainer
  ) throws -> FunctionDeclaration.ID {
    let introducer = try take(.fun) ?? take(.subscript) ?? expected(.fun)
    let name = try parseMemberName()
    let parameters = try parseParameterList(in: &file)

    let body: [StatementIdentity]?
    let site: SourceSpan

    if take(.assign) != nil {
      body = try parseBlockBody(in: &file)
      site = introducer.site.extended(upTo: file[body!.last!].site.end.index)
    } else {
      body = nil
      site = span(from: introducer)
    }

    return file.insert(
      FunctionDeclaration(
        introducer: introducer, name: name.value, parameters: parameters, body: body, site: site))
  }

  /// Parses a list of parameters if the next token is a left parenthesis.
  private mutating func parseOptionalParameterList(
    in file: inout Program.SourceContainer
  ) throws -> [ParameterDeclaration.ID] {
    if next(is: .leftParenthesis) {
      return try parseParameterList(in: &file)
    } else {
      return []
    }
  }

  /// Parses a list of parameters.
  private mutating func parseParameterList(
    in file: inout Program.SourceContainer
  ) throws -> [ParameterDeclaration.ID] {
    try inParentheses { (me) in
      let (ps, _) = try me.commaSeparated(until: Token.hasTag(.rightParenthesis)) { (me) in
        try me.parseParameterDeclaration(in: &file)
      }
      return ps
    }
  }

  /// Parses the declaration of a parameter in a function declaration.
  private mutating func parseParameterDeclaration(
    in file: inout Program.SourceContainer
  ) throws -> ParameterDeclaration.ID {
    let start = nextTokenStart()
    let (label, identifier) = try parseParameterInterface()
    var site = span(from: start)

    let convention = try parseOptionalPassingConvention()
    let defaultValue = try parseOptionalInitializerExpression(in: &file)

    if let v = defaultValue {
      site = site.extended(upTo: file[v].site.end.index)
    } else if let c = convention {
      site = site.extended(upTo: c.site.end.index)
    }

    return file.insert(
      ParameterDeclaration(
        label: label,
        identifier: identifier,
        convention: convention,
        defaultValue: defaultValue,
        site: site))
  }

  /// Parses the label and identifier of a parameter.
  private mutating func parseParameterInterface() throws -> (label: String?, identifier: String) {
    let l = try take(if: \.isArgumentLabel) ?? expected("identifier")

    if let i = take(.name) {
      return (String(l.text), String(i.text))
    } else if l.tag != .name {
      throw expected("identifier", at: l.site)
    } else {
      return (nil, String(l.text))
    }
  }

  /// Parses a passing convention if the next token is a colon.
  private mutating func parseOptionalPassingConvention()
    throws -> Parsed<BindingPattern.Introducer>?
  {
    if take(.colon) != nil {
      return try parseOptional(BindingPattern.Introducer.self) ?? expected("passing convention")
    } else {
      return nil
    }
  }

  /// Parses the declaration of a struct.
  private mutating func parseStructDeclaration(
    in file: inout Program.SourceContainer
  ) throws -> StructDeclaration.ID {
    let introducer = try parse(.struct)
    let identifier = try parse(.name)
    let fields = try parseOptionalFieldList(in: &file)
    let interfaces = try parseOptionalInterfaceList(in: &file)
    var site = span(from: introducer)

    let members = try parseOptionalMemberList(in: &file)

    if let m = members.last {
      site = site.extended(upTo: file[m].site.end.index)
    }

    return file.insert(
      StructDeclaration(
        introducer: introducer,
        identifier: String(identifier.text),
        fields: fields,
        interfaces: interfaces,
        members: members,
        site: site))
  }

  /// Parses the declaration of a trait.
  private mutating func parseTraitDeclaration(
    in file: inout Program.SourceContainer
  ) throws -> TraitDeclaration.ID {
    let introducer = try parse(.trait)
    let identifier = try parse(.name)
    let interfaces = try parseOptionalInterfaceList(in: &file)
    var site = span(from: introducer)

    let members = try parseOptionalMemberList(in: &file)

    if let m = members.last {
      site = site.extended(upTo: file[m].site.end.index)
    }

    return file.insert(
      TraitDeclaration(
        introducer: introducer,
        identifier: String(identifier.text),
        interfaces: interfaces,
        members: members,
        site: site))
  }

  /// Parses a list of parameters if the next token is a left parenthesis.
  private mutating func parseOptionalFieldList(
    in file: inout Program.SourceContainer
  ) throws -> [FieldDeclaration.ID] {
    if next(is: .leftParenthesis) {
      return try parseFieldList(in: &file)
    } else {
      return []
    }
  }

  /// Parses a list of parameters.
  private mutating func parseFieldList(
    in file: inout Program.SourceContainer
  ) throws -> [FieldDeclaration.ID] {
    try inParentheses { (me) in
      let (ps, _) = try me.commaSeparated(until: Token.hasTag(.rightParenthesis)) { (me) in
        try me.parseFieldDeclaration(in: &file)
      }
      return ps
    }
  }

  /// Parses the declaration of a field in a struct declaration.
  private mutating func parseFieldDeclaration(
    in file: inout Program.SourceContainer
  ) throws -> FieldDeclaration.ID {
    let start = nextTokenStart()
    let name = try parse(.name)

    let site: SourceSpan
    let value = try parseOptionalInitializerExpression(in: &file)
    if let v = value {
      site = SourceSpan(from: start, to: file[v].site.end)
    } else {
      site = span(from: start)
    }

    return file.insert(
      FieldDeclaration(identifier: String(name.text), defaultValue: value, site: site))
  }

  /// Parses a list of interface constraints if the next token is `is`.
  private mutating func parseOptionalInterfaceList(
    in file: inout Program.SourceContainer
  ) throws -> [ExpressionIdentity] {
    if take(.is) != nil {
      var xs: [ExpressionIdentity] = []
      while true {
        try xs.append(parseCompoundExpression(in: &file))
        if take(operator: "&") == nil { break }
      }
      return xs
    } else {
      return []
    }
  }

  /// Parses a sequence of member functions if the next token is `where`.
  private mutating func parseOptionalMemberList(
    in file: inout Program.SourceContainer
  ) throws -> [FunctionDeclaration.ID] {
    if take(.where) != nil {
      return try indented { (me) in
        let ms = try me.parseMemberList(in: &file)
        if ms.isEmpty {
          throw me.expected("declaration")
        }
        return ms
      }
    } else {
      return []
    }
  }

  /// Parses a sequence of member functions.
  private mutating func parseMemberList(
    in file: inout Program.SourceContainer
  ) throws -> [FunctionDeclaration.ID] {
    var result: [FunctionDeclaration.ID] = []
    var end: SourcePosition?

    while let n = peek(), n.tag != .dedentation {
      // Ignore leading semicolons.
      discard(while: Token.hasTag(.semicolon))

      // Require a newline before consecutive members on the same line.
      if let e = end, (e == position) && !existNewline(from: e, to: position) {
        throw unseparatedConsecutiveLineStatements(at: .empty(at: position))
      }

      // Parse the next statement.
      let s = try parseFunctionDeclaration(in: &file)
      result.append(s)
      end = file[s].site.end
    }
    return result
  }

  /// Parses an initializer/default expression iff the next token is `=`.
  private mutating func parseOptionalInitializerExpression(
    in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity? {
    if take(.assign) != nil {
      return try parseExpression(in: &file)
    } else {
      return nil
    }
  }

  // MARK: Expressions

  /// Parses an expression.
  private mutating func parseExpression(
    in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity {
    try parseTypeTestExpression(in: &file)
  }

  /// Parses an expression possibly part of a type test.
  private mutating func parseTypeTestExpression(
    in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity {
    var head = try parseInfixExpression(in: &file)
    while take(.is) != nil {
      let rhs = try parseCompoundExpression(in: &file)
      let s = file[head].site.extended(upTo: file[rhs].site.end.index)
      head = .init(file.insert(TypeTest(lhs: head, rhs: rhs, site: s)))
    }
    return head
  }

  /// Parses the root of infix expression whose operator binds at least as tightly as `p`.
  private mutating func parseInfixExpression(
    minimumPrecedence p: PrecedenceGroup = .assignment, in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity {
    let start = position
    var l = try parsePrefixExpression(in: &file)

    // Can we parse a term operator?
    while p < .max {
      // Next token isn't considered an infix operator unless it is surrounded by whitespaces.
      guard
        next(is: .operator),
        existWhitespacesBeforeNextToken(),
        let (o, q) = try parseOptionalInfixOperator(notTighterThan: p)
      else { break }

      let r = try parseInfixExpression(minimumPrecedence: q.next, in: &file)
      let f = file.insert(
        NameExpression(
          qualification: l,
          name: .init(Name(identifier: String(o.text), notation: .infix), at: o.site),
          site: o.site))
      let s = SourceSpan(from: start, to: file[r].site.end)
      let a = [Labeled(label: nil, syntax: r)]
      let n = file.insert(Call(callee: .init(f), arguments: a, style: .parenthesized, site: s))
      l = .init(n)
    }

    // Done.
    return l
  }

  /// Parses an expression possibly prefixed by an operator.
  private mutating func parsePrefixExpression(
    in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity {
    // Is there a prefix operator?
    if let o = take(.operator) {
      if existWhitespacesBeforeNextToken() {
        throw Diagnostic(
          .error, "unary operator '\(o.text)' cannot be separated from its operand", at: o.site)
      }

      let e = try parsePostfixExpression(in: &file)
      let f = file.insert(
        NameExpression(
          qualification: e,
          name: .init(Name(identifier: String(o.text), notation: .prefix), at: o.site),
          site: o.site))
      let s = SourceSpan(from: o.site.start, to: file[e].site.end)
      let n = file.insert(Call(callee: .init(f), arguments: [], style: .parenthesized, site: s))
      return .init(n)
    }

    // No prefix operator; simply parse a compound expression.
    else {
      return try parsePostfixExpression(in: &file)
    }
  }

  /// Parses an expression possibly suffixed by an operator.
  private mutating func parsePostfixExpression(
    in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity {
    let e = try parseCompoundExpression(in: &file)

    // Is there a postfix operator?
    if next(is: .operator) && !existWhitespacesBeforeNextToken() {
      let o = take()!
      let f = file.insert(
        NameExpression(
          qualification: e,
          name: .init(Name(identifier: String(o.text), notation: .postfix), at: o.site),
          site: o.site))
      let s = SourceSpan(from: file[e].site.start, to: o.site.end)
      let n = file.insert(Call(callee: .init(f), arguments: [], style: .parenthesized, site: s))
      return .init(n)
    }

    // No postfix operator.
    else {
      return e
    }
  }

  /// Parses an expression made of one or more components.
  private mutating func parseCompoundExpression(
    in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity {
    let head = try parsePrimaryExpression(in: &file)
    return try appendCompounds(to: head, in: &file)
  }

  /// Parses the arguments and nominal components that can be affixed to `head`.
  private mutating func appendCompounds(
    to head: ExpressionIdentity, in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity {
    var h = head
    while true {
      // Qualifications and bracketed calls bind more tightly than mutation markers.
      if let n = try appendNominalComponent(to: h, in: &file) {
        h = n
      } else if let n = try appendArguments(to: h, in: &file) {
        h = n
      } else {
        break
      }
    }
    return h
  }

  /// If the next token is a left parenthesis or bracket, parses an argument list and returns a
  /// call applying `head`. Otherwise, returns `nil`.
  private mutating func appendArguments(
    to head: ExpressionIdentity, in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity? {
    // Argument list must start on the same line.
    guard let next = peek(), !existNewline(from: position, to: next.site.start) else { return nil }

    // Determine the style of the call.
    let style: Call.Style
    switch next.tag {
    case .leftParenthesis:
      style = .parenthesized
    case .leftBracket:
      style = .bracketed
    default:
      return nil
    }

    // Parse the arguments.
    let (l, r) = style.delimiters
    let (a, _) = try between((l, r)) { (me) in
      try me.parseLabeledExpressionList(until: r, in: &file)
    }

    let s = file[head].site.extended(upTo: position.index)
    let m = file.insert(Call(callee: head, arguments: a, style: style, site: s))
    return .init(m)
  }

  /// If the next token is `.`, parses a nominal component and returns a name expression qualified
  /// by `head`. Otherwise, returns `nil`.
  private mutating func appendNominalComponent(
    to head: ExpressionIdentity, in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity? {
    if take(.dot) == nil { return nil }
    let n = try parseQualifiedName()
    let s = span(from: file[head].site.start)
    let m = file.insert(NameExpression(qualification: head, name: n, site: s))
    return .init(m)
  }

  /// Parses a primary expression.
  private mutating func parsePrimaryExpression(
    in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity {
    let head = try peek() ?? expected("expression")
    switch head.tag {
    case .leftParenthesis:
      return try parseTupleOrParenthesizedExpression(in: &file)
    case .leftBracket:
      return try parseArrayOrDictionaryLiteral(in: &file)
    case .booleanLiteral:
      return try .init(parseBooleanLiteral(in: &file))
    case .integerLiteral:
      return try .init(parseIntegerLiteral(in: &file))
    case .floatingPointLiteral:
      return try .init(parseFloatingPointLiteral(in: &file))
    case .stringLiteral:
      return try .init(parseStringLiteral(in: &file))
    case .backslash:
      return try .init(parseLambda(in: &file))
    case .if:
      return try .init(parseConditionalExpression(in: &file))
    case .match:
      return try .init(parseMatchExpression(in: &file))
    case .name:
      return try .init(parseUnqualifiedNameExpression(in: &file))
    case .try:
      return try .init(parseTryExpression(in: &file))
    default:
      throw unexpected(head)
    }
  }

  /// Parses a tuple literal or a parenthesized expression.
  private mutating func parseTupleOrParenthesizedExpression(
    in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity {
    let start = nextTokenStart()
    let (elements, lastComma) = try parseParenthesizedLabeledExpressionList(in: &file)

    if (elements.count == 1) && (elements[0].label == nil) && (lastComma == nil) {
      return elements[0].syntax
    } else {
      return .init(file.insert(TupleLiteral(elements: elements, site: span(from: start))))
    }
  }

  /// Parses an array or a dictionary literal.
  private mutating func parseArrayOrDictionaryLiteral(
    in file: inout Program.SourceContainer
  ) throws -> ExpressionIdentity {
    let head = try parse(.leftBracket)

    // Empty array literal?
    if let e = take(.rightBracket) {
      let s = SourceSpan(from: head.site.start, to: e.site.end)
      return .init(file.insert(ArrayLiteral(elements: [], site: s)))
    }

    // Empty map literal?
    else if take(.colon) != nil {
      let e = try parse(.rightBracket)
      let s = SourceSpan(from: head.site.start, to: e.site.end)
      return .init(file.insert(DictionaryLiteral(elements: [], site: s)))
    }

    // In any case, there should be an expression.
    let first = try parseExpression(in: &file)

    // If the next token is a colon, we're parsing a dictionary literal.
    if take(.colon) != nil {
      let value = try parseExpression(in: &file)
      var elements: [DictionaryLiteral.Entry] = [.init(key: first, value: value)]

      if take(.comma) != nil {
        let (xs, _) = try commaSeparated(until: Token.hasTag(.rightBracket)) { (me) in
          let k = try me.parseExpression(in: &file)
          try me.discardOrThrow(.colon)
          let v = try me.parseExpression(in: &file)
          return DictionaryLiteral.Entry(key: k, value: v)
        }
        elements.append(contentsOf: xs)
      }

      let e = try parse(.rightBracket)
      let s = SourceSpan(from: head.site.start, to: e.site.end)
      return .init(file.insert(DictionaryLiteral(elements: elements, site: s)))
    }

    // Otherwise, we're parsing an array literal.
    else {
      var elements = [first]

      if take(.comma) != nil {
        let (xs, _) = try commaSeparated(until: Token.hasTag(.rightBracket)) { (me) in
          try me.parseExpression(in: &file)
        }
        elements.append(contentsOf: xs)
      }

      let e = try parse(.rightBracket)
      let s = SourceSpan(from: head.site.start, to: e.site.end)
      return .init(file.insert(ArrayLiteral(elements: elements, site: s)))
    }
  }

  /// Parses a Boolean literal.
  private mutating func parseBooleanLiteral(
    in file: inout Program.SourceContainer
  ) throws -> BooleanLiteral.ID {
    let value = try parse(.booleanLiteral)
    return file.insert(BooleanLiteral(site: value.site))
  }

  /// Parses an integer literal.
  private mutating func parseIntegerLiteral(
    in file: inout Program.SourceContainer
  ) throws -> IntegerLiteral.ID {
    let value = try parse(.integerLiteral)
    return file.insert(IntegerLiteral(site: value.site))
  }

  /// Parses a floating-point literal.
  private mutating func parseFloatingPointLiteral(
    in file: inout Program.SourceContainer
  ) throws -> FloatingPointLiteral.ID {
    let value = try parse(.floatingPointLiteral)
    return file.insert(FloatingPointLiteral(site: value.site))
  }

  /// Parses a string literal.
  private mutating func parseStringLiteral(
    in file: inout Program.SourceContainer
  ) throws -> StringLiteral.ID {
    let value = try parse(.stringLiteral)
    return file.insert(StringLiteral(site: value.site))
  }

  /// Parses a lambda expression.
  private mutating func parseLambda(
    in file: inout Program.SourceContainer
  ) throws -> Lambda.ID {
    let introducer = try parse(.backslash)
    let parameters = try parseParameterList(in: &file)
    try discardOrThrow(.in)
    let body = try parseBlockBody(in: &file)

    let site = introducer.site.extended(upTo: file[body.last!].site.end.index)
    return file.insert(
      Lambda(introducer: introducer, parameters: parameters, body: body, site: site))
  }

  /// Parses a conditional expression.
  private mutating func parseConditionalExpression(
    in file: inout Program.SourceContainer
  ) throws -> ConditionalExpression.ID {
    let introducer = try parse(.if)
    let conditions = try parseConditionList(in: &file)
    let success = try parseBlock(introducedBy: .do, in: &file)
    let failure: ElseIdentity? = try take(.else).map { (e) in
      if next(is: .if) {
        return try .init(parseConditionalExpression(in: &file))
      } else {
        let b = try parseBlockBody(in: &file)
        let s = e.site.extended(upTo: file[b.last!].site.end.index)
        return .init(file.insert(Block(introducer: e, statements: b, site: s)))
      }
    }

    let end = failure.map({ (e) in file[e].site.end }) ?? file[success].site.end
    let site = SourceSpan(from: introducer.site.start, to: end)

    return file.insert(
      ConditionalExpression(
        introducer: introducer,
        conditions: conditions,
        success: success,
        failure: failure,
        site: site))
  }

  /// Parses a non-empty comma-separated list of conditions.
  private mutating func parseConditionList(
    in file: inout Program.SourceContainer
  ) throws -> [ConditionIdentity] {
    var conditions = try [parseCondition(in: &file)]
    while take(.comma) != nil {
      try conditions.append(parseCondition(in: &file))
    }
    return conditions
  }

  /// Parses a single item in a condition.
  private mutating func parseCondition(
    in file: inout Program.SourceContainer
  ) throws -> ConditionIdentity {
    // Is it a match condition?
    if let i = take(.case) {
      let p = try parsePattern(in: &file)
      try discardOrThrow(.assign)
      let e = try parseExpression(in: &file)
      let s = i.site.extended(upTo: file[e].site.end.index)
      let c = file.insert(MatchCondition(introducer: i, pattern: p, scrutinee: e, site: s))
      return .init(c)
    }

    // Defaults to a expression.
    else {
      return try .init(parseExpression(in: &file))
    }
  }

  /// Parses a match expression.
  private mutating func parseMatchExpression(
    in file: inout Program.SourceContainer
  ) throws -> MatchExpression.ID {
    let introducer = try parse(.match)
    let scrutinee = try parseExpression(in: &file)
    let branches = try parseMatchCaseList(in: &file)

    let site = introducer.site.extended(upTo: file[branches.last!].site.end.index)
    return file.insert(
      MatchExpression(scrutinee: scrutinee, branches: branches, site: site))
  }

  /// Parses a sequence of match cases.
  private mutating func parseMatchCaseList(
    in file: inout Program.SourceContainer
  ) throws -> [MatchCase.ID] {
    try indented { (me) in
      var cases: [MatchCase.ID] = []
      while !me.next(is: .dedentation) {
        try cases.append(me.parseMatchCase(in: &file))
      }
      if cases.isEmpty {
        throw me.expected("case")
      }
      return cases
    }
  }

  /// Parses a match case.
  private mutating func parseMatchCase(
    in file: inout Program.SourceContainer
  ) throws -> MatchCase.ID {
    let introducer = try parse(.case)
    let pattern = try parsePattern(in: &file)
    try discardOrThrow(.do)
    let body = try parseBlockBody(in: &file)

    let site = introducer.site.extended(upTo: file[body.last!].site.end.index)
    return file.insert(
      MatchCase(introducer: introducer, pattern: pattern, body: body, site: site))
  }

  /// Parses an unqualified name expression.
  private mutating func parseUnqualifiedNameExpression(
    in file: inout Program.SourceContainer
  ) throws -> NameExpression.ID {
    let n = try parseName()
    return file.insert(NameExpression(qualification: nil, name: n, site: n.site))
  }

  /// Parses a try-expression.
  private mutating func parseTryExpression(
    in file: inout Program.SourceContainer
  ) throws -> TryExpression.ID {
    let introducer = try parse(.try)
    let statements = try parseBlockBody(in: &file)
    let s0 = introducer.site.extended(upTo: file[statements.last!].site.end.index)
    let body = file.insert(
      Block(introducer: introducer, statements: statements, site: s0))

    try discardOrThrow(.catch)
    let handlers = try parseMatchCaseList(in: &file)

    let s1 = introducer.site.extended(upTo: file[handlers.last!].site.end.index)
    return file.insert(
      TryExpression(body: body, handlers: handlers, site: s1))
  }

  /// Parses a parenthesized comma-separated list of labeled patterns.
  private mutating func parseParenthesizedLabeledExpressionList(
    in file: inout Program.SourceContainer
  ) throws -> ([Labeled<ExpressionIdentity>], lastComma: Token?) {
    try inParentheses { (me) in
      try me.parseLabeledExpressionList(until: .rightParenthesis, in: &file)
    }
  }

  /// Parses a comma-separated list of labeled patterns.
  private mutating func parseLabeledExpressionList(
    until rightDelimiter: Token.Tag, in file: inout Program.SourceContainer
  ) throws -> ([Labeled<ExpressionIdentity>], lastComma: Token?) {
    try labeledList(until: rightDelimiter) { (me) in
      try me.parseExpression(in: &file)
    }
  }

  // MARK: Patterns

  /// Parses a pattern.
  private mutating func parsePattern(
    in file: inout Program.SourceContainer
  ) throws -> PatternIdentity {
    var head = try parsePrimaryPattern(in: &file)
    while take(.as) != nil {
      let rhs = try parseCompoundExpression(in: &file)
      let s = file[head].site.extended(upTo: file[rhs].site.end.index)
      head = .init(file.insert(TypePattern(lhs: head, rhs: rhs, site: s)))
    }
    return head
  }

  /// Parses a primary expression.
  private mutating func parsePrimaryPattern(
    in file: inout Program.SourceContainer
  ) throws -> PatternIdentity {
    let head = try peek() ?? expected("pattern")
    switch head.tag {
    case .leftParenthesis:
      return try parseTupleOrParenthesizedPattern(in: &file)
    case .name:
      return try parseNameOrExtractorPattern(in: &file)
    case .dot:
      return try .init(parseExtractorPattern(in: &file))
    case .var, .let, .inout:
      return try .init(parseBindingPattern(in: &file))
    case .underscore:
      return try .init(parseWildcard(in: &file))
    default:
      return try .init(parseExpression(in: &file))
    }
  }

  /// Parses a tuple pattern or a parenthesized pattern.
  private mutating func parseTupleOrParenthesizedPattern(
    in file: inout Program.SourceContainer
  ) throws -> PatternIdentity {
    let start = nextTokenStart()
    let (elements, lastComma) = try parseParenthesizedLabeledPatternList(in: &file)

    if (elements.count == 1) && (elements[0].label == nil) && (lastComma == nil) {
      return elements[0].syntax
    } else {
      return .init(file.insert(TuplePattern(elements: elements, site: span(from: start))))
    }
  }

  /// Parses a compound name expression or a variable declaration, depending on context.
  private mutating func parseNameOrExtractorPattern(
    in file: inout Program.SourceContainer
  ) throws -> PatternIdentity {
    let n = try parse(.name)

    if isParsingBindingSubpattern {
      return .init(
        file.insert(VariableDeclaration(identifier: String(n.text), site: n.site)))
    } else {
      return .init(
        file.insert(NameExpression(qualification: nil, name: .init(name: n), site: n.site)))
    }
  }

  /// Parses an extractor pattern.
  private mutating func parseExtractorPattern(
    in file: inout Program.SourceContainer
  ) throws -> ExtractorPattern.ID {
    let introducer = try parse(.dot)
    var head = try ExpressionIdentity(parseUnqualifiedNameExpression(in: &file))

    // Handle qualifications.
    while let n = try appendNominalComponent(to: head, in: &file) {
      head = n
    }

    // Extractor arguments must be on the same line.
    if existWhitespacesBeforeNextToken() { throw expected(.leftParenthesis) }

    let (xs, _) = try parseParenthesizedLabeledPatternList(in: &file)
    return file.insert(
      ExtractorPattern(extractor: head, elements: xs, site: span(from: introducer)))
  }

  /// Parses a binding pattern.
  private mutating func parseBindingPattern(
    in file: inout Program.SourceContainer
  ) throws -> BindingPattern.ID {
    let introducer = try parseBindingIntroducer()

    // Modify the context of the parser to interpret identifiers as variable declarations.
    isParsingBindingSubpattern = true
    defer { isParsingBindingSubpattern = false }

    let pattern = try parsePattern(in: &file)

    let site = introducer.site.extended(upTo: file[pattern].site.end.index)
    return file.insert(
      BindingPattern(introducer: introducer, pattern: pattern, site: site))
  }

  /// Parses a binding introducer.
  private mutating func parseBindingIntroducer() throws -> Parsed<BindingPattern.Introducer> {
    try parseOptional(BindingPattern.Introducer.self) ?? expected("binding introducer")
  }

  /// Parses a wildcard.
  private mutating func parseWildcard(
    in file: inout Program.SourceContainer
  ) throws -> Wildcard.ID {
    let w = try parse(.underscore)
    return file.insert(Wildcard(site: w.site))
  }

  /// Parses a parenthesized comma-separated list of labeled patterns.
  private mutating func parseParenthesizedLabeledPatternList(
    in file: inout Program.SourceContainer
  ) throws -> ([Labeled<PatternIdentity>], lastComma: Token?) {
    try inParentheses { (me) in
      try me.parseLabeledPatternList(until: .rightParenthesis, in: &file)
    }
  }

  /// Parses a comma-separated list of labeled patterns.
  private mutating func parseLabeledPatternList(
    until rightDelimiter: Token.Tag, in file: inout Program.SourceContainer
  ) throws -> ([Labeled<PatternIdentity>], lastComma: Token?) {
    try labeledList(until: rightDelimiter) { (me) in
      try me.parsePattern(in: &file)
    }
  }

  // MARK: Statements

  /// Parses a sequence of statements.
  private mutating func parseStatementList(
    in file: inout Program.SourceContainer
  ) throws -> [StatementIdentity] {
    var result: [StatementIdentity] = []
    var end: SourcePosition?

    while let n = peek(), n.tag != .dedentation {
      // Ignore leading semicolons.
      discard(while: Token.hasTag(.semicolon))

      // Require a newline before consecutive statements on the same line.
      let n = nextTokenStart()
      if let e = end, !existNewline(from: e, to: n) {
        throw unseparatedConsecutiveLineStatements(at: .empty(at: position))
      }

      // Parse the next statement.
      let s = try parseStatement(in: &file)
      result.append(s)
      end = file[s].site.end
    }
    return result
  }

  /// Parses a statement.
  private mutating func parseStatement(
    in file: inout Program.SourceContainer
  ) throws -> StatementIdentity {
    let head = try peek() ?? expected("statement")
    switch head.tag {
    case .break:
      return try .init(parseBreak(in: &file))
    case .continue:
      return try .init(parseContinue(in: &file))
    case .fun, .subscript:
      return try .init(parseFunctionDeclaration(in: &file))
    case .defer:
      return try .init(parseBlock(introducedBy: .defer, in: &file))
    case .do:
      return try .init(parseBlock(introducedBy: .do, in: &file))
    case .for:
      return try .init(parseFor(in: &file))
    case .return:
      return try .init(parseReturn(in: &file))
    case .throw:
      return try .init(parseThrow(in: &file))
    case .var, .let, .inout:
      return try .init(parseBindingDeclaration(as: .unconditional, in: &file))
    case .while:
      return try .init(parseWhile(in: &file))
    default:
      return try parseAssignmentOrExpression(in: &file)
    }
  }

  /// Parses a break statement.
  private mutating func parseBreak(
    in file: inout Program.SourceContainer
  ) throws -> Break.ID {
    try file.insert(Break(introducer: parse(.break)))
  }

  /// Parses a continue statement.
  private mutating func parseContinue(
    in file: inout Program.SourceContainer
  ) throws -> Continue.ID {
    try file.insert(Continue(introducer: parse(.continue)))
  }

  /// Parses a block introduced by a token having the given tag.
  private mutating func parseBlock(
    introducedBy k: Token.Tag, in file: inout Program.SourceContainer
  ) throws -> Block.ID {
    let introducer = try parse(k)
    let statements = try parseBlockBody(in: &file)

    let site = introducer.site.extended(upTo: file[statements.last!].site.end.index)
    return file.insert(Block(introducer: introducer, statements: statements, site: site))
  }

  /// Parses the body of block after its introduction token.
  ///
  /// The body is parsed as an indented sequence of statement if the next token is an indentation.
  /// Otherwise, it is parsed as a single expression.
  ///
  /// - Postcondition: The returned array is not empty.
  private mutating func parseBlockBody(
    in file: inout Program.SourceContainer
  ) throws -> [StatementIdentity] {
    // Parses with indentation.
    if next(is: .indentation) {
      return try indented { (me) in
        let ss = try me.parseStatementList(in: &file)
        if ss.isEmpty {
          throw me.expected("statement")
        }
        return ss
      }
    }

    // Parses the statement inline.
    else {
      return [try parseStatement(in: &file)]
    }
  }

  /// Parses a for loop.
  private mutating func parseFor(
    in file: inout Program.SourceContainer
  ) throws -> For.ID {
    let introducer = try parse(.for)
    let pattern = try parsePattern(in: &file)
    try discardOrThrow(.in)
    let sequence = try parseExpression(in: &file)
    let filters = try parseOptionalFilterList(in: &file)
    let body = try parseBlock(introducedBy: .do, in: &file)

    let site = introducer.site.extended(upTo: file[body].site.end.index)
    return file.insert(
      For(
        introducer: introducer,
        pattern: pattern,
        sequence: sequence,
        filters: filters,
        body: body,
        site: site))
  }

  /// Parses a list of loop filters if the next token is `where`.
  private mutating func parseOptionalFilterList(
    in file: inout Program.SourceContainer
  ) throws -> [ConditionIdentity] {
    if take(.where) != nil {
      return try parseConditionList(in: &file)
    } else {
      return []
    }
  }

  /// Parses a return statement.
  private mutating func parseReturn(
    in file: inout Program.SourceContainer
  ) throws -> Return.ID {
    let introducer = try parse(.return)

    if !existNewlineBeforeNextToken() {
      let v = try parseExpression(in: &file)
      let s = introducer.site.extended(upTo: file[v].site.end.index)
      return file.insert(Return(introducer: introducer, value: v, site: s))
    } else {
      return file.insert(Return(introducer: introducer, value: nil, site: introducer.site))
    }
  }

  /// Parses a throw statement.
  private mutating func parseThrow(
    in file: inout Program.SourceContainer
  ) throws -> Throw.ID {
    let introducer = try parse(.return)
    let value = try parseExpression(in: &file)

    let site = introducer.site.extended(upTo: file[value].site.end.index)
    return file.insert(Throw(introducer: introducer, value: value, site: site))
  }

  /// Parses a while loop.
  private mutating func parseWhile(
    in file: inout Program.SourceContainer
  ) throws -> While.ID {
    let introducer = try parse(.while)
    let conditions = try parseConditionList(in: &file)
    let body = try parseBlock(introducedBy: .do, in: &file)

    let site = introducer.site.extended(upTo: file[body].site.end.index)
    return file.insert(
      While(introducer: introducer, conditions: conditions, body: body, site: site))
  }

  /// Parses an assignment or an expression.
  private mutating func parseAssignmentOrExpression(
    in file: inout Program.SourceContainer
  ) throws -> StatementIdentity {
    let start = nextTokenStart()
    let lhs = try parseExpression(in: &file)
    if take(.assign) != nil {
      let rhs = try parseExpression(in: &file)
      let s = SourceSpan(from: start, to: file[rhs].site.end)
      return .init(file.insert(Assignment(lhs: lhs, rhs: rhs, site: s)))
    } else {
      return .init(lhs)
    }
  }

  // MARK: Identifiers

  /// Parses a name.
  private mutating func parseName() throws -> Parsed<Name> {
    // Simple name?
    if let i = take(.name) {
      return .init(name: i)
    }

    // Operator name?
    else if next(satisfies: \.isOperatorNotation) {
      let (n, o) = try parseOperatorName()
      return .init(Name(identifier: String(o.text), notation: n), at: o.site)
    }

    // We're out of luck.
    else {
      throw expected("identifier")
    }
  }

  /// Parses the name of a function or subscript.
  private mutating func parseMemberName() throws -> Parsed<Name> {
    if let i = take(.underscore) {
      return .init(name: i)
    } else {
      return try parseName()
    }
  }

  /// Parses the name of a member after some qualification.
  private mutating func parseQualifiedName() throws -> Parsed<Name> {
    if let i = take(if: \.isArgumentLabel) {
      return .init(name: i)
    } else {
      return try parseName()
    }
  }

  /// Parses the name of an operator.
  private mutating func parseOperatorName() throws -> (OperatorNotation, Token) {
    let n = try parseOptional(OperatorNotation.self) ?? expected("operator notation")
    let o = try parse(.operator)
    return (n.value, o)
  }

  /// Parses an infix operator and returns the region of the file from which it has been extracted
  /// iff it binds less than or as tightly as `p`.
  private mutating func parseOptionalInfixOperator(
    notTighterThan p: PrecedenceGroup
  ) throws -> (Token, PrecedenceGroup)? {
    var backup = self
    let o = try parse(.operator)
    let q = PrecedenceGroup(containing: o.text)
    if existWhitespacesBeforeNextToken() && ((p < q) || ((p == q) && !q.isRightAssociative)) {
      return (o, q)
    } else {
      swap(&self, &backup)
      return nil
    }
  }

  // MARK: Combinators

  /// Parses a list of labeled syntax.
  private mutating func labeledList<T: SyntaxIdentity>(
    until rightDelimiter: Token.Tag, _ parse: (inout Self) throws -> T
  ) throws -> ([Labeled<T>], lastComma: Token?) {
    try commaSeparated(until: Token.hasTag(rightDelimiter)) { (me) in
      try me.labeled(parse)
    }
  }

  /// Parses an instance of `T` with an optional label.
  private mutating func labeled<T: SyntaxIdentity>(
    _ parse: (inout Self) throws -> T
  ) rethrows -> Labeled<T> {
    var backup = self

    // Can we parse a label?
    if let l = take(if: \.isArgumentLabel) {
      if take(.colon) != nil {
        let v = try parse(&self)
        return .init(label: .init(String(l.text), at: l.site), syntax: v)
      } else {
        swap(&self, &backup)
      }
    }

    // No label
    let v = try parse(&self)
    return .init(label: nil, syntax: v)
  }

  /// Parses an instance of `T` enclosed in `delimiters`.
  private mutating func between<T>(
    _ delimiters: (left: Token.Tag, right: Token.Tag),
    _ parse: (inout Self) throws -> T
  ) throws -> T {
    try discardOrThrow(delimiters.left)
    let contents = try parse(&self)
    try discardOrThrow(delimiters.right)
    return contents
  }

  /// Parses an instance of `T` enclosed in parentheses.
  private mutating func inParentheses<T>(_ parse: (inout Self) throws -> T) throws -> T {
    try between((.leftParenthesis, .rightParenthesis), parse)
  }

  /// Parses an instance of `T`, which is indentend relative to the current indentation.
  private mutating func indented<T>(_ parse: (inout Self) throws -> T) throws -> T {
    let i = take(while: Token.hasTag(.indentation))
    let s = try i.first ?? expected("indentation")
    let e = i.last ?? s

    // The specific character used for indentation is irrelevant.
    indententation.append(s.site.extended(toCover: e.site))
    let contents = try parse(&self)
    for _ in 0 ..< i.count {
      _ = try take(.dedentation) ?? insufficientDedentation()
    }
    indententation.removeLast()

    return contents
  }

  /// Parses a list of instances of `T` separated by colons.
  private mutating func commaSeparated<T>(
    until isRightDelimiter: (Token) -> Bool, _ parse: (inout Self) throws -> T
  ) throws -> ([T], lastComma: Token?) {
    var xs: [T] = []
    var trailingComma: Token? = nil
    while let head = peek() {
      if isRightDelimiter(head) { break }
      trailingComma = nil
      try xs.append(parse(&self))
      if let c = take(.comma) { trailingComma = c }
    }
    return (xs, trailingComma)
  }

  /// Parses a token with the given tag.
  private mutating func parse(_ k: Token.Tag) throws -> Token {
    try take(k) ?? expected(k)
  }

  /// Parses an instance of `T` if it can be constructed from the next token.
  private mutating func parseOptional<T: ExpressibleByTokenTag>(
    _: T.Type
  ) -> Parsed<T>? {
    if let h = peek(), let v = T(tag: h.tag) {
      discard()
      return .init(v, at: h.site)
    } else {
      return nil
    }
  }

  // MARK: Helpers

  /// Returns the start position of the next token or the current position if the stream is empty.
  private mutating func nextTokenStart() -> SourcePosition {
    peek()?.site.start ?? position
  }

  /// Returns a source span from `s` to the current position.
  ///
  /// Do not use this method to determine the source span of a syntax tree if the last parsed
  /// element may cover dedentation tokens.
  private func span(from s: SourcePosition) -> SourceSpan {
    .init(s.index ..< position.index, in: tokens.source)
  }

  /// Returns a source span from the first position of `t` to the current position.
  ///
  /// Do not use this method to determine the source span of a syntax tree if the last parsed
  /// element may cover dedentation tokens.
  private func span(from t: Token) -> SourceSpan {
    .init(t.site.start.index ..< position.index, in: tokens.source)
  }

  /// Returns `true` iff there is a newline in the text from `p` up to but not including `q`.
  private func existNewline(from p: SourcePosition, to q: SourcePosition) -> Bool {
    var i = p.index
    while i != q.index {
      if tokens.source[i].isNewline { return true }
      i = tokens.source.index(after: i)
    }
    return false
  }

  /// Returns `true` iff there is a newline before the next token or the character stream is empty.
  private mutating func existNewlineBeforeNextToken() -> Bool {
    if let n = peek() {
      return existNewline(from: position, to: n.site.start)
    } else {
      return true
    }
  }

  /// Returns `true` iff there is a whitespace in the text from `p` up to but not including `q`.
  private func existWhitespace(from p: SourcePosition, to q: SourcePosition) -> Bool {
    var i = p.index
    while i != q.index {
      if tokens.source[i].isWhitespace { return true }
      i = tokens.source.index(after: i)
    }
    return false
  }

  /// Returns `true` iff there is a whitespace before the next token.
  private mutating func existWhitespacesBeforeNextToken() -> Bool {
    if let n = peek() {
      return existWhitespace(from: position, to: n.site.start)
    } else {
      return false
    }
  }

  /// Returns `true` iff the next token has tag `k`, without consuming that token.
  private mutating func next(is k: Token.Tag) -> Bool {
    peek()?.tag == k
  }

  /// Returns `true` iff the next token satisfies `predicate`, without consuming that token.
  private mutating func next(satisfies predicate: (Token) -> Bool) -> Bool {
    peek().map(predicate) ?? false
  }

  /// Returns the next token without consuming it.
  private mutating func peek() -> Token? {
    if lookahead == nil { lookahead = tokens.next() }
    return lookahead
  }

  /// Consumes and returns the next token.
  private mutating func take() -> Token? {
    let next = lookahead.take() ?? tokens.next()
    position = next?.site.end ?? .init(tokens.source.endIndex, in: tokens.source)
    return next
  }

  /// Consumes and returns the next token iff it has tag `k`.
  private mutating func take(_ k: Token.Tag) -> Token? {
    next(is: k) ? take() : nil
  }

  /// Consumes and returns the next token iff it satisifies `predicate`.
  private mutating func take(if predicate: (Token) -> Bool) -> Token? {
    next(satisfies: predicate) ? take() : nil
  }

  /// Consumes and returns the next token iff it is a contextual keyword with the given value.
  private mutating func take(contextual s: String) -> Token? {
    take(if: { (t) in (t.tag == .name) && (t.text == s) })
  }

  /// Consumes and returns the next operator iff it has the given value.
  private mutating func take(operator s: String) -> Token? {
    take(if: { (t) in (t.tag == .operator) && (t.text == s) })
  }

  /// Consumes and returns the longest sequence of tokens satisfying `predicate`.
  private mutating func take(while predicate: (Token) -> Bool) -> [Token] {
    var result: [Token] = []
    while let t = take(if: predicate) {
      result.append(t)
    }
    return result
  }

  /// Consumes and returns the next token iff its tag is in `ks`.
  private mutating func take<T: Collection<Token.Tag>>(oneOf ks: T) -> Token? {
    take(if: { (t) in ks.contains(t.tag) })
  }

  /// Discards a single token.
  private mutating func discard() {
    _ = take()
  }

  /// Discards tokens until `predicate` isn't satisfied or all the input has been consumed.
  private mutating func discard(while predicate: (Token) -> Bool) {
    while next(satisfies: predicate) { discard() }
  }

  /// Discards a token with the given tag or throws an error.
  private mutating func discardOrThrow(_ k: Token.Tag) throws {
    _ = try parse(k)
  }

  /// Returns a parse error reporting that `s` was expected at the current position.
  private func expected(_ s: String) -> Diagnostic {
    expected(s, at: .empty(at: position))
  }

  /// Returns a parse error reporting that `s` was expected at `site`.
  private func expected(_ s: String, at site: SourceSpan) -> Diagnostic {
    .init(.error, "expected \(s)", at: site)
  }

  /// Returns a parse error reporting that `t` was expected at the current position.
  private func expected(_ t: Token.Tag) -> Diagnostic {
    expected(String(describing: t), at: .empty(at: position))
  }

  /// Returns a parse error reporting that `t` was unexpected.
  private func unexpected(_ t: Token) -> Diagnostic {
    .init(.error, "unexpected token '\(t.tag)'", at: t.site)
  }

  /// Returns a parse error diagnosing illegal consecutive statements on a line at `site`.
  private func unseparatedConsecutiveLineStatements(at site: SourceSpan) -> Diagnostic {
    .init(.error, "consecutive statements on a line must be separated by ';'", at: site)
  }

  /// Returns a parse error reporting insufficient dedentation at the current position.
  ///
  /// - Requires: `self.indententation` is not empty.
  private func insufficientDedentation() -> Diagnostic {
    let i = indententation.last!
    let s = describeIndentationString(at: i)
    return .init(
      .error, "dedendation does not match the current identation", at: .empty(at: position),
      notes: [
        .init(.note, "indentation of the current line is: \(s)", at: .empty(at: i.start))
      ])
  }

  private func describeIndentationString(at site: SourceSpan) -> String {
    var subsequences: [(symbol: Character, count: Int)] = []
    for c in tokens.source[site] {
      if c == subsequences.last?.symbol {
        subsequences[subsequences.count - 1].count += 1
      } else {
        subsequences.append((c, 1))
      }
    }

    return subsequences.reduce(into: "") { (result, s) in
      switch s.symbol {
      case " ":
        result.append("\(s.count) space(s)")
      case "\t":
        result.append("\(s.count) tab(s)")
      default:
        let unicode = s.symbol.unicodeScalars.reduce(into: "") { (us, u) in
          us.write("\\u{\(String(u.value, radix: 16))}")
        }
        result.append("\(s.count) \(unicode)")
      }
    }
  }

}

/// A type whose instances can be created from a single token.
private protocol ExpressibleByTokenTag {

  /// Creates an instance from `tag`.
  init?(tag: Token.Tag)

}

extension BindingPattern.Introducer: ExpressibleByTokenTag {

  fileprivate init?(tag: Token.Tag) {
    switch tag {
    case .inout:
      self = .inout
    case .let:
      self = .let
    case .var:
      self = .var
    default:
      return nil
    }
  }

}

extension OperatorNotation: ExpressibleByTokenTag {

  fileprivate init?(tag: Token.Tag) {
    switch tag {
    case .infix:
      self = .infix
    case .postfix:
      self = .postfix
    case .prefix:
      self = .prefix
    default:
      return nil
    }
  }

}

extension Parsed<Name> {

  /// Creates an instance with the value of `t`.
  fileprivate init(name t: Token) {
    self.init(Name(identifier: String(t.text)), at: t.site)
  }

}

extension Call.Style {

  /// The tags of the tokens surrounding arguments to a call in the style of `self`.
  fileprivate var delimiters: (left: Token.Tag, right: Token.Tag) {
    switch self {
    case .parenthesized:
      return (.leftParenthesis, .rightParenthesis)
    case .bracketed:
      return (.leftBracket, .rightBracket)
    }
  }

}
