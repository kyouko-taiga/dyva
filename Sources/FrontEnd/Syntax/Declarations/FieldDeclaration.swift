/// The declaration of a field in a struct.
public struct FieldDeclaration: Declaration {

  /// The name of the field.
  public let identifier: String

  /// The default value of the field, if any.
  public let defaultValue: ExpressionIdentity?

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(identifier: String, defaultValue: ExpressionIdentity?, site: SourceSpan) {
    self.identifier = identifier
    self.defaultValue = defaultValue
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    if let v = defaultValue {
      return "\(identifier) = \(module.show(v))"
    } else {
      return identifier
    }
  }

}
