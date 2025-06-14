/// A constant value.
public enum IRConstant: Hashable, Sendable {

  /// A unit value.
  case unit

  /// A Boolean value.
  case bool(Bool)

  /// A 64-bit signed integer.
  case i64(Int64)

  /// A free function.
  case function(IRFunction.Identity)

  /// The built-in `print` function.
  case print

  /// The built-in `type(of:)` function.
  case type

}

extension IRConstant: CustomStringConvertible {

  public var description: String {
    switch self {
    case .unit:
      return "()"
    case .bool(let b):
      return b.description
    case .i64(let n):
      return "i64 \(n)"
    case .function(let n):
      return "<function(\(n))>"
    case .print:
      return "print"
    case .type:
      return "type"
    }
  }

}
