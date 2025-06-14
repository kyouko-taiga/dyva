/// Where an instruction should be inserted in a basic block.
public enum InsertionPoint: Hashable, Sendable {

  /// The start of a basic block.
  case start(BasicBlockIdentity)

  /// The end of a basic block.
  case end(BasicBlockIdentity)

  /// After another instruction.
  case after(InstructionIdentity)

  /// The block in which this insertion point falls.
  public var block: BasicBlockIdentity {
    switch self {
    case .start(let b):
      return b
    case .end(let b):
      return b
    case .after(let i):
      return i.block
    }
  }

  /// The function in which this insertion point falls.
  public var function: IRFunction.Identity {
    block.function
  }

}
