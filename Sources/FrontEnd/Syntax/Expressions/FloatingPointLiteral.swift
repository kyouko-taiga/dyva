/// The expression of a floating-point literal.
public struct FloatingPointLiteral: Expression {

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(site: SourceSpan) {
    self.site = site
  }

  /// The value of the literal.
  public var value: Substring {
    site.text
  }

  /// Returns a textual representation of `self` using `program`.
  public func show(using program: Program) -> String {
    value.description
  }

}
