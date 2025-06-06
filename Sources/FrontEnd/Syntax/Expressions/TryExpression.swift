/// A block for evaluating statements and catching the exceptions that they may throw.
public struct TryExpression: Expression {

  /// The statements whose exceptions are caught by this expression.
  public let body: Block.ID

  /// The exception handlers of this expression.
  public let handlers: [MatchCase.ID]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    body: Block.ID,
    handlers: [MatchCase.ID],
    site: SourceSpan
  ) {
    self.body = body
    self.handlers = handlers
    self.site = site
  }

  /// Returns a textual representation of `self` using `program`.
  public func show(using program: Program) -> String {
    var result = "\(program.show(body))\ncatch"
    for h in handlers {
      result.write("\n")
      result.write(program.show(h).indented)
    }
    return result
  }

}
