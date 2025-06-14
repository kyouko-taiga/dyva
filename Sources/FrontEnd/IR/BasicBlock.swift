import Utilities

/// A basic block in a Dyva IR function.
public struct BasicBlock: Sendable {

  /// The number of arguments that the block accepts.
  public var parameterCount: Int

  /// The instructions in the block.
  public var instructions: List<any Instruction>

  /// Creates an empty block taking `n` parameters.
  public init(parameterCount n: Int) {
    self.parameterCount = n
    self.instructions = []
  }

}
