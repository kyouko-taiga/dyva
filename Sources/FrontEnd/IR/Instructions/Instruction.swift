/// An instruction in Dyva IR.
public protocol Instruction: Showable, Sendable {

  /// The operands of the instruction.
  var operands: [IRValue] { get }

  /// The site to which `self` is attached.
  var anchor: SourceSpan { get }

}

extension Instruction {

  public var operands: [IRValue] {
    []
  }

}

/// A namespace for instructions.
enum IR {}
