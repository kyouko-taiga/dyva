/// A while loop.
public struct While: Statement, Scope {

  /// The introducer of the loop.
  public let introducer: Token

  /// The list of conditions of this expression, which is not empty.
  public let conditions: [ConditionIdentity]

  /// The The body of the loop.
  public let body: Block.ID

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    introducer: Token,
    conditions: [ConditionIdentity],
    body: Block.ID,
    site: SourceSpan
  ) {
    self.introducer = introducer
    self.conditions = conditions
    self.body = body
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "while \(module.show(conditions)) \(module.show(body))"
  }

}
