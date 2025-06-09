/// A control statement for returning a value from the innermost enclosing function.
public struct Return: Statement {

  /// The introducer of this statement.
  public let introducer: Token

  /// The value being returned, if explicit.
  public let value: ExpressionIdentity?

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(introducer: Token, value: ExpressionIdentity?, site: SourceSpan) {
    self.introducer = introducer
    self.value = value
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    if let v = value {
      return "return \(module.show(v))"
    } else {
      return "return"
    }
  }

}
