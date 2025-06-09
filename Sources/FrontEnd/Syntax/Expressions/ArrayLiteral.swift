/// The expression of an array literal.
public struct ArrayLiteral: Expression {

  /// The elements of the array.
  public let elements: [ExpressionIdentity]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(elements: [ExpressionIdentity], site: SourceSpan) {
    self.elements = elements
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "[\(module.show(elements))]"
  }

}
