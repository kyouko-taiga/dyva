import Utilities

/// The lowering of a Dyva module into IR.
public struct Lowerer {

  /// The current insertion context.
  private var insertionContext: InsertionContext

  /// The module being lowered.
  private var module: Module!

  /// Creates an instance.
  public init() {
    self.insertionContext = .init()
    self.module = nil
  }

  /// Lowers `module` to IR.
  public mutating func visit(_ module: inout Module) {
    self.module = consume module
    lowerRoots()
    module = self.module.sink()
  }

  /// Lowers the roots of `module`'s syntax tree.
  private mutating func lowerRoots() {
    assert(module.functions.isEmpty)

    // If `m` is the entry, then the whole module is the definition of a function.
    if module.isMain {
      let f = module.addFunction(name: .main, labels: [])

      insertionContext.function = module[f]
      insertionContext.point = .end(of: insertionContext.function!.appendBlock(parameterCount: 0))
      push(Frame(scope: .init(module: module.identity), locals: [:]))
      for s in module.roots {
        assert(module.isStatement(s), "ill-formed syntax tree")
        lower(StatementIdentity(uncheckedFrom: s))
      }
      pop()
      module[f] = insertionContext.function.sink()
    }

    // Otherwise, `m` is a collection of top-level declarations.
    else { todo() }
  }

  // MARK: Declarations

  /// Lowers `d` to IR.
  private mutating func lower(_ d: DeclarationIdentity) {
    switch module.tag(of: d) {
    case BindingDeclaration.self:
      lower(module.castUnchecked(d, to: BindingDeclaration.self))
    case FunctionDeclaration.self:
      lower(module.castUnchecked(d, to: FunctionDeclaration.self))
    default:
      module.unexpected(d)
    }
  }

  /// Lowers `d` to IR.
  private mutating func lower(_ d: BindingDeclaration.ID) {
    let storage = _alloc(at: module[d].site)

    if let e = module[d].initializer {
      module.visit(pattern: module[d].pattern, with: e, at: []) { (path, p, s) in
        let anchor = module[s].site

        // Nothing to declare if the pattern is a wildcard-
        if module.tag(of: p) == Wildcard.self {
          lower(s)
        } else {
          var w = storage
          for i in path { w = _member(.index(i), of: w, at: anchor) }
          let v = lower(s)
          _store(v, to: w, at: anchor)

          declareBindings(in: p, relativeTo: w)
        }
      }
    }

    _ = storage
  }

  /// Lowers `d` to IR.
  private mutating func lower(_ d: FunctionDeclaration.ID) {
    // Has the function been lowered already?
    if module.functions[.lowered(d)] != nil { return }

    // The function is added to the module unconditionally so that it can be referred to even if it
    // lacks a definition or it is ill-formed.
    let l = module[d].parameters.map({ (p) in module[p].label })
    let f = module.addFunction(name: .lowered(d), labels: l)

    // Function requires a definition.
    guard let body = module[d].body else {
      module.addDiagnostic(module.missingImplementation(of: d))
      return
    }

    // Enumerate the captures to determine whether the function has a closure..
    let captures = CaptureEnumerator.captures(of: d, in: module)
    if captures.isEmpty {
      locals[module[d].name] = .constant(.function(f))
    } else {
      todo()
    }

    insertionContext.function = module[f]
    let entry = insertionContext.function!.appendBlock(parameterCount: module[d].parameters.count)

    insertionContext.point = .end(of: entry)
    var ls: [Name: IRValue] = [:]
    for (i, p) in module[d].parameters.enumerated() {
      ls[Name(identifier: module[p].identifier)] = .parameter(entry, i)
    }

    push(Frame(scope: .init(node: d), locals: ls))
    lower(body: body)
    pop()
    module[f] = insertionContext.function.sink()
  }

