/// A return instruction.
public struct IRReturn: Terminator {

  /// The operands of the instruction.
  public let operands: [IRValue]

  /// The site to which `self` is attached.
  public let anchor: SourceSpan

  /// Creates an instance with the given properties.
  public init(value: IRValue, anchor: SourceSpan) {
    self.operands = [value]
    self.anchor = anchor
  }

  /// The value being returned.
  public var value: IRValue {
    operands[0]
  }

  /// The basic blocks to which control flow may transfer.
  public var successors: [BasicBlock.ID] { [] }
}

extension IRReturn: Showable {

  public func show(using module: Module) -> String {
    "return \(value)"
  }

}
