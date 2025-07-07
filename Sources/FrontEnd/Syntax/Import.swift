public struct Import: Statement, Syntax {
  public struct Binding: Sendable, Showable, Equatable {
    /// The imported identifier.
    public let importee: Name

    /// The renamed name of the binding
    public let rename: Name?

    public init(importee: Name, rename: Name?) {
      self.importee = importee
      self.rename = rename
    }

    /// The binding's name, which is either the `importee` or the `rename` if it exists.
    public var name: Name {
      rename ?? importee
    }

    public func show(using module: Module) -> String {
      if let rename = rename {
        return "\(importee) as \(rename)"
      } else {
        return "\(importee)"
      }
    }
  }

  /// The introducer of this statement.
  public let introducer: Token

  /// The bindings being imported.
  public let bindings: [Binding]

  /// The source of the import.
  public let source: String

  /// The site from which `self` was parsed.
  public let site: SourceSpan

  public init(
    introducer: Token,
    bindings: [Binding],
    source: String,
    site: SourceSpan
  ) {
    self.introducer = introducer
    self.bindings = bindings
    self.source = source
    self.site = site
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    "import \(bindings.map { $0.show(using: module) }.joined(by: ", ")) from \(source)"
  }
}
