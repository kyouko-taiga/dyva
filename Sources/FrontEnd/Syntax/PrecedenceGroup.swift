/// The precedence and associativity of an operator.
public enum PrecedenceGroup: UInt8 {

  /// The assignment precedrence group, which is left associative.
  case assignment = 0

  /// The disjunction precedrence group, which is left associative.
  case disjunction

  /// The conjunction precedrence group, which is left associative.
  case conjunction

  /// The comparison precedrence group, which is left associative.
  case comparison

  /// The fallback precedrence group, which is right associative.
  case fallback

  /// The range precedrence group, which is left associative.
  case range

  /// The addition precedrence group, which is left associative.
  case addition

  /// The multiplication precedrence group, which is left associative.
  case multiplication

  /// The shift precedrence group, which is left associative.
  case shift

  /// The exponentiation precedrence group, which is right associative.
  case exponentiation

  /// A value ordered after all precedence groups.
  case max

  /// Creates the precedence group containing `op`.
  public init<T: StringProtocol>(containing op: T) {
    switch op {
    case "**":
      self = .exponentiation
    case "<<", ">>":
      self = .shift
    case "*", "/", "%":
      self = .multiplication
    case "+", "-":
      self = .addition
    case "..<", "...":
      self = .range
    case "??", "!!":
      self = .fallback
    case "==", "!=", "<", "<=", ">", ">=":
      self = .comparison
    case "^", "&", "&&":
      self = .conjunction
    case "|", "||":
      self = .disjunction
    case _ where op.last == "=":
      self = .assignment
    case _ where op.first == "&":
      self = .init(containing: op.dropFirst())
    default:
      self = .addition
    }
  }

  /// `true` iff `self` is right-associative.
  public var isRightAssociative: Bool {
    (self == .fallback) || (self == .exponentiation)
  }

  /// The precedence group ordered right after `self`.
  public var next: PrecedenceGroup {
    .init(rawValue: rawValue + 1) ?? .max
  }

}

extension PrecedenceGroup: Hashable {}

extension PrecedenceGroup: Comparable {

  /// Returns `true` iff `l` binds less tightly than `r`.
  public static func < (l: Self, r: Self) -> Bool {
    l.rawValue < r.rawValue
  }

}
