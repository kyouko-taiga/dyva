import OrderedCollections
import Utilities

/// A module, which consists of single source file.
public struct Module: Sendable {

  /// The identity of a module.
  public typealias Identity = UInt32

  /// The position of `self` in the containing program.
  internal let identity: Identity

  /// `true` iff `self` is the program entry.
  internal let isMain: Bool

  /// The source file contained in `self`.
  internal let source: SourceFile

  /// The abstract syntax of `source`'s contents.
  internal var syntax: [AnySyntax] = []

  /// A table from syntax tree to its tag.
  internal var syntaxToTag: [SyntaxTag] = []

  /// The list of all (top-level) imports in `self`.
  internal var imports: [Import.ID] = []

  /// The resolved list of all imports by name.
  internal var namesToImports: OrderedDictionary<Name, DeclarationIdentity> = [:]

  /// The root of the syntax trees in `self`, which may be subset of the top-level declarations.
  internal var roots: [AnySyntaxIdentity] = []

  /// A table from syntax tree to the scope that contains it.
  ///
  /// The keys and values of the table are the offsets of the syntax trees in the source file
  /// (i.e., syntax identities sans module offset). Top-level declarations are mapped onto `-1`.
  internal var syntaxToParent: [Int] = []

  /// A table from scope to the declarations that it contains directly.
  internal var scopeToDeclarations: [Int: [DeclarationIdentity]] = [:]

  /// A table from identifiers to the corresponding top-level declaration.
  internal var topLevelDeclarations: [String: DeclarationIdentity] = [:]

  /// The lowered functions in the module.
  internal var functions: OrderedDictionary<IRFunction.Name, IRFunction> = [:]

  /// The diagnostics accumulated during compilation.
  internal private(set) var diagnostics = OrderedSet<Diagnostic>()

  /// `true` iff at least one element in `diagnostics` is an error.
  internal private(set) var containsError: Bool = false

  /// `true` iff `self` has gone through scoping.
  public var isScoped: Bool {
    syntaxToParent.count == syntax.count
  }

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

  /// Returns the elements in `ns` that identify nodes of type `T`.
  public func collect<S: Sequence, T: Syntax>(
    _ t: T.Type, in ns: S
  ) -> (some Sequence<ConcreteSyntaxIdentity<T>>) where S.Element: SyntaxIdentity {
    ns.lazy.compactMap({ (n) in cast(n, to: t) })
  }

  /// Returns the innermost scope that strictly contains `n`.
  public func parent<T: SyntaxIdentity>(containing n: T) -> ScopeIdentity {
    assert(isScoped, "unscoped module")
    let p = syntaxToParent[n.offset]
    if p >= 0 {
      return .init(uncheckedFrom: .init(module: identity, offset: p))
    } else {
      return .init(module: identity)
    }
  }

  /// Returns a sequence containing `s` and its ancestors, from inner to outer.
  public func scopes(from s: ScopeIdentity) -> some Sequence<ScopeIdentity> {
    var next: Optional = s
    return AnyIterator {
      if let n = next {
        next = n.node.map(parent(containing:))
        return n
      } else {
        return nil
      }
    }
  }

  /// Returns the declarations directly contained in `s`.
  public func declarations(lexicallyIn s: ScopeIdentity) -> [DeclarationIdentity] {
    if let n = s.node {
      return scopeToDeclarations[n.offset] ?? preconditionFailure("unscoped module")
    } else {
      return roots.compactMap(castToDeclaration(_:))
    }
  }

  /// Returns the argument labels of `d`.
  public func labels(of d: FunctionDeclaration.ID) -> [String?] {
    self[d].parameters.map({ (p) in self[p].label })
  }

  /// Returns the contents of `b` it it contains exactly one expression.
  public func uniqueExpression(in b: Block.ID) -> ExpressionIdentity? {
    uniqueExpression(in: self[b].statements)
  }

  /// Returns the contents of `b` it it contains exactly one expression.
  public func uniqueExpression(in b: [StatementIdentity]) -> ExpressionIdentity? {
    b.uniqueElement.flatMap(castToExpression(_:))
  }

  /// Inserts `child` into `self`.
  internal mutating func insert<T: Syntax>(_ child: T) -> T.ID {
    let d = syntax.count
    syntax.append(.init(child))
    syntaxToTag.append(.init(T.self))
    syntaxToParent.append(-1)
    return T.ID(uncheckedFrom: .init(module: identity, offset: d))
  }

  /// Projects the IR function identified by `n`.
  internal subscript(_ n: IRFunction.Identity) -> IRFunction {
    get {
      functions.values[n]
    }
    _modify {
      yield &functions.values[n]
    }
  }

  /// Adds an IR function with the given properties to this module and returns its identity.
  internal mutating func addFunction(
    name: IRFunction.Name, labels: [String?]
  ) -> IRFunction.Identity {
    if let i = functions.index(forKey: name) {
      return i
    } else {
      let i = functions.count
      functions[name] = .init(identity: i, labels: labels)
      return i
    }
  }

  /// Adds a diagnostic to this module.
  ///
  /// - requires: The diagnostic is anchored at a position in `self`.
  public mutating func addDiagnostic(_ d: Diagnostic) {
    assert(d.site.source.name == source.name)
    diagnostics.append(d)
    if d.level == .error {
      containsError = true
    }
  }

  /// Returns a source span suitable to emit a disgnostic related to `n`.
  public func anchorForDiagnostic<T: SyntaxIdentity>(about n: T) -> SourceSpan {
    self[n].site
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

  /// Returns a textual representation of `n`.
  public func show(_ n: IRFunction.Identity) -> String {
    let (name, function) = functions.elements[n]

    // Write the signature.
    var result = "fun \(show(name))("
    for l in function.labels {
      result.write(l ?? "_")
      result.write(":")
    }
    result.write(")")

    // Nothing more to do if the function has no definition.
    if !function.isDefined { return result }

    // Otherwise, renders the basic blocks.
    result.write(" =\n")
    for b in function.blocks.addresses {
      let bb = BasicBlockIdentity(function: n, address: b)

      result.write("  b\(b) =\n")
      for s in function.blocks[b].instructions.addresses {
        let r = IRValue.register(.init(block: bb, address: s))
        let v = function.blocks[b].instructions[s].show(using: self)
        result.write("    \(r) = \(v)\n")
      }
    }

    return result
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
