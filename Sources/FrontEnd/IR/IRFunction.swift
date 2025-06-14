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
  public private(set) var blocks: List<BasicBlock>

  /// The def-use chains of the values in this module.
  public private(set) var uses: [IRValue: [Use]] = [:]

  /// Creates a function that has the given `identity` and that accepts arguments with `labels`.
  public init(identity: Identity, labels: [String?]) {
    self.identity = identity
    self.labels = labels
    self.blocks = []
  }

  /// `true` iff `self` has an entry block.
  public var isDefined: Bool {
    !blocks.isEmpty
  }

  /// The entry of this function, if any.
  public var entry: BasicBlock? {
    blocks.first
  }

  /// Appends a basic block taking `n` parameters to this function.
  @discardableResult
  public mutating func appendBlock(parameterCount n: Int) -> BasicBlockIdentity {
    .init(function: identity, address: blocks.append(.init(parameterCount: n)))
  }

  /// Inserts instruction `i` into `self` at boundary `p` and returns its identity.
  public mutating func insert<T: Instruction>(
    _ i: T, at p: InsertionPoint
  ) -> InstructionIdentity {
    switch p {
    case .start(let b):
      return prepend(i, to: b)
    case .end(let b):
      return append(i, to: b)
    case .after(let j):
      return insert(i, after: j)
    }
  }

  /// Inserts `newInstruction` after `predecessor` and returns its identity.
  @discardableResult
  mutating func insert(
    _ i: Instruction, after p: InstructionIdentity
  ) -> InstructionIdentity {
    insert(i) { (me, i) in
      InstructionIdentity(
        block: p.block,
        address: me.blocks[p.block.address].instructions.insert(i, after: p.address))
    }
  }

  /// Adds `i` at the end of `b` and returns its identity.
  public mutating func append<T: Instruction>(
    _ i: T, to b: BasicBlockIdentity
  ) -> InstructionIdentity {
    insert(i) { (me, i) in
      InstructionIdentity(block: b, address: me.blocks[b.address].instructions.append(i))
    }
  }


  /// Adds `instruction` at the start of `b` and returns its identity.
  public mutating func prepend<T: Instruction>(
    _ i: T, to b: BasicBlockIdentity
  ) -> InstructionIdentity {
    insert(i) { (me, i) -> InstructionIdentity in
      InstructionIdentity(block: b, address: me.blocks[b.address].instructions.prepend(i))
    }
  }

  /// Inserts `instruction` with `impl` and returns its identity.
  private mutating func insert<T: Instruction>(
    _ instruction: T, with impl: (inout Self, any Instruction) -> InstructionIdentity
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
