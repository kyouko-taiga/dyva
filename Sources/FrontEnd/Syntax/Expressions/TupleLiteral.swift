/// The expression of a tuple expression.
public struct TupleLiteral: Expression {

  /// The elements of the tuple.
  public let elements: [Labeled<ExpressionIdentity>]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(elements: [Labeled<ExpressionIdentity>], site: SourceSpan) {
    self.elements = elements
    self.site = site
  }

  /// Returns a textual representation of `self` using `program`.
  public func show(using program: Program) -> String {
    if elements.count == 1 {
      return "(\(program.show(elements)),)"
    } else {
      return "(\(program.show(elements)))"
    }
  }

}
