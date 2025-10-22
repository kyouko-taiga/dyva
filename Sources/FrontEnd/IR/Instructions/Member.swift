extension IR {

  /// The selection of a value's member.
  public struct Member: Instruction {

    /// The name or index of a member.
    public enum NameOrIndex: Hashable, Sendable {

      /// A name.
      case name(Name)

      /// An index.
      case index(Int)

    }

    /// The operands of the instruction.
    public let operands: [IRValue]

    /// The name or index of the selected member.
    public let member: NameOrIndex

    /// The site to which `self` is attached.
    public let anchor: SourceSpan

    /// Creates an instance with the given properties.
    public init(whole: IRValue, member: NameOrIndex, anchor: SourceSpan) {
      self.operands = [whole]
      self.member = member
      self.anchor = anchor
    }

    /// The value of which a member is being selected.
    public var whole: IRValue {
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

}

extension IR.Member: Showable {

  public func show(using module: Module) -> String {
    "member \(member) of \(whole)"
  }

}

