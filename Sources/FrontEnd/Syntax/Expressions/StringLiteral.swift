/// The expression of a string literal.
public struct StringLiteral: Expression {

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(site: SourceSpan) {
    self.site = site
  }

  /// The value of the literal.
  public var value: Substring {
    site.text.dropFirst().dropLast()
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    value.description
  }

}
