/// The expression of a Boolean literal.
public struct BooleanLiteral: Expression {

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(site: SourceSpan) {
    self.site = site
  }

  /// The value of the literal.
  public var value: Bool {
    site.text == "true"
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    value.description
  }

}
