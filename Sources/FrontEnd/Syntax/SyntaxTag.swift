/// The type of a node in an abstract syntax tree.
public struct SyntaxTag: Sendable {

  /// The underlying value of `self`.
  public let value: any Syntax.Type

  /// Creates an instance with the given underlying value.
  public init(_ value: any Syntax.Type) {
    self.value = value
  }

  /// Returns `true` iff `scrutinee` and `pattern` denote the same node type.
  public static func ~= (pattern: any Syntax.Type, scrutinee: Self) -> Bool {
    scrutinee == pattern
  }

  /// Returns `true` iff `l` and `r` denote the same node type.
  public static func == (l: Self, r: any Syntax.Type) -> Bool {
    l.value == r
  }

  /// Returns `true` iff `l` and `r` denote the same node type.
  public static func == (l: Self, r: (any Syntax.Type)?) -> Bool {
    l.value == r
  }

}

extension SyntaxTag: Equatable {

  public static func == (l: Self, r: Self) -> Bool {
    l.value == r.value
  }

}

extension SyntaxTag: Hashable {

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(value))
  }

}

extension SyntaxTag: CustomStringConvertible {

  public var description: String {
    String(describing: value)
  }

}
