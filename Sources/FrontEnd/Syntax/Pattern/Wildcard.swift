/// A pattern that matches any scrutinee.
public struct Wildcard: Pattern {

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(site: SourceSpan) {
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "_"
  }

}
