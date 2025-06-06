/// An instance of one of two types.
public enum Either<Left, Right> {

  /// The "left" case.
  case left(Left)

  /// The "right" case.
  case right(Right)

  /// The associated value of `self` iff it is `.left`. Otherwise, `nil`.
  public var left: Left? {
    if case .left(let v) = self { v } else { nil }
  }

  /// The associated value of `self` iff it is `.right`. Otherwise, `nil`.
  public var right: Right? {
    if case .right(let v) = self { v } else { nil }
  }

}

extension Either: Equatable where Left: Equatable, Right: Equatable {}

extension Either: Hashable where Left: Hashable, Right: Hashable {}
