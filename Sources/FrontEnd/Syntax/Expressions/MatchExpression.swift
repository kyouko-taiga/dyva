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

  /// Returns a textual representation of `self` using `program`.
  public func show(using program: Program) -> String {
    var result = "match \(program.show(scrutinee))"
    for b in branches {
      result.write("\n")
      result.write(program.show(b).indented)
    }
    return result
  }

}
