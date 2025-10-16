/// An instruction in Dyva IR.
public protocol Instruction: Showable, Sendable {

  /// The operands of the instruction.
  var operands: [IRValue] { get }

  /// The site to which `self` is attached.
  var anchor: SourceSpan { get }

}

extension Instruction {

  /// `true` iff `self` is a terminator instruction.
  public var isTerminator: Bool {
    self is any Terminator
  }

  public var operands: [IRValue] {
    []
  }

}

/// A namespace for instructions.
enum IR {}
