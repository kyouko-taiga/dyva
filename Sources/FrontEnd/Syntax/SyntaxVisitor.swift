/// A collection of callbacks for visiting an abstract syntax tree.
///
/// Use this protocol to implement algorithms that traverse all or most nodes of an abstract syntax
/// tree and perform similar operations on each of them. Instances of conforming types are meant to
/// be passed as argument to `Syntax.visit(_:calling:)`.
public protocol SyntaxVisitor {

  /// Called when the node `node`, which is in `module`, is about to be entered; returns `false`
  /// if traversal should skip `node`.
  ///
  /// Use this method to perform actions before a node is being traversed and/or customize how the
  /// tree is traversed. If the method returns `true`, `willEnter` will be called before visiting
  /// each child of `node` and `willExit` will be called when `node` is left. If the method returns
  /// `false`, neither `willEnter` nor `willExit` will be called for `node` and its children.
  mutating func willEnter(_ node: AnySyntaxIdentity, in module: Module) -> Bool

  /// Called when the node `node`, which is in `module`, is about to be left.
  mutating func willExit(_ node: AnySyntaxIdentity, in module: Module)

}

extension SyntaxVisitor {

  public mutating func willEnter(_ node: AnySyntaxIdentity, in module: Module) -> Bool { true }

  public mutating func willExit(_ node: AnySyntaxIdentity, in module: Module) {}

}

extension Module {

  /// Calls `visit(_:calling:)` on the abstract syntax tree of `self`.
  public func visit<T: SyntaxVisitor>(calling v: inout T) {
    for o in syntax.indices {
      visit(AnySyntaxIdentity(module: identity, offset: o), calling: &v)
    }
  }

  /// Visits `n` and its children in pre-order, calling back `v` when a node is entered or left.
  public func visit<T: SyntaxVisitor>(_ n: AnySyntaxIdentity, calling v: inout T) {
    if !v.willEnter(n, in: self) { return }
    switch tag(of: n) {
    case BindingDeclaration.self:
      traverse(castUnchecked(n, to: BindingDeclaration.self), calling: &v)
    case FieldDeclaration.self:
      traverse(castUnchecked(n, to: FieldDeclaration.self), calling: &v)
    case FunctionDeclaration.self:
      traverse(castUnchecked(n, to: FunctionDeclaration.self), calling: &v)
    case ParameterDeclaration.self:
      traverse(castUnchecked(n, to: ParameterDeclaration.self), calling: &v)
    case StructDeclaration.self:
      traverse(castUnchecked(n, to: StructDeclaration.self), calling: &v)
    case TraitDeclaration.self:
      traverse(castUnchecked(n, to: TraitDeclaration.self), calling: &v)
    case VariableDeclaration.self:
      break

    case ArrayLiteral.self:
      traverse(castUnchecked(n, to: ArrayLiteral.self), calling: &v)
    case BooleanLiteral.self:
      break
    case Call.self:
      traverse(castUnchecked(n, to: Call.self), calling: &v)
    case ConditionalExpression.self:
      traverse(castUnchecked(n, to: ConditionalExpression.self), calling: &v)
    case DictionaryLiteral.self:
      traverse(castUnchecked(n, to: DictionaryLiteral.self), calling: &v)
    case FloatingPointLiteral.self:
      break
    case IntegerLiteral.self:
      break
    case Lambda.self:
      traverse(castUnchecked(n, to: Lambda.self), calling: &v)
    case MatchExpression.self:
      traverse(castUnchecked(n, to: MatchExpression.self), calling: &v)
    case NameExpression.self:
      traverse(castUnchecked(n, to: NameExpression.self), calling: &v)
    case StringLiteral.self:
      break
    case TryExpression.self:
      traverse(castUnchecked(n, to: TryExpression.self), calling: &v)
    case TupleLiteral.self:
      traverse(castUnchecked(n, to: TupleLiteral.self), calling: &v)
    case TypeTest.self:
      traverse(castUnchecked(n, to: TypeTest.self), calling: &v)

    case BindingPattern.self:
      traverse(castUnchecked(n, to: BindingPattern.self), calling: &v)
    case ExtractorPattern.self:
      traverse(castUnchecked(n, to: ExtractorPattern.self), calling: &v)
    case TuplePattern.self:
      traverse(castUnchecked(n, to: TuplePattern.self), calling: &v)
    case TypePattern.self:
      traverse(castUnchecked(n, to: TypePattern.self), calling: &v)
    case Wildcard.self:
      break

    case Assignment.self:
      traverse(castUnchecked(n, to: Assignment.self), calling: &v)
    case Block.self:
      traverse(castUnchecked(n, to: Block.self), calling: &v)
    case Break.self:
      break
    case Continue.self:
      break
    case For.self:
      traverse(castUnchecked(n, to: For.self), calling: &v)
    case Return.self:
      traverse(castUnchecked(n, to: Return.self), calling: &v)
    case Throw.self:
      traverse(castUnchecked(n, to: Throw.self), calling: &v)
    case While.self:
      traverse(castUnchecked(n, to: While.self), calling: &v)

    case MatchCase.self:
      traverse(castUnchecked(n, to: MatchCase.self), calling: &v)
    case MatchCondition.self:
      traverse(castUnchecked(n, to: MatchCondition.self), calling: &v)

    default:
      unexpected(n)
    }
    v.willExit(n, in: self)
  }

