/// A reference to an entity.
public struct NameExpression: Expression {

  /// The qualification of the referred entity, if any.
  public let qualification: ExpressionIdentity?

  /// The name of the referred entity.
  public let name: Parsed<Name>

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(qualification: ExpressionIdentity?, name: Parsed<Name>, site: SourceSpan) {
    self.qualification = qualification
    self.name = name
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    if let q = qualification {
      return "\(module.show(q)).\(name)"
    } else {
      return name.description
    }
  }

}
