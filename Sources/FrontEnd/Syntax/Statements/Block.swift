/// A list of statements in an scope.
public struct Block: Statement, Scope {

  /// The introducer of this block.
  public let introducer: Token

  /// The statements in this block.
  public let statements: [StatementIdentity]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(introducer: Token, statements: [StatementIdentity], site: SourceSpan) {
    self.introducer = introducer
    self.statements = statements
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    var result = String(introducer.text)
    for s in statements {
      result.write("\n")
      result.write(module.show(s).indented)
    }
    return result
  }

}
