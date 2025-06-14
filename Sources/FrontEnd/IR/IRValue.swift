import Utilities

/// A value in Dyva IR.
public enum IRValue: Hashable, Sendable {

  /// The result of an instruction.
  case register(InstructionIdentity)

  /// The i-th parameter of a basic block.
  case parameter(BasicBlockIdentity, Int)

  /// A constant value.
  case constant(IRConstant)

  /// A poison value produced by an error.
  case poison(SourceSpan)

  /// Returns `true` iff `self` is neither `.register` nor `.parameter`.
  public var isConstant: Bool {
    switch self {
    case .register, .parameter:
      return false
    default:
      return true
    }
  }

}

extension IRValue: CustomStringConvertible {

  public var description: String {
    switch self {
    case .register(let s):
      return "%\(s)"
    case .parameter(let b, let i):
      return "b\(b).\(i)"
    case .constant(let c):
      return c.description
    case .poison:
      return "<poison>"
    }
  }

}
