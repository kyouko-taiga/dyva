/// The assignment of a lvalue.
public struct Assignment: Statement {

  /// The lvalue being assigned.
  public let lhs: ExpressionIdentity

  /// The value assigned to the left-hand-side.
  public let rhs: ExpressionIdentity

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(lhs: ExpressionIdentity, rhs: ExpressionIdentity, site: SourceSpan) {
    self.lhs = lhs
    self.rhs = rhs
    self.site = site
  }

  /// Returns a textual representation of `self` using `program`.
  public func show(using program: Program) -> String {
    "\(program.show(lhs)) = \(program.show(rhs))"
  }

}
