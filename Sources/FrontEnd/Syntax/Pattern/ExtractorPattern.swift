/// A pattern for extracting values with an extractor.
public struct ExtractorPattern: Pattern {

  /// The expression of the extractor's name.
  public let extractor: ExpressionIdentity

  /// The elements of the pattern.
  public let elements: [Labeled<PatternIdentity>]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    extractor: ExpressionIdentity,
    elements: [Labeled<PatternIdentity>],
    site: SourceSpan
  ) {
    self.extractor = extractor
    self.elements = elements
    self.site = site
  }

  /// Returns a textual representation of `self` using `program`.
  public func show(using program: Program) -> String {
    ".\(program.show(extractor))(\(program.show(elements)))"
  }

}
