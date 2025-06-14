import Utilities

/// The identity of an instruction in Dyva IR.
public struct InstructionIdentity: Hashable, Sendable {

  /// The identity of the basic block containing this instruction.
  public let block: BasicBlockIdentity

  /// The address of the instruction in its containing block.
  public let address: List<any Instruction>.Address

  /// Creates an instance with the given properties.
  public init(block: BasicBlockIdentity, address: List<any Instruction>.Address) {
    self.block = block
    self.address = address
  }

}


extension InstructionIdentity: CustomStringConvertible {

  public var description: String {
    "\(block).\(address)"
  }

}
