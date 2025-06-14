extension IR {

  /// A conditional jump.
  public struct CondBr: Terminator {

    /// The operands of the instruction.
    public let operands: [IRValue]

    /// The basic blocks to which control flow may transfer.
    public var successors: [BasicBlockIdentity]

    /// The site to which `self` is attached.
    public let anchor: SourceSpan

    /// Creates an instance with the given properties.
    public init(
      condition: IRValue,
      success: BasicBlockIdentity,
      failure: BasicBlockIdentity,
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
    public var success: BasicBlockIdentity {
      successors[0]
    }

    /// The target of the jump in `condition` is `false`.
    public var failure: BasicBlockIdentity {
      successors[1]
    }

  }

}

extension IR.CondBr: Showable {

  public func show(using module: Module) -> String {
    "condbr \(condition), b\(success), b\(failure)"
  }

}
