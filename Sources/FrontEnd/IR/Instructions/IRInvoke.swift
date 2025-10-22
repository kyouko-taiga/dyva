/// The application of a function in Dyva IR.
public struct IRInvoke: Instruction {

  /// The labels of the arguments.
  public let labels: [String?]

  /// The operands of the instruction.
  public let operands: [IRValue]

  /// The site to which `self` is attached.
  public let anchor: SourceSpan

  /// Creates an instance with the given properties.
  public init(
    callee: IRValue,
    labels: [String?],
    arguments: [IRValue],
    anchor: SourceSpan
  ) {
    self.operands = [callee] + arguments
    self.labels = labels
    self.anchor = anchor
  }

  /// The function being applied.
  public var callee: IRValue {
    operands[0]
  }

  /// The arguments passed to the target.
  public var arguments: ArraySlice<IRValue> {
    operands[1...]
  }

}

extension IRInvoke: Showable {

  public func show(using module: Module) -> String {
    var result = "invoke \(callee)("

    var first = true
    for (l, a) in zip(labels, arguments) {
      if first { first = false } else { result.write(", ") }
      if let s = l {
        result.write("\(s): \(a)")
      } else {
        result.write(a.description)
      }
    }

    result.write(")")
    return result
  }

}
