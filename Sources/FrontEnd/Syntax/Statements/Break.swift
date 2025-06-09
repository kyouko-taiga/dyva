/// A control statement for jumping after the innermost enclosing loop.
public struct Break: Statement {

  /// The introducer of this statement.
  public let introducer: Token

  /// The site from which `self` was parsed.
  public var site: SourceSpan { introducer.site }

  /// Creates an instance with the given properties.
  public init(introducer: Token) {
    self.introducer = introducer
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "break"
  }

}
