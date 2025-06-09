/// A pattern introducing a (possibly empty) set of bindings.
public struct BindingPattern: Pattern {

  /// The introducer of a binding pattern.
  public enum Introducer: Sendable {

    /// The introducer of owned bindings.
    case `var`

    /// The introducer of a mutable projection.
    case `inout`

    /// The introducer of an immutable projection.
    case `let`

  }

  /// The introducer of this declaration.
  public let introducer: Parsed<Introducer>

  /// A tree containing the declarations of the bindings being introduced.
  public let pattern: PatternIdentity

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(introducer: Parsed<Introducer>, pattern: PatternIdentity, site: SourceSpan) {
    self.introducer = introducer
    self.pattern = pattern
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "\(introducer) \(module.show(pattern))"
  }

}
