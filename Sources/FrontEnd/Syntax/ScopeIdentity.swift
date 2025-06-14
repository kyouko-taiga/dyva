/// The identity of a lexical scope.
public struct ScopeIdentity: Hashable {

  /// The internal representation of this identity.
  private var representation: AnySyntaxIdentity

  /// Creates an instance representing the scope formed by `module`.
  public init(module: Module.Identity) {
    self.representation = .init(bits: UInt64(module) << 32 | UInt64(UInt32.max))
  }

  /// Creates an instance representing the scope formed by `syntax`.
  public init<T: Scope>(node: T.ID) {
    self.representation = node.widened
  }

  /// Creates an instance representing the scope formed by `syntax`, assuming it is a scope.
  public init(uncheckedFrom node: AnySyntaxIdentity) {
    self.representation = node
  }

  /// The module containing this scope.
  public var file: Module.Identity {
    representation.module
  }

  /// `true` iff `self` represents a whole module.
  public var isModule: Bool {
    representation.offset == UInt32.max
  }

  /// The syntax tree that `self` represents, or `nil` if `self` represents a file.
  public var node: AnySyntaxIdentity? {
    isModule ? nil : .init(uncheckedFrom: representation)
  }

}

extension ScopeIdentity: Showable {

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    if let n = node {
      return module.show(n)
    } else {
      return module.description
    }
  }

}
