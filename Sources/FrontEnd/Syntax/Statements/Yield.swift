/// A control statement for projecting a value from the innermost enclosing subscript.
public struct Yield: Statement {

  /// The introducer of this statement.
  public let introducer: Token

  /// The value being projected.
  public let value: ExpressionIdentity

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(introducer: Token, value: ExpressionIdentity, site: SourceSpan) {
    self.introducer = introducer
    self.value = value
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "yield \(module.show(value))"
  }

}
