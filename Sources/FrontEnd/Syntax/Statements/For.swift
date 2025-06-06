/// A for loop.
public struct For: Statement, Scope {

  /// The introducer of the loop.
  public let introducer: Token

  /// The main pattern of the loop.
  public let pattern: PatternIdentity

  /// The expression of the sequence over which the loop iterates.
  public let sequence: ExpressionIdentity

  /// The additional filtering conditions, if any.
  public let filters: [ConditionIdentity]

  /// The The body of the loop.
  public let body: Block.ID

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    introducer: Token,
    pattern: PatternIdentity,
    sequence: ExpressionIdentity,
    filters: [ConditionIdentity],
    body: Block.ID,
    site: SourceSpan
  ) {
    self.introducer = introducer
    self.pattern = pattern
    self.sequence = sequence
    self.filters = filters
    self.body = body
    self.site = site
  }

  /// Returns a textual representation of `self` using `program`.
  public func show(using program: Program) -> String {
    var result = "for \(program.show(pattern)) in \(program.show(sequence))"
    if !filters.isEmpty {
      result.write(" where ")
      result.write(program.show(filters))
    }
    result.write(" ")
    result.write(program.show(body))
    return result
  }

}
