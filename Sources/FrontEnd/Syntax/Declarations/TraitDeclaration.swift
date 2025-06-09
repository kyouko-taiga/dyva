/// The declaration of a trait.
public struct TraitDeclaration: Declaration, Scope {

  /// The keyword introducing this declaration.
  public let introducer: Token

  /// The name of the declared trait.
  public let identifier: String

  /// The expression of the parent traits to which the conforming types must also conform.
  public let interfaces: [ExpressionIdentity]

  /// The member requirements of the trait.
  public let members: [FunctionDeclaration.ID]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    introducer: Token,
    identifier: String,
    interfaces: [ExpressionIdentity],
    members: [FunctionDeclaration.ID],
    site: SourceSpan
  ) {
    self.introducer = introducer
    self.identifier = identifier
    self.interfaces = interfaces
    self.members = members
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    var result = "trait \(identifier)"
    if !interfaces.isEmpty {
      result.write(" is ")
      result.write(module.show(interfaces, separatedBy: " & "))
    }
    if !members.isEmpty {
      result.write(" where")
      for m in members {
        result.write("\n")
        result.write(module.show(m).indented)
      }
    }
    return result
  }

}
