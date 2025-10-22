/// An instruction that allocates storage for a local value.s
public struct IRAlloc: Instruction {

  /// The site to which `self` is attached.
  public let anchor: SourceSpan

  /// Creates an instance with the given properties.
  public init(anchor: SourceSpan) {
    self.anchor = anchor
  }

  /// The operands of the instruction.
  public var operands: [IRValue] { [] }

}

extension IRAlloc: Showable {

  public func show(using module: Module) -> String {
    "alloc"
  }

}
