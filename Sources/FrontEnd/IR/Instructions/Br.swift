extension IR {

  /// An unconditional jump.
  public struct Br: Terminator {

    /// The operands of the instruction.
    public let operands: [IRValue]

    /// The basic blocks to which control flow may transfer.
    public let successors: [BasicBlock.ID]

    /// The site to which `self` is attached.
    public let anchor: SourceSpan

    /// Creates an instance with the given properties.
    public init(target: BasicBlock.ID, arguments: [IRValue], anchor: SourceSpan) {
      self.operands = arguments
      self.successors = [target]
      self.anchor = anchor
    }

    /// The arguments passed to the target.
    public var arguments: [IRValue] {
      operands
    }

    /// The target of the jump.
    public var target: BasicBlock.ID {
      successors[0]
    }

  }

}

extension IR.Br: Showable {

  public func show(using module: Module) -> String {
    "br b\(target)(\(arguments.descriptions()))"
  }

}
