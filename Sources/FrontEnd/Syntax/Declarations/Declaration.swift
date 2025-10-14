/// A syntax tree denoting a declaration.
public protocol Declaration: Statement {}

/// A syntax tree denoting a declaration with an identifier.
public protocol IdentifierDeclaration: Declaration {
  var identifier: String { get }
}
