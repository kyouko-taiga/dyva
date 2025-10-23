import BitCollections

extension IRFunction {

  /// If `self` defines a subscript, makes sure there is exactly one yield statement on every path;
  /// does nothing otherwise.
  ///
  /// The algorithm operates in two phases:
  ///
  /// First, we determine which blocks are part of the subscript's ramp. We run a breadth-first
  /// search starting from the entry and look for blocks having a yield instruction. When we find
  /// one, we conclude that its successors are part of the side. When we reach a returning block,
  /// we conclude that the path is missing a yield statement.
  ///
  /// In the second phase, we run another breadth-first search starting from the slides we have
  /// identified and look for illegal yield statements.
  ///
  /// - Complexity: O(*n*) where *n* is the number of instructions in the function.
  public mutating func checkYieldCoherence(reportingDiagnosticsTo log: inout DiagnosticSet) {
    // Nothing to do if the function isn't a subscript or isn't defined.
    if !isSubscript || !isDefined { return }

    /// A work list with the basic blocks to process.
    var work: [Int] = .init(minimumCapacity: blocks.count)
    /// The set of basic blocks that have been visited.
    var visited: BitArray
    /// A map from slide block to one a yield instruction in one of its preceeding ramp blocks.
    var slide: [InstructionIdentity?] = Array(repeating: nil, count: blocks.count)

    // Phase 1: Determine which blocks are part of the ramp.
    work.append(0)
    visited = BitArray(repeating: false, count: blocks.count)
    while let b = work.popLast() {
      visited[b] = true

      // Does the block contain a yield instruction?
      if let y = first(of: b, where: { (s) in s is IRYield }) {
        // Make sure there isn't another yield in the same block.
        var i = y
        while i != blocks[b].last {
          i = instructions.address(after: i)!
          if instructions[i] is IRYield {
            log.insert(extraneousYield(i, first: y))
            return
          }
        }

        // Move the successors to the slide.
        for s in successors(of: b) { slide[s] = y }
        continue
      }

      // Otherwise, does the block have successors that haven't been visited yet?
      let ss = successors(of: b).filter({ (s) in !visited[s] })
      if !ss.isEmpty {
        work.append(contentsOf: ss)
        continue
      }

      // Otherwise, complain that there isn't any yield statement.
      else {
        log.insert(missingYield(at: .empty(at: instructions[blocks[b].last!].anchor.end)))
        return
      }
    }

    // Phase 2: Make sure none of the slide blocks have yield statements.
    work = slide.indices.filter({ (b) in slide[b] != nil })
    visited.fill(with: false)
    while let b = work.popLast() {
      visited[b] = true

      // Make sure there isn't another yield in the block.
      let y = slide[b]!
      if let i = first(of: b, where: { (s) in s is IRYield }) {
        log.insert(extraneousYield(i, first: y))
        return
      }

      // Collect the next blocks to visit.
      for s in successors(of: b) where !visited[s] {
        slide[s] = y
        work.append(s)
      }
    }
  }

}
