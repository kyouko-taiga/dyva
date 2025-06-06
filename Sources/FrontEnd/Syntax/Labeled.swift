/// An expression with an optional label.
public struct Labeled<T: SyntaxIdentity>: Hashable, Showable, Sendable {

  /// The label of the expression, if any.
  public let label: Parsed<String>?

  /// The syntax.
  public let syntax: T

  /// Creates an instance with the given properties.
  public init(label: Parsed<String>?, syntax: T) {
    self.label = label
    self.syntax = syntax
  }

  /// Returns a textual representation of `self` using `program`.
  public func show(using program: Program) -> String {
    let v = program.show(syntax)
    return if let l = label { "\(l): \(v)" } else { v }
  }

}
