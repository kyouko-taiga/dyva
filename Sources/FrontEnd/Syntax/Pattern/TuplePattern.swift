/// A pattern that matches tuples.
public struct TuplePattern: Pattern {

  /// The elements of the pattern.
  public let elements: [Labeled<PatternIdentity>]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(elements: [Labeled<PatternIdentity>], site: SourceSpan) {
    self.elements = elements
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    if elements.count == 1 {
      return "(\(module.show(elements)),)"
    } else {
      return "(\(module.show(elements)))"
    }
  }

}
