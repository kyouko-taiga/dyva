import Utilities

/// An instruction marking the entry into a region within an IR function.
public protocol RegionEntry: Instruction {}

extension RegionEntry {

  public typealias End = RegionEnd<Self>

}

/// The exit of a region.
public struct RegionEnd<T: RegionEntry>: Instruction {

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

extension RegionEnd: Showable {

  public func show(using module: Module) -> String {
    "end \(start)"
  }

}
