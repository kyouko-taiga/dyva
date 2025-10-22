/// The aquisition of an access to a value.
public struct IRAccess: RegionEntry {

  /// The operands of the instruction.
  public let operands: [IRValue]

  /// The capability requested by the access.
  public let capability: AccessEffect

  /// The site to which `self` is attached.
  public let anchor: SourceSpan

  /// Creates an instance with the given properties.
  public init(source: IRValue, capability: AccessEffect, anchor: SourceSpan) {
    self.operands = [source]
    self.capability = capability
    self.anchor = anchor
  }

  /// The value being accessed.
  public var source: IRValue {
    operands[0]
  }

  /// The arguments passed to the target.
  public var arguments: ArraySlice<IRValue> {
    operands[1...]
  }

  /// `true`.
  public var isExtendingOperandLifetimes: Bool {
    false
  }

}

extension IRAccess: Showable {

  public func show(using module: Module) -> String {
    "access \(capability) \(source)"
  }

}
