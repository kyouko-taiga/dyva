/// A case in a matching or try expression.
public struct MatchCase: Scope {

  /// The introducer of this case.
  public let introducer: Token

  /// The expression being compared with each pattern.
  public let pattern: PatternIdentity

  /// The body of the case.
  public let body: [StatementIdentity]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    introducer: Token,
    pattern: PatternIdentity,
    body: [StatementIdentity],
    site: SourceSpan
  ) {
    self.introducer = introducer
    self.pattern = pattern
    self.body = body
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    var result = "case \(module.show(pattern)) do"

    if let s = body.uniqueElement {
      result.write(" \(module.show(s))")
    } else {
      for s in body {
        result.write("\n")
        result.write(module.show(s).indented)
      }
    }

    return result
  }

}
