import Utilities

/// An instruction marking the entry into a region within an IR function.
public protocol IRRegionEntry: Instruction {}

extension IRRegionEntry {

  public typealias End = IRRegionEnd<Self>

}

/// The exit of a region.
public struct IRRegionEnd<T: IRRegionEntry>: Instruction {

  /// The operands of the instruction.
  public let operands: [IRValue]

  /// The region of the code corresponding to this instruction.
  public let anchor: SourceSpan

  /// Creates an instance with the given properties.
  public init(start: IRValue, anchor: SourceSpan) {
    self.operands = [start]
    self.anchor = anchor
  }

  /// The instruction starting the region being exited.
  public var start: IRValue {
    operands[0]
  }

}

extension IRRegionEnd: Showable {

  public func show(using module: Module) -> String {
    "end \(start)"
  }

}
