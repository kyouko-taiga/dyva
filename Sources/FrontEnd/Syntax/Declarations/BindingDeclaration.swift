/// The declaration of a (possibly empty) set of bindings.
public struct BindingDeclaration: Declaration {

  /// The grammatical role a binding declaration plays.
  public enum Role: Hashable, Sendable {

    /// The declaration is used to introduce new bindings unconditionally.
    case unconditional

    /// The declaration is used to introduce new bindings iff its pattern matches the value of its
    /// initializer, which is not `nil`.
    case condition

  }

  /// The grammatical role of this declaration.
  public let role: Role

  /// A pattern introducing the declared bindings.
  public let pattern: BindingPattern.ID

  /// The initializer of the declaration, if any.
  public let initializer: ExpressionIdentity?

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    role: Role,
    pattern: BindingPattern.ID,
    initializer: ExpressionIdentity?,
    site: SourceSpan
  ) {
    self.role = role
    self.pattern = pattern
    self.initializer = initializer
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    var result = module.show(pattern)
    if let i = initializer {
      result.write(" = \(module.show(i))")
    }
    return result
  }

}