  /// Visits `n` and its children in pre-order, calling back `v` when a node is entered or left.
  public func visit<T: SyntaxVisitor, U: SyntaxIdentity>(_ n: U?, calling v: inout T) {
    n.map({ (m) in visit(m.widened, calling: &v) })
  }

  /// Visits `ns` and their children in pre-order, calling back `v` when a node is entered or left.
  public func visit<T: SyntaxVisitor, U: Collection>(
    _ ns: U, calling v: inout T
  ) where U.Element: SyntaxIdentity {
    for n in ns {
      visit(n.widened, calling: &v)
    }
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: BindingDeclaration.ID, calling v: inout T) {
    visit(self[n].pattern, calling: &v)
    visit(self[n].initializer, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: FieldDeclaration.ID, calling v: inout T) {
    visit(self[n].defaultValue, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: FunctionDeclaration.ID, calling v: inout T) {
    visit(self[n].parameters, calling: &v)
    if let b = self[n].body { visit(b, calling: &v) }
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: ParameterDeclaration.ID, calling v: inout T) {
    visit(self[n].defaultValue, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: StructDeclaration.ID, calling v: inout T) {
    visit(self[n].fields, calling: &v)
    visit(self[n].interfaces, calling: &v)
    visit(self[n].members, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: TraitDeclaration.ID, calling v: inout T) {
    visit(self[n].interfaces, calling: &v)
    visit(self[n].members, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: ArrayLiteral.ID, calling v: inout T) {
    visit(self[n].elements, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: Call.ID, calling v: inout T) {
    visit(self[n].callee, calling: &v)
    for a in self[n].arguments { visit(a.syntax, calling: &v) }
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: ConditionalExpression.ID, calling v: inout T) {
    visit(self[n].conditions, calling: &v)
    visit(self[n].success, calling: &v)
    visit(self[n].failure, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: DictionaryLiteral.ID, calling v: inout T) {
    for e in self[n].elements {
      visit(e.key, calling: &v)
      visit(e.value, calling: &v)
    }
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: Lambda.ID, calling v: inout T) {
    visit(self[n].parameters, calling: &v)
    visit(self[n].body, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: MatchExpression.ID, calling v: inout T) {
    visit(self[n].scrutinee, calling: &v)
    visit(self[n].branches, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: NameExpression.ID, calling v: inout T) {
    visit(self[n].qualification, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: TryExpression.ID, calling v: inout T) {
    visit(self[n].body, calling: &v)
    visit(self[n].handlers, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: TupleLiteral.ID, calling v: inout T) {
    for a in self[n].elements { visit(a.syntax, calling: &v) }
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: TypeTest.ID, calling v: inout T) {
    visit(self[n].lhs, calling: &v)
    visit(self[n].rhs, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: BindingPattern.ID, calling v: inout T) {
    visit(self[n].pattern, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: ExtractorPattern.ID, calling v: inout T) {
    visit(self[n].extractor, calling: &v)
    for a in self[n].elements { visit(a.syntax, calling: &v) }
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: TuplePattern.ID, calling v: inout T) {
    for a in self[n].elements { visit(a.syntax, calling: &v) }
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: TypePattern.ID, calling v: inout T) {
    visit(self[n].lhs, calling: &v)
    visit(self[n].rhs, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: Assignment.ID, calling v: inout T) {
    visit(self[n].lhs, calling: &v)
    visit(self[n].rhs, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: Block.ID, calling v: inout T) {
    visit(self[n].statements, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: For.ID, calling v: inout T) {
    visit(self[n].pattern, calling: &v)
    visit(self[n].sequence, calling: &v)
    visit(self[n].filters, calling: &v)
    visit(self[n].body, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: Return.ID, calling v: inout T) {
    visit(self[n].value, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: Throw.ID, calling v: inout T) {
    visit(self[n].value, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: While.ID, calling v: inout T) {
    visit(self[n].conditions, calling: &v)
    visit(self[n].body, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: MatchCase.ID, calling v: inout T) {
    visit(self[n].pattern, calling: &v)
    visit(self[n].body, calling: &v)
  }

  /// Visits the children of `n` in pre-order, calling back `v` when a node is entered or left.
  public func traverse<T: SyntaxVisitor>(_ n: MatchCondition.ID, calling v: inout T) {
    visit(self[n].pattern, calling: &v)
    visit(self[n].scrutinee, calling: &v)
  }

}
