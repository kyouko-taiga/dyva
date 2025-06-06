/// A node in an abstract syntax tree.
public protocol Syntax: Equatable, Showable, Sendable {

  /// The site from which `self` was parsed.
  var site: SourceSpan { get }

}

extension Syntax {

  /// The identity of an instance of `Self`.
  public typealias ID = ConcreteSyntaxIdentity<Self>

  /// Returns `true` iff `self` is equal to `other`.
  public func equals(_ other: any Syntax) -> Bool {
    self == other as? Self
  }

}

/// A type-erasing container for nodes in an abstract syntax tree.
internal struct AnySyntax: Sendable {

  /// The node wrapped in this container.
  internal let wrapped: any Syntax

  /// Creates an instance wrapping `n`.
  internal init(_ n: any Syntax) {
    self.wrapped = n
  }

}

extension AnySyntax: Equatable {

  internal static func == (l: Self, r: Self) -> Bool {
    l.wrapped.equals(r.wrapped)
  }

}
