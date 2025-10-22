/// A pair representing the use of a value in an instruction.
public struct Use: Hashable, Sendable {

  /// The ID of the user that contains this use.
  public let user: InstructionIdentity

  /// The index of this use in `user`'s operands.
  public let index: Int

}
