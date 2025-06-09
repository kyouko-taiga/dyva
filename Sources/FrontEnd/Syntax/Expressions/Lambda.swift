/// The expression of a term abstraction.
public struct Lambda: Expression, Scope {

  /// The introducer of this expression.
  public let introducer: Token

  /// The parameters of the function.
  public let parameters: [ParameterDeclaration.ID]

  /// The body of the abstraction.
  public let body: [StatementIdentity]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    introducer: Token,
    parameters: [ParameterDeclaration.ID],
    body: [StatementIdentity],
    site: SourceSpan
  ) {
    self.introducer = introducer
    self.parameters = parameters
    self.body = body
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    var result = "\\(\(module.show(parameters))) in"
    for s in body {
      result.write("\n")
      result.write(module.show(s).indented)
    }
    return result
  }

}
