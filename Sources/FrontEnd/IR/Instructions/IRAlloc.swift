extension IR {

  /// An instruction that allocates storage for a local value.s
  public struct Alloc: Instruction {

    /// The site to which `self` is attached.
    public let anchor: SourceSpan

    /// Creates an instance with the given properties.
    public init(anchor: SourceSpan) {
      self.anchor = anchor
    }

    /// The operands of the instruction.
    public var operands: [IRValue] { [] }

  }

}

extension IR.Alloc: Showable {

  public func show(using module: Module) -> String {
    "alloc"
  }

}
