import Utilities

/// A function computing the scoping relationships of a module.
public struct Scoper {

  /// Creates an instance.
  public init() {}

  /// Computes the scoping relationships in `m`.
  public func visit(_ m: inout Module) {
    var v = Visitor(m)
    for n in m.roots {
      m.visit(n, calling: &v)
    }
    modify(&m) { (w) in
      swap(&w.syntaxToParent, &v.syntaxToParent)
      swap(&w.scopeToDeclarations, &v.scopeToDeclarations)
    }
    assert(m.syntax.count == v.syntaxToParent.count)
  }

  /// The computation of the scoping relationships in a single source file.
  private struct Visitor: SyntaxVisitor, Sendable {

    /// A table from syntax tree to the scope that contains it.
    var syntaxToParent: [Int]

    /// A table from scope to the declarations that it contains directly.
    var scopeToDeclarations: [Int: [DeclarationIdentity]]

    /// The innermost lexical scope currently visited.
    var innermostScope: Int

    /// Creates an instance for computing the relationships of `m`.
    init(_ m: Module) {
      self.syntaxToParent = m.syntaxToParent
      self.scopeToDeclarations = [:]
      self.innermostScope = -1
    }

    mutating func willEnter(_ n: AnySyntaxIdentity, in module: Module) -> Bool {
      syntaxToParent[n.offset] = innermostScope

      if let m = module.castToDeclaration(n) {
        if innermostScope >= 0 {
          scopeToDeclarations[innermostScope]!.append(m)
        }
      }

      if module.isScope(n) {
        innermostScope = n.offset
        scopeToDeclarations[innermostScope] = []
      }

      return true
    }

    mutating func willExit(_ n: AnySyntaxIdentity, in module: Module) {
      if module.isScope(n) {
        innermostScope = syntaxToParent[n.offset]
      }
    }

  }

}
