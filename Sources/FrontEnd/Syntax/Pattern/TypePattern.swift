/// A pattern that matches if the scrutinee conforms to a particular type.
public struct TypePattern: Pattern {

  /// A subpattern that is matched against the scrutinee if the latter's type match.
  public let lhs: PatternIdentity

  /// The expression of the type.
  public let rhs: ExpressionIdentity

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(lhs: PatternIdentity, rhs: ExpressionIdentity, site: SourceSpan) {
    self.lhs = lhs
    self.rhs = rhs
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "\(module.show(lhs)) as \(module.show(rhs))"
  }

}
