/// Where an instruction should be inserted in a basic block.
public enum InsertionPoint: Hashable, Sendable {

  case start(of: BasicBlock.ID)

  /// The end of a basic block.
  case end(of: BasicBlock.ID)

  /// The block in which this insertion point falls.
  public var block: BasicBlock.ID {
    switch self {
    case .start(let b):
      return b
    case .end(let b):
      return b
    }
  }

}
