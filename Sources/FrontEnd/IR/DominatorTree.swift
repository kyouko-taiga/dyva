import Utilities

/// A tree whose nodes are basic blocks and where a node immediately dominates its children.
///
/// Definitions:
/// - A block `b1` in a control-flow graph *dominates* a block `b2` if every path from the entry to
///   `b2` must go through `b1`. By definition, every node dominates itself.
/// - A block `b1` *strictly dominates* a block `b2` if `b1` dominates `b2` and `b1 != b2`.
/// - A block `b1` *immediately dominates* a block `b2` if `b1` strictly dominates `b2` and there
///   is no block `b3` that strictly dominates `b2`.
///
/// A dominator tree encodes the dominance relation of a control graph as a tree where a node is
/// a basic blocks and its children are those it immediately dominates.
internal struct DominatorTree: Sendable {

  /// The root of the tree.
  internal let root: BasicBlock.ID

  /// The immediate dominators of each basic block.
  ///
  /// The array notionally encodes a map `[BasicBlock.ID: BasicBlock.ID?]`. It contains one entry
  /// for each basic block in the function that for which `self` been created where `-1` denotes
  /// `.some(nil)` and `-2` denotes `nil`.
  private var immediateDominators: [BasicBlock.ID]

  /// Creates the dominator tree of `f` using its control-flow graph `g`.
  internal init(function f: IRFunction, controlFlow g: ControlFlowGraph) {
    // The following is an implementation of Cooper et al.'s fast dominance iterative algorithm
    // (see "A Simple, Fast Dominance Algorithm", 2001). First, build any spanning tree rooted at
    // the function's entry.
    var t = SpanningTree(of: g, vertexCount: f.blocks.count)

    // Then, until a fixed point is reached, for each block `v` that has a predecessor `u` that
    // isn't `v`'s parent in the tree, assign `v`'s parent to the least common ancestor of `u` and
    // its current parent.
    var changed = true
    while changed {
      changed = false
      for v in f.blocks.indices {
        for u in g.predecessors(of: v) where t.parent(v) != u {
          let lca = t.lowestCommonAncestor(u, t.parent(v))
          if lca != t.parent(v) {
            t.setParent(lca, forChild: v)
            changed = true
          }
        }
      }
    }

    // The resulting tree encodes the immediate dominators.
    root = 0
    immediateDominators = t.parents
  }

  /// A collection containing the blocks in this tree in breadth-first order.
  internal var bfs: [BasicBlock.ID] {
    var children = Array<[BasicBlock.ID]>(repeating: [], count: immediateDominators.count)
    for (a, b) in immediateDominators.enumerated() where b >= 0 {
      children[a].append(b)
    }

    var result = [root]
    var i = 0
    while i < result.count {
      result.append(contentsOf: children[result[i]])
      i += 1
    }
    return result
  }

  /// Returns the immediate dominator of `b`, if any.
  internal func immediateDominator(of b: BasicBlock.ID) -> BasicBlock.ID? {
    let d = immediateDominators[b]
    return (d >= 0) ? d : nil
  }

  /// Returns a collection containing the strict dominators of `b`.
  internal func strictDominators(of b: BasicBlock.ID) -> [BasicBlock.ID] {
    var result: [BasicBlock.ID] = []
    var d = immediateDominators[b]
    while d >= 0 {
      result.append(d)
      d = immediateDominators[d]
    }
    return result
  }

  /// Returns `true` if `a` dominates `b`.
  internal func dominates(_ a: BasicBlock.ID, _ b: BasicBlock.ID) -> Bool {
    // By definition, a node dominates itself.
    if a == b { return true }

    // Walk the dominator tree from `b` up to the root to find `a`.
    var parent = immediateDominators[b]
    while parent >= 0 {
      if parent == a { return true }
      parent = immediateDominators[b]
    }
    return false
  }

  /// Returns `true` if the instruction identified by `d` dominates use `u` in function `f`.
  ///
  /// - Requires: `d` and `u` reside in `f`.
  internal func dominates(_ d: InstructionIdentity, use: Use, in f: IRFunction) -> Bool {
    // If `definition` is in the same block as `use`, check which comes first.
    let a = f.container[d]!
    let b = f.container[use.user]!

    if a == b {
      // Assume well-formedness: definition dominates its uses.
      return f.contents(of: a).contains(d)
    } else {
      // Return whether the block containing `d` dominates the block containing `use`.
      return dominates(a, b)
    }
  }

}

extension DominatorTree: CustomStringConvertible {

  /// The Graphviz (dot) representation of the tree.
  internal var description: String {
    var result = "strict digraph D {\n\n"
    for (a, b) in immediateDominators.enumerated() {
      if b >= 0 {
        result.write("\(a) -> \(b);\n")
      } else {
        result.write("\(a);\n")
      }
    }
    result.write("\n}")
    return result
  }

}

/// A spanning tree of a control flow graph.
private struct SpanningTree: Sendable {

  /// A map from node to its parent.
  ///
  /// The array notionally encodes the same data structure as `DominatorTree.immediateDominators`.
  private(set) var parents: [Int]

  /// Creates a spanning tree of `g`, whose vertices are in the range `0 ..< n`.
  fileprivate init(of g: ControlFlowGraph, vertexCount n: Int) {
    parents = Array(repeating: -2, count: n)
    var work: [(vertex: BasicBlock.ID, parent: Int)] = [(0, -1)]
    while let (v, parent) = work.popLast() {
      parents[v] = parent
      for w in g.successors(of: v) where parents[w] == -2 {
        work.append((w, v))
      }
    }
  }

  /// Returns the parent of `v`.
  ///
  /// - Requires: `v` is in the tree.
  /// - Complexity: O(1).
  fileprivate func parent(_ v: BasicBlock.ID) -> Int {
    assert(parents[v] > -2)
    return parents[v]
  }

  /// Sets `newParent` as `v`'s parent.
  ///
  /// - Requires: `v` and `newParent` are in the tree and distinct; `v` isn't the root.
  /// - Complexity: O(1).
  fileprivate mutating func setParent(_ newParent: BasicBlock.ID, forChild v: BasicBlock.ID) {
    parents[v] = newParent
  }

  /// Returns collection containing `v` followed by all its ancestor, ordered by depth.
  ///
  /// - Requires: `v` is in the tree.
  /// - Complexity: O(*h*) where *h* is the height of `self`.
  fileprivate func ancestors(_ v: BasicBlock.ID) -> [BasicBlock.ID] {
    var result = [v]
    var parent = parents[result.last!]
    while parent >= 0 {
      result.append(parent)
      parent = parents[parent]
    }
    return result
  }

  /// Returns the deepest vertex that is ancestor of both `v` and `u`.
  ///
  /// - Requires: `v` and `u` are in the tree.
  /// - Complexity: O(*h*) where *h* is the height of `self`.
  fileprivate func lowestCommonAncestor(_ v: BasicBlock.ID, _ u: BasicBlock.ID) -> BasicBlock.ID {
    var x = ancestors(v)[...]
    var y = ancestors(u)[...]
    while x.count > y.count {
      x.removeFirst()
    }
    while y.count > x.count {
      y.removeFirst()
    }
    while x.first != y.first {
      x.removeFirst()
      y.removeFirst()
    }
    return x.first!
  }

}
