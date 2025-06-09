/// The declaration of a variable in a pattern binding.
public struct VariableDeclaration: Declaration, Pattern {

  /// The identifier of the declared variable.
  public let identifier: String

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(identifier: String, site: SourceSpan) {
    self.identifier = identifier
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    identifier.description
  }

}
