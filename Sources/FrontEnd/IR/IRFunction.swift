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

  /// The name of the function.
  public let name: Name

  /// The argument labels of the function.
  public let labels: [String?]

  /// `true` iff `self` is the lowering of a subscript.
  public let isSubscript: Bool

  /// The basic blocks in the function, the first of which being the function's entry.
  public private(set) var blocks: [BasicBlock]

  /// The instructions in the function.
  public private(set) var instructions: List<any Instruction>

  /// A map from an instruction to the basic block in which it resides.
  public private(set) var container: [InstructionIdentity: BasicBlock.ID]

  /// The def-use chains of the values in this module.
  public private(set) var uses: [IRValue: [Use]]

  /// Creates a function that has the given `name` and that accepts arguments with `labels`.
  ///
  /// This initializer is meant to be called from `Module.addFunction(_:)`.
  internal init(name: Name, labels: [String?], isSubscript: Bool) {
    self.name = name
    self.labels = labels
    self.isSubscript = isSubscript
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

  /// Returns the identity of the first instruction in `b` that satisfies `p`, if any.
  public func first(
    of b: BasicBlock.ID, where p: (any Instruction) -> Bool
  ) -> InstructionIdentity? {
    contents(of: b).first(where: { (i) in p(instructions[i]) })
  }

  /// Returns the terminator of `b`, if any.
  public func terminator(of b: BasicBlock.ID) -> InstructionIdentity? {
    blocks[b].last.flatMap({ (i) in instructions[i].isTerminator ? i : nil })
  }

  /// Returns `true` iff `b` is terminated by a return instruction.
  public func isReturnBlock(_ b: BasicBlock.ID) -> Bool {
    if let i = terminator(of: b) {
      return instructions[i] is IRReturn
    } else {
      return false
    }
  }

  /// Returns the basic block in which `v` is defined, if any.
  public func blockDefining(_ v: IRValue) -> BasicBlock.ID? {
    switch v {
    case .register(let i):
      return container[i]
    case .parameter(let b, _):
      return b
    default:
      return nil
    }
  }

  /// Returns the last use of `v` in `b`, if any.
  public func lastUse(of v: IRValue, in b: BasicBlock.ID) -> Use? {
    for i in contents(of: b).reversed() {
      if let n = instructions[i].operands.lastIndex(of: v) {
        return Use(user: i, index: n)
      }
    }
    return nil
  }

  /// Returns the successors of `b`.
  public func successors(of b: BasicBlock.ID) -> [BasicBlock.ID] {
    if let i = blocks[b].last, let s = instructions[i] as? any Terminator {
      return s.successors
    } else {
      return []
    }
  }

  /// Returns the control flow graph of this function.
  public func controlFlow() -> ControlFlowGraph {
    var g = ControlFlowGraph()
    for a in blocks.indices {
      for b in successors(of: a) {
        g.define(a, predecessorOf: b)
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

  /// Inserts `instruction` at the start of `b` and returns its identity.
  @discardableResult
  public mutating func prepend<T: Instruction>(
    _ instruction: T, to b: BasicBlock.ID
  ) -> InstructionIdentity {
    if let i = blocks[b].first {
      return insert(instruction, before: i)
    } else {
      return insert(instruction) { (me, i) in
        let s = me.instructions.append(i)
        me.container[s] = b
        me.blocks[b].setFirst(s)
        return s
      }
    }
  }

  /// Inserts `instruction` at the end of `b` and returns its identity.
  @discardableResult
  public mutating func append<T: Instruction>(
    _ instruction: T, to b: BasicBlock.ID
  ) -> InstructionIdentity {
    if let i = blocks[b].last {
      return insert(instruction, after: i)
    } else {
      return insert(instruction) { (me, i) in
        let s = me.instructions.append(i)
        me.container[s] = b
        me.blocks[b].setLast(s)
        return s
      }
    }
  }

  /// Inserts `instruction` immediately before `j` and returns its identity.
  @discardableResult
  public mutating func insert<T: Instruction>(
    _ instruction: T, before j: InstructionIdentity
  ) -> InstructionIdentity {
    let b = container[j]!
    return insert(instruction) { (me, i) in
      let s = me.instructions.insert(i, before: j)
      me.container[s] = b
      if me.blocks[b].first == j {
        me.blocks[b].setFirst(s)
      }
      return s
    }
  }

  /// Inserts `instruction` immediately after `j` and returns its identity.
  @discardableResult
  public mutating func insert<T: Instruction>(
    _ instruction: T, after j: InstructionIdentity
  ) -> InstructionIdentity {
    let b = container[j]!
    assert(terminator(of: b) == nil, "insertion after terminator")
    return insert(instruction) { (me, i) in
      let s = me.instructions.insert(i, after: j)
      me.container[s] = b
      if me.blocks[b].last == j {
        me.blocks[b].setLast(s)
      }
      return s
    }
  }

  /// Inserts `instruction` at `boundary` and returns its identity.
  @discardableResult
  internal mutating func insert<T: Instruction>(
    _ instruction: T, at boundary: Lifetime.Boundary
  ) -> InstructionIdentity {
    switch boundary {
    case .start(let b):
      return prepend(instruction, to: b)
    case .before(let j):
      return insert(instruction, before: j)
    case .after(let j):
      return insert(instruction, after: j)
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

  /// Removes `i` and updates the def-use chains.
  ///
  /// - Requires: The result of `i` have no users.
  public mutating func remove(_ i: InstructionIdentity) {
    assert(uses[.register(i), default: []].isEmpty)
    removeUses(madeBy: i)
    instructions.remove(at: i)

    let b = container[i].sink()
    if blocks[b].first == i {
      if let j = instructions.address(after: i), j != blocks[b].last {
        blocks[b].setFirst(j)
      } else {
        assert(blocks[b].first == blocks[b].last)
        blocks[b].removeAll()
      }
    } else if blocks[b].last == i {
      if let j = instructions.address(before: i), j != blocks[b].last {
        blocks[b].setLast(j)
      } else {
        assert(blocks[b].first == blocks[b].last)
        blocks[b].removeAll()
      }
    }
  }

  /// Removes `i` from the def-use chains of its operands.
  private mutating func removeUses(madeBy i: InstructionIdentity) {
    for o in instructions[i].operands {
      uses[o]?.removeAll(where: { $0.user == i })
    }
  }

}

extension IRFunction: Showable {

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    // Write the signature.
    var result = "fun \(module.show(name))("
    for l in labels {
      result.write(l ?? "_")
      result.write(":")
    }
    result.write(")")

    // Nothing more to do if the function has no definition.
    if !isDefined { return result }

    // Otherwise, renders the basic blocks.
    result.write(" =\n")
    for b in blocks.indices {
      result.write("  b\(b) =\n")
      for s in contents(of: b) {
        let r = IRValue.register(s)
        let v = instructions[s].show(using: module)
        result.write("    \(r) = \(v)\n")
      }
    }

    return result
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
