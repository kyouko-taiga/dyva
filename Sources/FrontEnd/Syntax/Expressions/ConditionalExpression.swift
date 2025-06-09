/// A conditional expression with two branches.
public struct ConditionalExpression: Expression, Scope {

  /// The introducer of this expression.
  public let introducer: Token

  /// The list of conditions of this expression, which is not empty.
  public let conditions: [ConditionIdentity]

  /// The code executed if the condition holds.
  public let success: Block.ID

  /// The code executed if the condition does not hold, if any.
  public let failure: ElseIdentity?

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    introducer: Token,
    conditions: [ConditionIdentity],
    success: Block.ID,
    failure: ElseIdentity?,
    site: SourceSpan
  ) {
    self.introducer = introducer
    self.conditions = conditions
    self.success = success
    self.failure = failure
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    var result = "if \(module.show(conditions)) \(module.show(success))"
    if let f = failure {
      result.write("\n\(module.show(f))")
    }
    return result
  }

}
