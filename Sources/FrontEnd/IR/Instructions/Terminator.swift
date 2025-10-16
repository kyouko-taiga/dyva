/// An instruction that causes control flow to transfer.
protocol Terminator: Instruction {

  /// The basic blocks to which control flow may transfer.
  var successors: [BasicBlock.ID] { get }

}
