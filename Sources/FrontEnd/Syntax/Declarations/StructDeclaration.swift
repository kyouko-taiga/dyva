/// The declaration of a struct.
public struct StructDeclaration: Declaration, Scope {

  /// The keyword introducing this declaration.
  public let introducer: Token

  /// The name of the declared struct.
  public let identifier: String

  /// The fields of the declared struct.
  public let fields: [FieldDeclaration.ID]

  /// The expression of the traits to which the struct must conform.
  public let interfaces: [ExpressionIdentity]

  /// The member functions of the struct.
  public let members: [FunctionDeclaration.ID]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    introducer: Token,
    identifier: String,
    fields: [FieldDeclaration.ID],
    interfaces: [ExpressionIdentity],
    members: [FunctionDeclaration.ID],
    site: SourceSpan
  ) {
    self.introducer = introducer
    self.identifier = identifier
    self.fields = fields
    self.interfaces = interfaces
    self.members = members
    self.site = site
  }

  /// Returns a textual representation of `self` using `program`.
  public func show(using program: Program) -> String {
    var result = "struct \(identifier)(\(program.show(fields)))"
    if !interfaces.isEmpty {
      result.write(" is ")
      result.write(program.show(interfaces, separatedBy: " & "))
    }
    if !members.isEmpty {
      result.write(" where")
      for m in members {
        result.write("\n")
        result.write(program.show(m).indented)
      }
    }
    return result
  }

}
