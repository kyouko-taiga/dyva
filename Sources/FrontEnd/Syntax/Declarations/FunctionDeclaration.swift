/// The declaration of a function.
public struct FunctionDeclaration: IdentifierDeclaration, Scope {

  /// The keyword introducing this declaration.
  public let introducer: Token

  /// The name of the function.
  public let name: Name

  public var identifier: String {
    name.identifier
  }

  /// The parameters of the function.
  public let parameters: [ParameterDeclaration.ID]

  /// The body of the function, if any.
  public let body: [StatementIdentity]?

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    introducer: Token,
    name: Name,
    parameters: [ParameterDeclaration.ID],
    body: [StatementIdentity]?,
    site: SourceSpan
  ) {
    self.introducer = introducer
    self.name = name
    self.parameters = parameters
    self.body = body
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    var result = "\(introducer.text) \(name)(\(module.show(parameters)))"
    if let b = body {
      result.write(" =")
      for s in b {
        result.write("\n")
        result.write(module.show(s).indented)
      }
    }
    return result
  }

}
