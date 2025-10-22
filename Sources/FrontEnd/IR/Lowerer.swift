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
      let f = module.addFunction(name: .main, labels: [], isSubscript: false)

      currentFunction = module[f]
      insertionContext.point = .end(of: currentFunction!.appendBlock(parameterCount: 0))
      within(Frame(scope: .init(module: module.identity), locals: [:])) { (me) in
        me.lower(block: me.module.roots)
      }
      module[f] = currentFunction.sink()
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
    if module[module[d].pattern].introducer.value == .var {
      lower(stored: d)
    } else {
      lower(projected: d)
    }
  }

  /// Lowers the stored bindings declared by `d` to IR.
  private mutating func lower(stored d: BindingDeclaration.ID) {
    let p = module[d].pattern
    assert(module[p].introducer.value == .var)

    let storage = _alloc(at: module[d].site)
    if let e = module[d].initializer {
      module.visit(pattern: module[d].pattern, with: e, at: []) { (path, p, s) in
        let anchor = module[s].site

        // Nothing to declare if the pattern is a wildcard.
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
  }

  /// Lowers the projected bindings declared by `d` to IR.
  private mutating func lower(projected d: BindingDeclaration.ID) {
    let p = module[d].pattern
    assert(module[p].introducer.value == .let || module[p].introducer.value == .inout)

    let effect = AccessEffect(module[p].introducer.value)
    let source = lower(module[d].initializer!)
    module.forEachDeclaration(in: .init(p), rootedAt: []) { (path, d) in
      let a = module[d].site
      var w = source
      for i in path { w = _member(.index(i), of: w, at: a) }
      locals[Name(identifier: module[d].identifier)] = _access(effect, on: w, at: a)
    }
  }

  /// Lowers `d` to IR.
  private mutating func lower(_ d: FunctionDeclaration.ID) {
    withClearContext({ (me) in me.lowerInClearContext(d) })
  }

  /// Generates the IR of `d` assuming the insertion context is clear.
  ///
  /// This method is meant to be called by `lower(_:)`, ensuring that the context is clear.
  private mutating func lowerInClearContext(_ d: FunctionDeclaration.ID) {
    // The function is added to the module unconditionally so that it can be referred to even if it
    // lacks a definition or it is ill-formed.
    let f = module.functions.index(forKey: .lowered(d)) ?? declare(d)

    // Function requires a definition.
    guard let body = module[d].body else {
      module.addDiagnostic(module.missingImplementation(of: d))
      return
    }

    currentFunction = module[f]
    let entry = currentFunction!.appendBlock(parameterCount: module[d].parameters.count)

    insertionContext.point = .end(of: entry)
    var ls: [Name: IRValue] = [:]
    for (i, p) in module[d].parameters.enumerated() {
      ls[Name(identifier: module[p].identifier)] = .parameter(entry, i)
    }

    // TODO: captures

    within(Frame(scope: .init(node: d), locals: ls)) { (me) in
      me.lower(body: body, endingAt: me.module[d].site.end)
    }
    module[f] = currentFunction.sink()
  }

  /// Lowers the statements in `body`, which form the body of a function.
  private mutating func lower(body: [StatementIdentity], endingAt end: SourcePosition) {
    if let e = module.uniqueExpression(in: body) {
      let v = lower(e)
      _return(v, at: .empty(at: module[e].site.end))
    } else {
      lower(block: body)

      // Ensure the block has a terminator.
      let b = insertionContext.point!.block
      if currentFunction!.terminator(of: b) == nil {
        _return(.constant(.unit), at: .empty(at: end))
      }
    }
  }

  /// Declares the IR function to which `d` is lowered.
  private mutating func declare(_ d: FunctionDeclaration.ID) -> IRFunction.Identity {
    let l = module[d].parameters.map({ (p) in module[p].label })
    return module.addFunction(name: .lowered(d), labels: l, isSubscript: module[d].isSubscript)
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

    switch module[e].style {
    case .parenthesized:
      return _invoke(f, mapping: l, to: a, at: module[e].site)
    case .bracketed:
      return _project(f, mapping: l, to: a, at: module[e].site)
    }
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

  /// Lowers `block`, which is a list of statements to be evaluated sequentially.
  private mutating func lower<T: SyntaxIdentity>(block: [T]) {
    var ss: [StatementIdentity] = []

    // Hoist pure functions.
    for n in block {
      if let d = module.cast(n, to: FunctionDeclaration.self) {
        let captures = CaptureEnumerator.captures(of: d, in: module)
        if captures.isEmpty {
          locals[module[d].name] = .constant(.function(declare(d)))
          lower(d)
        } else {
          ss.append(.init(d))
        }
      } else {
        // Other nodes should be statements.
        ss.append(module.castToStatement(n) ?? unreachable("ill-formed syntax tree"))
      }
    }

    // Lower all other statements.
    for s in ss {
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
    case Yield.self:
      lower(module.castUnchecked(s, to: Yield.self))
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
    within(Frame(scope: .init(node: s), locals: [:])) { (me) in
      if let e = me.module.uniqueExpression(in: s) {
        return me.lower(e)
      } else {
        me.lower(s)
        return .constant(.unit)
      }
    }
  }

  /// Lowers `s` to IR.
  private mutating func lower(_ s: Return.ID) {
    if let e = module[s].value {
      let v = lower(e)
      _return(v, at: module[s].site)
    } else {
      _return(.constant(.unit), at: module[s].site)
    }
  }

  /// Lowers `s` to IR.
  private mutating func lower(_ s: Yield.ID) {
    if currentFunction!.isSubscript {
      let v = lower(module[s].value)
      _yield(v, at: module[s].site)
    } else {
      module.addDiagnostic(module.invalidYield(s))
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

  /// The current insertion function, if any.
  private var currentFunction: IRFunction? {
    get { insertionContext.function }
    set { insertionContext.function = newValue }
    _modify {
      yield &insertionContext.function
    }
  }

  /// Returns the result of calling `action` on a copy of `self` with a cleared insertion context.
  ///
  /// Use this method to wrap the lowering of a function or subscript to save the current insertion
  /// context and restore it once `action` returns.
  private mutating func withClearContext<T>(_ action: (inout Self) -> T) -> T {
    var c = InsertionContext()
    swap(&c, &insertionContext)
    let r = action(&self)
    swap(&c, &insertionContext)
    return r
  }

  /// Returns the result of calling `action` on `self` within `f`.
  ///
  /// `f` is pushed on `self.frames` before `action` is called. When `action` returns. References
  /// to locals set by `action` are invalidated when this method returns.
  private mutating func within<T>(_ f: Frame, _ action: (inout Self) -> T) -> T {
    insertionContext.frames.append(f)
    let r = action(&self)
    insertionContext.frames.removeLast()
    return r
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

  /// Appends a basic block taking `n` parameters at the end of the function containing the current
  /// insertion point.
  private mutating func appendBlock(parameterCount n: Int) -> BasicBlock.ID {
    currentFunction!.appendBlock(parameterCount: n)
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
    modify(&currentFunction!) { [p = insertionContext.point!] (f) in
      switch p {
      case .start(let b):
        return .register(f.prepend(instruction, to: b))
      case .end(let b):
        return .register(f.append(instruction, to: b))
      }
    }
  }

  private mutating func _access(
    _ capability: AccessEffect, on source: IRValue, at anchor: SourceSpan
   ) -> IRValue {
     insert(IRAccess(source: source, capability: capability, anchor: anchor))
   }


  private mutating func _alloc(at anchor: SourceSpan) -> IRValue {
    insert(IRAlloc(anchor: anchor))
  }

  @discardableResult
  private mutating func _br(
    _ target: BasicBlock.ID, _ arguments: [IRValue], at anchor: SourceSpan
  ) -> IRValue {
    insert(IRBranch(target: target, arguments: arguments, anchor: anchor))
  }

  @discardableResult
  private mutating func _condbr(
    if condition: IRValue, then success: BasicBlock.ID, else failure: BasicBlock.ID,
    at anchor: SourceSpan
  ) -> IRValue {
    let s = IRConditionalBranch(
      condition: condition, success: success, failure: failure, anchor: anchor)
    return insert(s)
  }

  private mutating func _invoke(
    _ callee: IRValue, mapping labels: [String?], to arguments: [IRValue],
    at anchor: SourceSpan
  ) -> IRValue {
    insert(IRInvoke(callee: callee, labels: labels, arguments: arguments, anchor: anchor))
  }

  private mutating func _member(
    _ member: IRMember.NameOrIndex, of whole: IRValue, at anchor: SourceSpan
  ) -> IRValue {
    insert(IRMember(whole: whole, member: member, anchor: anchor))
  }

  private mutating func _project(
    _ callee: IRValue, mapping labels: [String?], to arguments: [IRValue],
    at anchor: SourceSpan
  ) -> IRValue {
    insert(IRProject(callee: callee, labels: labels, arguments: arguments, anchor: anchor))
  }

  @discardableResult
  private mutating func _return(_ value: IRValue, at anchor: SourceSpan) -> IRValue {
    insert(IRReturn(value: value, anchor: anchor))
  }

  @discardableResult
  private mutating func _store(
    _ value: IRValue, to target: IRValue, at anchor: SourceSpan
  ) -> IRValue {
    insert(IRStore(value: value, target: target, anchor: anchor))
  }

  @discardableResult
  private mutating func _yield(_ value: IRValue, at anchor: SourceSpan) -> IRValue {
    insert(IRYield(value: value, anchor: anchor))
  }

}
