/// An access effect, specifying how a projection is accessed.
public enum AccessEffect: UInt8, Sendable {

  /// Value is accessed immutably.
  case `let` = 1

  /// Value is accessed mutably.
  case `inout` = 2

  /// Value is consumed.
  case sink = 4

  /// Creates an instance corresponding to the capability of a binding introduced by `i`.
  public init(_ i: BindingPattern.Introducer) {
    switch i {
    case .let: self = .let
    case .inout: self = .inout
    case .var: self = .sink
    }
  }

}

extension AccessEffect: Comparable {

  public static func < (l: Self, r: Self) -> Bool {
    l.rawValue < r.rawValue
  }

}
