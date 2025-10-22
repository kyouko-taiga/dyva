import Utilities

/// A basic block in a Dyva IR function.
public struct BasicBlock: Sendable {

  /// The identity of a basic block.
  public typealias ID = Int

  /// The number of arguments that the block accepts.
  public let parameterCount: Int

  /// The first instruction in `self`, if any.
  public private(set) var first: InstructionIdentity?

  /// The last instruction in `self`, if any.
  public private(set) var last: InstructionIdentity?

  /// Creates an empty block taking `n` parameters.
  public init(parameterCount n: Int) {
    self.parameterCount = n
    self.first = nil
    self.last = nil
  }

  /// Assigns the first instruction of `self`.
  internal mutating func setFirst(_ i: InstructionIdentity) {
    first = i
    if last == nil { last = i }
  }

  /// Assigns the last instruction of `self`.
  internal mutating func setLast(_ i: InstructionIdentity) {
    last = i
    if first == nil { first = i }
  }

}