  /// Lowers the statements in `body`, which form the body of a function.
  private mutating func lower(body: [StatementIdentity]) {
    if let e = module.uniqueExpression(in: body) {
      let v = lower(e)
      _ret(v, at: .empty(at: module[e].site.end))
    } else {
      lower(block: body)
    }
  }

  // MARK: Expressions

  /// Lowers `e` to IR and returns its value.
  @discardableResult
  private mutating func lower(_ e: ExpressionIdentity) -> IRValue {
    switch module.tag(of: e) {
    case BooleanLiteral.self:
      return lower(module.castUnchecked(e, to: BooleanLiteral.self))
    case Call.self:
      return lower(module.castUnchecked(e, to: Call.self))
    case ConditionalExpression.self:
      return lower(module.castUnchecked(e, to: ConditionalExpression.self))
    case IntegerLiteral.self:
      return lower(module.castUnchecked(e, to: IntegerLiteral.self))
    case NameExpression.self:
      return lower(module.castUnchecked(e, to: NameExpression.self))
    case StringLiteral.self:
      return lower(module.castUnchecked(e, to: StringLiteral.self))
    default:
      module.unexpected(e)
    }
  }

  /// Lowers `e` to IR and returns its value.
  private mutating func lower(_ e: BooleanLiteral.ID) -> IRValue {
    .constant(.bool(module[e].value))
  }

  /// Lowers `e` to IR and returns its value.
  private mutating func lower(_ e: Call.ID) -> IRValue {
    let f = lower(module[e].callee)
    let l = module[e].arguments.map(\.label?.value)
    let a = module[e].arguments.map({ (a) in lower(a.syntax)})
    return _invoke(f, mapping: l, to: a, at: module[e].site)
  }

  /// Lowers `e` to IR and returns its value.
  private mutating func lower(_ e: ConditionalExpression.ID) -> IRValue {
    let (success, failure) = lower(conditions: module[e].conditions)
    let tail = (module[e].failure != nil) ? appendBlock(parameterCount: 1) : failure

    insertionContext.point = .end(of: success)
    let v = lower(module[e].success)
    _br(tail, [v], at: module[e].site)

    insertionContext.point = .end(of: failure)
    if let b = module[e].failure {
      let w = lower(b)
      _br(tail, [w], at: module[e].site)
    }

    insertionContext.point = .end(of: tail)
    return .parameter(tail, 0)
  }

  /// Lowers given conditions, returning a pair `(s, f)` where `s` is where control-flow jumps if
  /// if all conditions are satisifed and `f` is where control-flow jumps otherwise.
  private mutating func lower(
    conditions: [ConditionIdentity]
  ) -> (success: BasicBlock.ID, failure: BasicBlock.ID) {
    let failure = appendBlock(parameterCount: 0)

    for c in conditions {
      if module.tag(of: c) == MatchCase.self {
        todo()
      } else {
        let e = module.castToExpression(c) ?? unreachable("ill-formed syntax tree")
        let b = lower(e)
        let n = appendBlock(parameterCount: 0)
        _ = _condbr(if: b, then: n, else: failure, at: module[c].site)
        insertionContext.point = .end(of: n)
      }
    }

    return (success: insertionContext.point!.block, failure: failure)
  }

  /// Lowers `s` to IR, returning the value of the branch.
  private mutating func lower(_ s: ElseIdentity) -> IRValue {
    switch module.tag(of: s) {
    case Block.self:
      return lower(module.castUnchecked(s, to: Block.self))
    case ConditionalExpression.self:
      return lower(module.castUnchecked(s, to: ConditionalExpression.self))
    default:
      module.unexpected(s)
    }
  }

  /// Lowers `e` to IR and returns its value.
  private mutating func lower(_ e: IntegerLiteral.ID) -> IRValue {
    if let n = Int64(module[e].value) {
      return .constant(.i64(n))
    } else {
      module.addDiagnostic(module.invalidIntegerLiteral(e))
      return .poison(module.anchorForDiagnostic(about: e))
    }
  }

