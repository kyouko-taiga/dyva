/// An operator notation.
public enum OperatorNotation: UInt8, Sendable {

  /// No notation.
  case none = 0

  /// The infix notation.
  case infix = 1

  /// The prefix notation.
  case prefix = 2

  /// The postfix notation.
  case postfix = 3

}

/// An unqualified name denoting an entity.
public struct Name: Hashable, Sendable {

  /// The identifier of the referred entity.
  public let identifier: String

  /// The operator notation of the referred entity, given that it is an operator.
  public let notation: OperatorNotation

  /// Creates an instance with the given properties.
  public init(identifier: String, notation: OperatorNotation = .none) {
    self.identifier = identifier
    self.notation = notation
  }

  /// Returns `true` iff `scrutinee` can be used to refer to a declaration named after `pattern`.
  public static func ~= (pattern: String, scrutinee: Name) -> Bool {
    (scrutinee.notation == .none) && (scrutinee.identifier == pattern)
  }

}

extension Name: CustomStringConvertible {

  public var description: String {
    if notation != .none {
      return "\(notation)\(identifier)"
    } else {
      return identifier
    }
  }

}
