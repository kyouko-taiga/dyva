/// A construct whose representation was parsed from a source files.
public struct Parsed<T> {

  /// The parsed construct.
  public let value: T

  /// The site from which `self` was extracted.
  public let site: SourceSpan

  /// Creates an instance annotating its value with the site from which it was extracted.
  public init(_ value: T, at site: SourceSpan) {
    self.value = value
    self.site = site
  }

}

extension Parsed: Equatable where T: Equatable {}

extension Parsed: Hashable where T: Hashable {}

extension Parsed: Sendable where T: Sendable {}

extension Parsed: CustomStringConvertible {

  public var description: String {
    String(describing: value)
  }

}
