/// An Boolean expression testing the type of a value.
public struct TypeTest: Expression {

  /// The expression of the value whose type is being tested.
  public let lhs: ExpressionIdentity

  /// The expression of the type.
  public let rhs: ExpressionIdentity

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(lhs: ExpressionIdentity, rhs: ExpressionIdentity, site: SourceSpan) {
    self.lhs = lhs
    self.rhs = rhs
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "\(module.show(lhs)) is \(module.show(rhs))"
  }

}
