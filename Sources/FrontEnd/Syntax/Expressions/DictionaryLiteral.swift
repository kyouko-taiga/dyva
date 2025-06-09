/// The expression of a dictionary literal.
public struct DictionaryLiteral: Expression {

  /// An entry in a dictionary literal.
  public struct Entry: Hashable, Sendable {

    /// The key labeling the entry.
    public let key: ExpressionIdentity

    /// The value of the entry.
    public let value: ExpressionIdentity

    /// Creates an instance with the given properties.
    public init(key: ExpressionIdentity, value: ExpressionIdentity) {
      self.key = key
      self.value = value
    }

  }

  /// The key/value pairs of the dictionary.
  public let elements: [Entry]

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(elements: [Entry], site: SourceSpan) {
    self.elements = elements
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "[\(module.show(elements))]"
  }

}

extension DictionaryLiteral.Entry: Showable {

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "\(module.show(key)) : \(module.show(value))"
  }

}
