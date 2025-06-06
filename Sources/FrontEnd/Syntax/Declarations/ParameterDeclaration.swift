/// The declaration of a function parameter.
public struct ParameterDeclaration: Declaration {

  /// The label of the parameter, if any.
  public let label: String?

  /// The name of the parameter.
  public let identifier: String

  /// The passing convention of the parameter, if explicit.
  public let convention: Parsed<BindingPattern.Introducer>?

  /// The default value of the parameter, if any.
  public let defaultValue: ExpressionIdentity?

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    label: String?,
    identifier: String,
    convention: Parsed<BindingPattern.Introducer>?,
    defaultValue: ExpressionIdentity?,
    site: SourceSpan
  ) {
    self.label = label
    self.identifier = identifier
    self.convention = convention
    self.defaultValue = defaultValue
    self.site = site
  }

  /// Returns a textual representation of `self` using `program`.
  public func show(using program: Program) -> String {
    var result = ""
    if let l = label {
      result.write("\(l) \(identifier)")
    } else {
      result.write(identifier)
    }
    if let c = convention {
      result.write(": \(c.value)")
    }
    if let v = defaultValue {
      result.write(" = \(program.show(v))")
    }
    return result
  }

}