  /// Lowers `e` to IR and returns its value.
  private mutating func lower(_ e: NameExpression.ID) -> IRValue {
    let n = module[e].name.value

    // Lowers to member selection if there's a qualification.
    if let q = module[e].qualification {
      let v = lower(q)
      return _member(.name(n), of: v, at: module[e].site)
    }

    // Otherwise, returns the result of unqualified name lookup.
    else if let v = lookup(unqualified: n) {
      return v
    }

    // Undefined symbol.
    else {
      let a = module.anchorForDiagnostic(about: e)
      module.addDiagnostic(module.undefinedSymbol(n, at: a))
      return .poison(a)
    }
  }

  /// Lowers `e` to IR and returns its value.
  private mutating func lower(_ e: StringLiteral.ID) -> IRValue {
    .constant(.string(String(module[e].value)))
  }

  // MARK: Statements

  /// Lowers `block`, which is a list of statements to be executed in sequence.
  private mutating func lower(block: [StatementIdentity]) {
    for s in block {
      lower(s)
      if module.isBreakingControl(s) { break }
    }
  }

  /// Lowers `s` to IR.
  private mutating func lower(_ s: StatementIdentity) {
    switch module.tag(of: s) {
    case Block.self:
      lower(module.castUnchecked(s, to: Block.self))
    case Return.self:
      lower(module.castUnchecked(s, to: Return.self))
    default:
      if let d = module.castToDeclaration(s) {
        lower(d)
      } else if let e = module.castToExpression(s) {
        lower(e)
      } else {
        module.unexpected(s)
      }
    }
  }

  /// Lowers `s` to `IR`, returning the value that it computes if it is composed of a single
  /// expression or a unit value otherwise.
  @discardableResult
  private mutating func lower(_ s: Block.ID) -> IRValue {
    push(Frame(scope: .init(node: s), locals: [:]))
    defer { pop() }

    if let e = module.uniqueExpression(in: s) {
      return lower(e)
    } else {
      lower(s)
      return .constant(.unit)
    }
  }

  /// Lowers `s` to IR.
  private mutating func lower(_ s: Return.ID) {
    if let e = module[s].value {
      let v = lower(e)
      _ret(v, at: module[s].site)
    } else {
      _ret(.constant(.unit), at: module[s].site)
    }
  }

  // MARK: Helpers

  /// The context in which instructions are inserted.
  private struct InsertionContext {

    /// A stack of frames keeping track of local symbols in traversed lexical scope.
    var frames: [Frame] = []

    /// The function in which new instructions are inserted.
    var function: IRFunction? = nil

    /// Where new instructions are inserted in `function`.
    var point: InsertionPoint? = nil

  }

  /// Information about a lexical scope.
  private struct Frame {

    /// The scope associated with this frame.
    let scope: ScopeIdentity

    /// A table from local symbol to its symbol.
    var locals: [Name: IRValue]

  }

  /// The symbol table of the top frame.
  private var locals: [Name: IRValue] {
    get {
      insertionContext.frames[insertionContext.frames.count - 1].locals
    }
    _modify {
      yield &insertionContext.frames[insertionContext.frames.count - 1].locals
    }
  }

  /// Returns the result of calling `action` with a copy of `self` where the insertion point has
  /// been moved to `p`.
  private mutating func at<T>(_ p: InsertionPoint, _ action: (inout Self) -> T) -> T {
    var q = p as Optional
    swap(&q, &insertionContext.point)
    let r = action(&self)
    swap(&q, &insertionContext.point)
    return r
  }

  /// Pushes `f` onto the stack.
  private mutating func push(_ f: Frame) {
    insertionContext.frames.append(f)
  }

  /// Pops the top of the stack.
  private mutating func pop() {
    insertionContext.frames.removeLast()
  }

  /// Appends a basic block taking `n` parameters at the end of the function containing the current
  /// insertion point.
  private mutating func appendBlock(parameterCount n: Int) -> BasicBlock.ID {
    insertionContext.function!.appendBlock(parameterCount: n)
  }

