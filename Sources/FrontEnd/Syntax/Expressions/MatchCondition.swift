/// A pattern being used to match a scrutinee.
public struct MatchCondition: Syntax {

  /// The introducer of the condition.
  public let introducer: Token

  /// The pattern to match.
  public let pattern: PatternIdentity

  /// The expression of the scrutinee.
  public let scrutinee: ExpressionIdentity

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    introducer: Token,
    pattern: PatternIdentity,
    scrutinee: ExpressionIdentity,
    site: SourceSpan
  ) {
    self.introducer = introducer
    self.pattern = pattern
    self.scrutinee = scrutinee
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "case \(module.show(pattern)) = \(module.show(scrutinee))"
  }

}
