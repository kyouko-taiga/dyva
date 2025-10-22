import Utilities

extension IRFunction {

  public mutating func closeRegions() {
    for i in instructions.addresses {
      close(i)
    }
  }

  private mutating func close(_ i: InstructionIdentity) {
    switch self.instructions[i] {
    case is IRAccess:
      let r = extendedLiveRange(of: .register(i))
      if r.isEmpty {
        remove(i)
      } else {
        insertClose(IRAccess.self, i, atBoundariesOf: r)
      }

    default:
      break
    }
  }

  /// Returns the extended live-range of `v`, which is a definition.
  ///
  /// A definition is *live* over an instruction if it is is used by that instruction or may be
  /// used by another instruction in the future. The live-range of a definition `d` is the region
  /// of a function containing all instructions over which `d` is live. The extended live-range of
  /// `d` is its live-range merged with the extended live-ranges of the definitions extending `d`.
  ///
  /// - Note: The definition of an operand `o` isn't part of `o`'s lifetime.
  private func extendedLiveRange(of v: IRValue) -> Lifetime {
    // Nothing to do if the operand has no use.
    guard let uses = self.uses[v] else { return Lifetime(operand: v) }

    // Nothing to do if the operand isn't a definition.
    guard let b = blockDefining(v) else { return Lifetime(operand: v) }

    // Compute the live-range of the definition and extend it with that of its extending uses.
    var r = liveRange(of: v, definedIn: b)
    for use in uses where instructions[use.user].isExtendingOperandLifetimes {
      r = extended(r, toCover: extendedLiveRange(of: .register(use.user)))
    }

    return r
  }

  /// Returns the minimal lifetime containing all instructions using `v`, which is defined in `b`.
  private func liveRange(of operand: IRValue, definedIn b: BasicBlock.ID) -> Lifetime {

    // This implementation is a variant of Appel's path exploration algorithm found in Brandner et
    // al.'s "Computing Liveness Sets for SSA-Form Programs".

    // Find all blocks in which the operand is being used.
    var occurrences = uses[operand, default: []].reduce(into: Set<BasicBlock.ID>()) { (bs, use) in
      bs.insert(container[use.user]!)
    }

    // Propagate liveness starting from the blocks in which the operand is being used.
    let g = controlFlow()
    var approximateCoverage: [BasicBlock.ID: (isLiveIn: Bool, isLiveOut: Bool)] = [:]
    while true {
      guard let occurrence = occurrences.popFirst() else { break }

      // `occurrence` is the defining block.
      if b == occurrence { continue }

      // We already propagated liveness to the block's live-in set.
      if approximateCoverage[occurrence]?.isLiveIn ?? false { continue }

      // Mark that the definition is live at the block's entry and propagate to its predecessors.
      approximateCoverage[occurrence, default: (false, false)].isLiveIn = true
      for predecessor in g.predecessors(of: occurrence) {
        approximateCoverage[predecessor, default: (false, false)].isLiveOut = true
        occurrences.insert(predecessor)
      }
    }

    var coverage: Lifetime.Coverage = [:]

    // If the operand isn't live out of its defining block, its last use is in that block.
    if approximateCoverage.isEmpty {
      coverage[b] = .closed(lastUse: lastUse(of: operand, in: b))
      return Lifetime(operand: operand, coverage: coverage)
    }

    // Find the last use in each block for which the operand is not live out.
    var successors: Set<BasicBlock.ID> = []
    for (block, bounds) in approximateCoverage {
      switch bounds {
      case (true, true):
        coverage[block] = .liveInAndOut
        successors.formUnion(g.successors(of: block))
      case (false, true):
        coverage[block] = .liveOut
        successors.formUnion(g.successors(of: block))
      case (true, false):
        coverage[block] = .liveIn(lastUse: lastUse(of: operand, in: block))
      case (false, false):
        continue
      }
    }

    // Mark successors of live out blocks as live in if they haven't been already.
    for block in successors where coverage[block] == nil {
      coverage[block] = .liveIn(lastUse: nil)
    }

    return Lifetime(operand: operand, coverage: coverage)
  }

  /// Returns `lhs` extended to cover the instructions in `rhs`.
  ///
  /// - Requires: `lhs` and `rhs` are defined in the same function, which is in `self`. The operand
  ///   for which `rhs` is defined must be in `lhs`.
  private func extended(_ left: Lifetime, toCover right: Lifetime) -> Lifetime {
    let coverage = left.coverage.merging(right.coverage) { (a, b) in
      switch (a, b) {
      case (.liveOut, .liveIn), (.liveIn, .liveOut):
        unreachable("definition does not dominate all uses")
      case (.liveInAndOut, _), (_, .liveInAndOut):
        return .liveInAndOut
      case (.liveOut, _), (_, .liveOut):
        return .liveOut
      case (.liveIn(let lhs), .liveIn(let rhs)):
        return .liveIn(lastUse: sequencedLast(lhs, rhs))
      case (.liveIn(let lhs), .closed(let rhs)):
        return .liveIn(lastUse: sequencedLast(lhs, rhs))
      case (.closed(let lhs), .liveIn(let rhs)):
        return .liveIn(lastUse: sequencedLast(lhs, rhs))
      case (.closed(let lhs), .closed(let rhs)):
        return .closed(lastUse: sequencedLast(lhs, rhs))
      }
    }
    return .init(operand: left.operand, coverage: coverage)
  }

  /// Returns the use that executes last iff `lhs` and `rhs` are in the same basic block.
  private func sequencedLast(_ lhs: Use?, _ rhs: Use?) -> Use? {
    guard let a = lhs else { return rhs }
    guard let b = rhs else { return lhs }

    if a.user == b.user {
      return a.index < b.index ? rhs : lhs
    } else {
      return contents(of: container[a.user]!).contains(b.user) ? lhs : rhs
    }
  }

  /// Closes the access formed by `i`, which is an instance of `T`, at the boundaries of `r`.
  ///
  /// No instruction is inserted after already existing lifetime closers for `i`.
  private mutating func insertClose<T: IRRegionEntry>(
    _: T.Type, _ i: InstructionIdentity, atBoundariesOf r: Lifetime
  ) {
    for boundary in r.upperBoundaries {
      switch boundary {
      case .after(let u):
        // Skip the insertion if the last user already closes the borrow.
        if let e = instructions[u] as? IRRegionEnd<T>, e.start.instruction == i {
          continue
        }
        let a = instructions[u].anchor
        insert(IRRegionEnd<T>(start: .register(i), anchor: a), after: u)

      case .start(let b):
        let a = blocks[b].first.map({ (s) in instructions[s].anchor }) ?? instructions[i].anchor
        insert(IRRegionEnd<T>(start: .register(i), anchor: a), at: boundary)

      default:
        unreachable()
      }
    }
  }

}
