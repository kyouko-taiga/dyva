/// A conditional expression whose branches match a pattern against a scrutinee.
public struct MatchExpression: Expression {

  /// The expression of the scrutinee.
  public let scrutinee: ExpressionIdentity

  /// The cases of the expression.
  public let branches: [MatchCase.ID]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(scrutinee: ExpressionIdentity, branches: [MatchCase.ID], site: SourceSpan) {
    self.scrutinee = scrutinee
    self.branches = branches
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    var result = "match \(module.show(scrutinee))"
    for b in branches {
      result.write("\n")
      result.write(module.show(b).indented)
    }
    return result
  }

}
