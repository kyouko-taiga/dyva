extension IR {

  /// The aquisition of an access to a value.
  public struct Access: Instruction {

    /// The operands of the instruction.
    public let operands: [IRValue]

    /// The site to which `self` is attached.
    public let anchor: SourceSpan

    /// Creates an instance with the given properties.
    public init(source: IRValue, anchor: SourceSpan) {
      self.operands = [source]
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

  }

}

extension IR.Access: Showable {

  public func show(using module: Module) -> String {
    "access \(source)"
  }

}

