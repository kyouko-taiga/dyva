import Utilities

/// A function in Dyva IR.
public struct IRFunction: Sendable {

  /// The identity of an IR function.
  public typealias Identity = Int

  /// The name of an IR function.
  public enum Name: Hashable, Sendable {

    /// The main function.
    case main

    /// The lowered form of a function defined in sources.
    case lowered(FunctionDeclaration.ID)

  }

  /// The position of `self` in the containing module.
  internal let identity: Identity

  /// The argument labels of the function.
  public let labels: [String?]

  /// The basic blocks in the function, the first of which being the function's entry.
  public private(set) var blocks: [BasicBlock]

  /// The instructions in the function.
  public private(set) var instructions: List<any Instruction>

  /// A map from an instruction to the basic block in which it resides.
  public private(set) var container: [InstructionIdentity: BasicBlock.ID]

  /// The def-use chains of the values in this module.
  public private(set) var uses: [IRValue: [Use]]

  /// Creates a function that has the given `identity` and that accepts arguments with `labels`.
  public init(identity: Identity, labels: [String?]) {
    self.identity = identity
    self.labels = labels
    self.blocks = []
    self.instructions = []
    self.container = [:]
    self.uses = [:]
  }

  /// `true` iff `self` has an entry block.
  public var isDefined: Bool {
    !blocks.isEmpty
  }

  /// The entry of this function, if any.
  public var entry: BasicBlock? {
    blocks.first
  }

  /// Returns the last instruction of `b`, if any.
  public func last(of b: BasicBlock.ID) -> (any Instruction)? {
    blocks[b].last.map({ (i) in instructions[i] })
  }

  /// Returns the instructions of `b`.
  public func contents(of b: BasicBlock.ID) -> some Sequence<InstructionIdentity> {
    var next = blocks[b].first
    let last = blocks[b].last
    return AnyIterator {
      if let n = next {
        next = (n != last) ? instructions.address(after: n) : nil
        return n
      } else {
        return nil
      }
    }
  }

  /// Returns the control flow graph of this function.
  func controlFlow() -> ControlFlowGraph {
    var g = ControlFlowGraph()
    for a in blocks.indices {
      if let s = blocks[a].last, let i = instructions[s] as? any Terminator {
        for b in i.successors {
          g.define(a, predecessorOf: b)
        }
      }
    }
    return g
  }

  /// Appends a basic block taking `n` parameters to this function.
  @discardableResult
  public mutating func appendBlock(parameterCount n: Int) -> BasicBlock.ID {
    let b = blocks.count
    blocks.append(.init(parameterCount: n))
    return b
  }

  /// Adds `instruction` at the end of `b` and returns its identity.
  @discardableResult
  public mutating func append<T: Instruction>(
    _ instruction: T, to b: BasicBlock.ID
  ) -> InstructionIdentity {
    assert(!(last(of: b)?.isTerminator ?? false), "insertion after terminator")
    return insert(instruction) { (me, i) in
      let s = me.instructions.append(i)
      me.container[s] = b
      me.blocks[b].setLast(s)
      return s
    }
  }

  /// Adds `instruction` at the start of `b` and returns its identity.
  @discardableResult
  public mutating func prepend<T: Instruction>(
    _ instruction: T, to b: BasicBlock.ID
  ) -> InstructionIdentity {
    insert(instruction) { (me, i) in
      let s = me.instructions.prepend(i)
      me.container[s] = b
      me.blocks[b].setFirst(s)
      return s
    }
  }

  /// Inserts `instruction` with `impl` and returns its identity.
  private mutating func insert<T: Instruction>(
    _ instruction: T, with impl: (inout Self, T) -> InstructionIdentity
  ) -> InstructionIdentity {
    // Insert the instruction.
    let user = impl(&self, instruction)

    // Update the def-use chains.
    for a in 0 ..< instruction.operands.count {
      uses[instruction.operands[a], default: []].append(Use(user: user, index: a))
    }

    return user
  }

}

extension IRFunction.Name: Showable {

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    switch self {
    case .main:
      return "$main"
    case .lowered(let d):
      return module[d].name.description
    }
  }

}
