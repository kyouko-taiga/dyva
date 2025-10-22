/// A conditional jump.
public struct IRConditionalBranch: Terminator {

  /// The operands of the instruction.
  public let operands: [IRValue]

  /// The basic blocks to which control flow may transfer.
  public var successors: [BasicBlock.ID]

  /// The site to which `self` is attached.
  public let anchor: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    condition: IRValue,
    success: BasicBlock.ID,
    failure: BasicBlock.ID,
    anchor: SourceSpan,
  ) {
    self.operands = [condition]
    self.successors = [success, failure]
    self.anchor = anchor
  }

  /// A Boolean value.
  public var condition: IRValue {
    operands[0]
  }

  /// The target of the jump if `condition` is `true`.
  public var success: BasicBlock.ID {
    successors[0]
  }

  /// The target of the jump in `condition` is `false`.
  public var failure: BasicBlock.ID {
    successors[1]
  }

}

extension IRConditionalBranch: Showable {

  public func show(using module: Module) -> String {
    "condbr \(condition), b\(success), b\(failure)"
  }

}
