/// A syntax visitor that enumerators the free variables of a function definition.
internal struct CaptureEnumerator: SyntaxVisitor {

  /// The root of the tree being visited.
  private var root: AnySyntaxIdentity

  /// The set of identifiers that are known to be bound.
  private var bound: Set<String>

  /// The (partially formed) set of enumerated captures.
  private(set) internal var captures: [String: [SourceSpan]]

  /// Creates an instance with the given root and set of bound identifiers.
  private init(root: AnySyntaxIdentity, bound: Set<String>) {
    self.root = root
    self.bound = []
    self.captures = [:]
  }

  /// Returns variables that occur free in `d` along with the positions of their occurences.
  internal static func captures(
    of d: FunctionDeclaration.ID, in module: Module
  ) -> [String: [SourceSpan]] {
    var enumerator = Self(root: d.widened, bound: [])
    module.visit(d, calling: &enumerator)
    return enumerator.captures
  }

  internal mutating func willEnter(_ n: AnySyntaxIdentity, in module: Module) -> Bool {
    if n == root { return false }

    switch module.tag(of: n) {
    case NameExpression.self:
      return willEnter(module.castUnchecked(n, to: NameExpression.self), in: module)
    case FunctionDeclaration.self:
      return willEnter(module.castUnchecked(n, to: FunctionDeclaration.self), in: module)
    case ParameterDeclaration.self:
      return willEnter(module.castUnchecked(n, to: ParameterDeclaration.self), in: module)
    case StructDeclaration.self:
      return willEnter(module.castUnchecked(n, to: StructDeclaration.self), in: module)
    case TraitDeclaration.self:
      return willEnter(module.castUnchecked(n, to: TraitDeclaration.self), in: module)
    case VariableDeclaration.self:
      return willEnter(module.castUnchecked(n, to: VariableDeclaration.self), in: module)

    default:
      if module.isScope(n) {
        withChildEnumerator(root: n, { (child) in module.visit(n, calling: &child) })
        return false
      } else {
        return true
      }
    }
  }

  /// Implements `willEnter(_:in:)` for `NameExpression`.
  private mutating func willEnter(_ e: NameExpression.ID, in module: Module) -> Bool {
    if module[e].qualification == nil {
      let n = module[e].name
      if !bound.contains(n.value.identifier) {
        captures[n.value.identifier, default: []].append(n.site)
      }
      return false
    } else {
      return true
    }
  }

  /// Implements `willEnter(_:in:)` for `FunctionDeclaration`.
  private mutating func willEnter(_ d: FunctionDeclaration.ID, in module: Module) -> Bool {
    bound.insert(module[d].name.identifier)

    withChildEnumerator(root: d.widened) { (child) in
      module.visit(module[d].parameters, calling: &child)
      if let b = module[d].body {
        module.visit(b, calling: &child)
      }
    }

    return false
  }

  /// Implements `willEnter(_:in:)` for `ParameterDeclaration`.
  private mutating func willEnter(_ d: ParameterDeclaration.ID, in module: Module) -> Bool {
    bound.insert(module[d].identifier)
    return true
  }

  /// Implements `willEnter(_:in:)` for `StructDeclaration`.
  private mutating func willEnter(_ d: StructDeclaration.ID, in module: Module) -> Bool {
    bound.insert(module[d].identifier)
    return false
  }

  /// Implements `willEnter(_:in:)` for `TraitDeclaration`.
  private mutating func willEnter(_ d: TraitDeclaration.ID, in module: Module) -> Bool {
    bound.insert(module[d].identifier)
    return false
  }

  /// Implements `willEnter(_:in:)` for `VariableDeclaration`.
  private mutating func willEnter(_ d: VariableDeclaration.ID, in module: Module) -> Bool {
    bound.insert(module[d].identifier)
    return false
  }

  /// Returns the result of `action` called on a copy of `self` rooted at `n` after merging the
  /// captures of that copy into `self`.
  private mutating func withChildEnumerator<T>(
    root n: AnySyntaxIdentity, _ action: (inout Self) -> T
  ) -> T {
    var child = CaptureEnumerator(root: n, bound: self.bound)
    swap(&self.captures, &child.captures)
    let result = action(&child)
    swap(&self.captures, &child.captures)
    return result
  }

}
