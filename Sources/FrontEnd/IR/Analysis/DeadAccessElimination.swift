extension IRFunction {

  /// Removes accesses with no uses.
  public mutating func eliminateDeadAccesses() {
    // Collect all accesses in the function.
    var work = instructions.addresses.filter({ (i) in instructions[i] is IRAccess })

    // Remove dead accesses until a fixed point has been reached.
    var i = 0
    var j = work.count
    while i < j {
      // Collect the uses of the access.
      let us = uses[.register(work[i]), default: []]

      // If there are no uses but end accesses, remove the instruction.
      if us.allSatisfy({ (u) in instructions[u.user] is IRRegionEnd<IRAccess> }) {
        for u in us { remove(u.user) }
        remove(work[i])
        work.swapAt(i, j - 1)
        i = 0
        j = j - 1
      } else {
        i = i + 1
      }
    }
  }

}
