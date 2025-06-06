/// The application of a function.
public struct Call: Expression {

  /// The way in which an entity is being applied.
  public enum Style: UInt8, Hashable, Sendable {

    /// Entity called with parentheses.
    case parenthesized

    /// Entity called with brackets.
    case bracketed

  }

  /// The function being applied.
  public let callee: ExpressionIdentity

  /// The arguments passed to the callee.
  public let arguments: [Labeled<ExpressionIdentity>]

  /// The way in which the arguments are passed.
  public let style: Style

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    callee: ExpressionIdentity,
    arguments: [Labeled<ExpressionIdentity>],
    style: Style,
    site: SourceSpan
  ) {
    self.callee = callee
    self.arguments = arguments
    self.style = style
    self.site = site
  }

  /// The labels of the arguments.
  public var labels: [String?] {
    arguments.map(\.label?.value)
  }

  /// Returns a textual representation of `self` using `program`.
  public func show(using program: Program) -> String {
    switch style {
    case .parenthesized:
      return "\(program.show(callee))(\(program.show(arguments)))"
    case .bracketed:
      return "\(program.show(callee))[\(program.show(arguments))]"
    }
  }

}