  /// Returns the identities of the symbols bound to `n` in the current context, if any.
  private mutating func lookup(unqualified n: Name) -> IRValue? {
    // Look in symbol tables.
    for f in insertionContext.frames.reversed() {
      if let i = f.locals[n] { return i }
    }

    // Look for function declarations not yet processed.
    var s: [Frame] = .init(minimumCapacity: insertionContext.frames.count)
    defer { insertionContext.frames.append(contentsOf: s.reversed()) }

    while !insertionContext.frames.isEmpty {
      for d in module.declarations(lexicallyIn: insertionContext.frames.last!.scope) {
        if let c = module.cast(d, to: FunctionDeclaration.self), module[c].name == n {
          lower(c)
          return insertionContext.frames.last!.locals[n]
        }
      }
      s.append(insertionContext.frames.removeLast())
    }

    // Look for built-in symbols.
    switch n {
    case "print":
      return .constant(.print)
    case "type":
      return .constant(.type)
    default:
      return nil
    }
  }

  /// Declares the bindings that are introduced in `p` and whose storage is in `s`.
  private mutating func declareBindings(in p: PatternIdentity, relativeTo s: IRValue) {
    switch module.tag(of: p) {
    case VariableDeclaration.self:
      let d = module.castUnchecked(p, to: VariableDeclaration.self)
      locals[Name(identifier: module[d].identifier)] = s

    case TuplePattern.self:
      module.forEachDeclaration(in: p, rootedAt: []) { (path, v) in
        var w = s
        for i in path { w = _member(.index(i), of: w, at: module[p].site) }
        locals[Name(identifier: module[v].identifier)] = s
      }

    default:
      module.unexpected(p)
    }
  }

  // MARK: Instructions

  /// Inserts `instruction` into `self.module` at `self.insertionContext.point` and returns its
  /// result the register assigned by `instruction`, if any.
  @discardableResult
  private mutating func insert<T: Instruction>(_ instruction: T) -> IRValue {
    modify(&insertionContext.function!) { [p = insertionContext.point!] (f) in
      switch p {
      case .start(let b):
        return .register(f.prepend(instruction, to: b))
      case .end(let b):
        return .register(f.append(instruction, to: b))
      }
    }
  }

  private mutating func _alloc(at anchor: SourceSpan) -> IRValue {
    insert(IR.Alloc(anchor: anchor))
  }

  @discardableResult
  private mutating func _br(
    _ target: BasicBlock.ID, _ arguments: [IRValue], at anchor: SourceSpan
  ) -> IRValue {
    insert(IR.Br(target: target, arguments: arguments, anchor: anchor))
  }

  @discardableResult
  private mutating func _condbr(
    if condition: IRValue, then success: BasicBlock.ID, else failure: BasicBlock.ID,
    at anchor: SourceSpan
  ) -> IRValue {
    insert(IR.CondBr(condition: condition, success: success, failure: failure, anchor: anchor))
  }

  private mutating func _invoke(
    _ callee: IRValue, mapping labels: [String?], to arguments: [IRValue],
    at anchor: SourceSpan
  ) -> IRValue {
    insert(IR.Invoke(callee: callee, labels: labels, arguments: arguments, anchor: anchor))
  }

  private mutating func _member(
    _ member: IR.Member.NameOrIndex, of whole: IRValue, at anchor: SourceSpan
  ) -> IRValue {
    insert(IR.Member(whole: whole, member: member, anchor: anchor))
  }

  @discardableResult
  private mutating func _ret(_ value: IRValue, at anchor: SourceSpan) -> IRValue {
    insert(IR.Ret(value: value, anchor: anchor))
  }

  @discardableResult
  private mutating func _store(
    _ value: IRValue, to target: IRValue, at anchor: SourceSpan
  ) -> IRValue {
    insert(IR.Store(value: value, target: target, anchor: anchor))
  }

}
