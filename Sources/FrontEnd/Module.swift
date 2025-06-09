import OrderedCollections
import Utilities

/// A module, which consists of single source file.
public struct Module: Sendable {

  /// The position of `self` in the containing program.
  internal let identity: Program.ModuleIdentity

  /// `true` iff `self` is the program entry.
  internal let isMain: Bool

  /// The source file contained in `self`.
  internal let source: SourceFile

  /// The abstract syntax of `source`'s contents.
  internal var syntax: [AnySyntax] = []

  /// A table from syntax tree to its tag.
  internal var syntaxToTag: [SyntaxTag] = []

  /// The root of the syntax trees in `self`, which may be subset of the top-level declarations.
  internal var roots: [AnySyntaxIdentity] = []

  /// A table from syntax tree to the scope that contains it.
  ///
  /// The keys and values of the table are the offsets of the syntax trees in the source file
  /// (i.e., syntax identities sans module offset). Top-level declarations are mapped onto `-1`.
  internal var syntaxToParent: [Int] = []

  /// A table from scope to the declarations that it contains directly.
  internal var scopeToDeclarations: [Int: [DeclarationIdentity]] = [:]

  /// The diagnostics accumulated during compilation.
  internal private(set) var diagnostics = OrderedSet<Diagnostic>()

  /// `true` iff at least one element in `diagnostics` is an error.
  internal private(set) var containsError: Bool = false

  /// Projects the node identified by `n`.
  public subscript<T: SyntaxIdentity>(n: T) -> any Syntax {
    assert(n.module == identity)
    return syntax[n.offset].wrapped
  }

  /// Projects the node identified by `n`.
  public subscript<T: Syntax>(n: T.ID) -> T {
    assert(n.module == identity)
    return syntax[n.offset].wrapped as! T
  }

  /// Returns the tag of `n`.
  public func tag<T: SyntaxIdentity>(of n: T) -> SyntaxTag {
    assert(n.module == identity)
    return syntaxToTag[n.offset]
  }

  /// Returns `true` iff `n` denotes a declaration.
  public func isDeclaration<T: SyntaxIdentity>(_ n: T) -> Bool {
    tag(of: n).value is any Declaration.Type
  }

  /// Returns `true` iff `n` denotes an expression.
  public func isExpression<T: SyntaxIdentity>(_ n: T) -> Bool {
    tag(of: n).value is any Expression.Type
  }

  /// Returns `true` iff `n` denotes a pattern.
  public func isPattern<T: SyntaxIdentity>(_ n: T) -> Bool {
    tag(of: n).value is any Pattern.Type
  }

  /// Returns `true` iff `n` denotes a statement.
  public func isStatement<T: SyntaxIdentity>(_ n: T) -> Bool {
    tag(of: n).value is any Statement.Type
  }

  /// Returns `true` iff `n` denotes a scope.
  public func isScope<T: SyntaxIdentity>(_ n: T) -> Bool {
    tag(of: n).value is any Scope.Type
  }

  /// Returns `n` if it identifies a node of type `U`; otherwise, returns `nil`.
  public func cast<T: SyntaxIdentity, U: Syntax>(_ n: T, to: U.Type) -> U.ID? {
    if tag(of: n) == .init(U.self) {
      return .init(uncheckedFrom: n.widened)
    } else {
      return nil
    }
  }

  /// Returns `n` assuming it identifies a node of type `U`.
  public func castUnchecked<T: SyntaxIdentity, U: Syntax>(_ n: T, to: U.Type = U.self) -> U.ID {
    assert(tag(of: n) == .init(U.self))
    return .init(uncheckedFrom: n.widened)
  }

  /// Returns `n` if it identifies a declaration; otherwise, returns `nil`.
  public func castToDeclaration<T: SyntaxIdentity>(_ n: T) -> DeclarationIdentity? {
    if isDeclaration(n) {
      return .init(uncheckedFrom: n.widened)
    } else {
      return nil
    }
  }

  /// Returns `n` if it identifies an expression; otherwise, returns `nil`.
  public func castToExpression<T: SyntaxIdentity>(_ n: T) -> ExpressionIdentity? {
    if isExpression(n) {
      return .init(uncheckedFrom: n.widened)
    } else {
      return nil
    }
  }

  /// Returns `n` if it identifies a pattern; otherwise, returns `nil`.
  public func castToPattern<T: SyntaxIdentity>(_ n: T) -> PatternIdentity? {
    if isPattern(n) {
      return .init(uncheckedFrom: n.widened)
    } else {
      return nil
    }
  }

  /// Returns `n` if it identifies a statement; otherwise, returns `nil`.
  public func castToStatement<T: SyntaxIdentity>(_ n: T) -> StatementIdentity? {
    if isStatement(n) {
      return .init(uncheckedFrom: n.widened)
    } else {
      return nil
    }
  }

  /// Returns `n` if it identifies a scope; otherwise, returns `nil`.
  public func castToScope<T: SyntaxIdentity>(_ n: T) -> ScopeIdentity? {
    if isScope(n) {
      return .init(uncheckedFrom: n.widened)
    } else {
      return nil
    }
  }

  /// Inserts `child` into `self`.
  internal mutating func insert<T: Syntax>(_ child: T) -> T.ID {
    let d = syntax.count
    syntax.append(.init(child))
    syntaxToTag.append(.init(T.self))
    syntaxToParent.append(-1)
    return T.ID(uncheckedFrom: .init(module: identity, offset: d))
  }

  /// Adds a diagnostic to this module.
  ///
  /// - requires: The diagnostic is anchored at a position in `self`.
  internal mutating func addDiagnostic(_ d: Diagnostic) {
    assert(d.site.source.name == source.name)
    diagnostics.append(d)
    if d.level == .error {
      containsError = true
    }
  }

  /// Reports that `n` was not expected in the current executation path and exits the program.
  public func unexpected<T: SyntaxIdentity>(
    _ n: T, file: StaticString = #file, line: UInt = #line
  ) -> Never {
    unreachable("unexpected node '\(tag(of: n))' at \(self[n].site)", file: file, line: line)
  }

  /// Returns a textual representation of `item`.
  public func show<T: Showable>(_ item: T) -> String {
    item.show(using: self)
  }

  /// Returns a textual representation of `items`, separating each element by `separator`.
  public func show<T: Sequence>(
    _ items: T, separatedBy separator: String = ", "
  ) -> String where T.Element: Showable {
    items.map({ (n) in show(n) }).joined(separator: separator)
  }

}

extension Module: CustomStringConvertible {

  /// Returns a textual representation of the syntax trees of `m`.
  public var description: String {
    roots.reduce(into: "") { (o, t) in
      o.write(show(t))
      o.write("\n")
    }
  }

}
