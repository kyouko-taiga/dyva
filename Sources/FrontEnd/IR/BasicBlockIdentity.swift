import Utilities

/// The identity of an basic block in Dyva IR.
public struct BasicBlockIdentity: Hashable, Sendable {

  /// The function in which the block lies.
  public let function: IRFunction.Identity

  /// The address of the block in its containing function.
  public let address: List<BasicBlock>.Address

  /// Creates an instance with the given properties.
  public init(function: Int, address: List<BasicBlock>.Address) {
    self.function = function
    self.address = address
  }

}

extension BasicBlockIdentity: CustomStringConvertible {

  public var description: String {
    address.description
  }

}
