import OrderedCollections
import Utilities

/// A Dyva program.
public struct Program {

  /// The identity of a source file.
  public typealias SourceIdentity = UInt32

  /// A source file added to a program.
  internal struct SourceContainer: Sendable {

    /// The position of `self` in the containing program.
    internal let identity: SourceIdentity

    /// The source file contained in `self`.
    internal let source: SourceFile

    /// The abstract syntax of `source`'s contents.
    internal var syntax: [AnySyntax] = []

    /// A table from syntax tree to its tag.
    internal var syntaxToTag: [SyntaxTag] = []

    /// The root of the syntax trees in `self`, which may be subset of the top-level declarations.
    internal var roots: [DeclarationIdentity] = []

    /// A table from syntax tree to the scope that contains it.
    ///
    /// The keys and values of the table are the offsets of the syntax trees in the source file
    /// (i.e., syntax identities sans module or source offset). Top-level declarations are mapped
    /// onto `-1`.
    internal var syntaxToParent: [Int] = []

    /// The diagnostics accumulated during compilation.
    internal var diagnostics = OrderedSet<Diagnostic>()

    /// Projects the node identified by `n`.
    internal subscript<T: SyntaxIdentity>(n: T) -> any Syntax {
      assert(n.file == identity)
      return syntax[n.offset].wrapped
    }

    /// Returns the tag of `n`.
    internal func tag<T: SyntaxIdentity>(of n: T) -> SyntaxTag {
      assert(n.file == identity)
      return syntaxToTag[n.offset]
    }

    /// Inserts `child` into `self`.
    internal mutating func insert<T: Syntax>(_ child: T) -> T.ID {
      let d = syntax.count
      syntax.append(.init(child))
      syntaxToTag.append(.init(T.self))
      syntaxToParent.append(-1)
      return T.ID(uncheckedFrom: .init(file: identity, offset: d))
    }

    /// Adds a diagnostic to this file.
    ///
    /// - requires: The diagnostic is anchored at a position in `self`.
    internal mutating func addDiagnostic(_ d: Diagnostic) {
      assert(d.site.source.name == source.name)
      diagnostics.append(d)
    }

  }

  /// The source files in the module.
  internal private(set) var sources = OrderedDictionary<FileName, SourceContainer>()

  /// Creates an empty program.
  public init() {
  }

  /// `true` if the program has errors.
  public var containsError: Bool {
    diagnostics.contains(where: { (d) in d.level == .error })
  }

  /// The diagnostics of the issues in the program.
  public var diagnostics: some Collection<Diagnostic> {
    sources.values.map(\.diagnostics).joined()
  }

  /// Adds a source file to this module.
  @discardableResult
  public mutating func addSource(
    _ s: SourceFile
  ) -> (inserted: Bool, identity: SourceIdentity) {
    if let f = sources.index(forKey: s.name) {
      return (inserted: false, identity: UInt32(f))
    } else {
      var f = SourceContainer(identity: UInt32(sources.count), source: s)
      Parser.parse(s, into: &f)
      sources[s.name] = f
      return (inserted: true, identity: f.identity)
    }
  }

  /// Projects the source file identified by `f`.
  internal subscript(f: SourceIdentity) -> SourceContainer {
    get {
      sources.values[Int(f)]
    }
    _modify {
      yield &sources.values[Int(f)]
    }
  }

  /// Projects the node identified by `n`.
  public subscript<T: SyntaxIdentity>(n: T) -> any Syntax {
    self[n.file][n]
  }

  /// Projects the node identified by `n`.
  public subscript<T: Syntax>(n: T.ID) -> T {
    self[n.file][n] as! T
  }

  /// Returns the tag of `n`.
  public func tag<T: SyntaxIdentity>(of n: T) -> SyntaxTag {
    self[n.file].tag(of: n)
  }

  /// Returns a textual representation of `item`.
  public func show<T: Showable>(_ item: T) -> String {
    item.show(using: self)
  }

  /// Returns a textual representation of `items`, separating each element by `separator`.
  public func show<T: Sequence>(
    _ items: T, separatedBy separator: String = ", "
  ) -> String where T.Element: Showable {
    items.map({ (n) in show(n) }).joined(separator: separator)
  }

  /// Returns a textual representation of the top-level declarations of `f`.
  public func show(_ f: SourceIdentity) -> String {
    self[f].roots.reduce(into: "") { (o, t) in
      o.write(show(t))
      o.write("\n")
    }
  }

}
