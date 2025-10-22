/// An instruction that writes a value to a location.
public struct IRStore: Instruction {

  /// The operands of the instruction.
  public let operands: [IRValue]

  /// The site to which `self` is attached.
  public let anchor: SourceSpan

  /// Creates an instance with the given properties.
  public init(value: IRValue, target: IRValue, anchor: SourceSpan) {
    self.operands = [value, target]
    self.anchor = anchor
  }

  /// The value being stored.
  public var value: IRValue {
    operands[0]
  }

  /// Where the value is being written to.
  public var target: IRValue {
    operands[1]
  }

}

extension IRStore: Showable {

  public func show(using module: Module) -> String {
    "store \(value) to \(target)"
  }

}
