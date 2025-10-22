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
struct DominatorTree: Sendable {

  /// A node in the tree.
  typealias Node = BasicBlock.ID

  /// The root of the tree.
  let root: Node

  /// The immediate dominators of each basic block.
  private var immediateDominators: [Node: Node?]

  /// Creates the dominator tree of `f` using its control-flow graph `g`.
  init(function f: IRFunction, g: ControlFlowGraph) {
    // The following is an implementation of Cooper et al.'s fast dominance iterative algorithm
    // (see "A Simple, Fast Dominance Algorithm", 2001). First, build any spanning tree rooted at
    // the function's entry.
    var t = SpanningTree(of: g, rootedAt: 0)

    // Then, until a fixed point is reached, for each block `v` that has a predecessor `u` that
    // isn't `v`'s parent in the tree, assign `v`'s parent to the least common ancestor of `u` and
    // its current parent.
    var changed = true
    while changed {
      changed = false
      for v in f.blocks.indices {
        for u in g.predecessors(of: v) where t.parent(v) != u {
          let lca = t.lowestCommonAncestor(u, t.parent(v)!)
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
  var bfs: [Node] {
    let children: [Node: [Node]] = immediateDominators.reduce(into: [:]) { (children, kv) in
      if case .some(let parent) = kv.value {
        children[parent, default: []].append(kv.key)
      }
    }

    var result = [root]
    var i = 0
    while i < result.count {
      if let nodes = children[result[i]] { result.append(contentsOf: nodes) }
      i += 1
    }
    return result
  }

  /// Returns the immediate dominator of `block`, if any.
  func immediateDominator(of block: Node) -> Node? {
    if case .some(let b) = immediateDominators[block]! {
      return b
    } else {
      return nil
    }
  }

  /// Returns a collection containing the strict dominators of `block`.
  func strictDominators(of block: Node) -> [Node] {
    var result: [Node] = []
    var a = block
    while case .some(let b) = immediateDominators[a]! {
      result.append(b)
      a = b
    }
    return result
  }

  /// Returns `true` if `a` dominates `b`.
  func dominates(_ a: Node, _ b: Node) -> Bool {
    // By definition, a node dominates itself.
    if a == b { return true }

    // Walk the dominator tree from `b` up to the root to find `a`.
    var child = b
    while case .some(let parent) = immediateDominators[child]! {
      if parent == a { return true }
      child = parent
    }
    return false
  }

  /// Returns `true` if the instruction identified by `d` dominates use `u` in function `f`.
  ///
  /// - Requires: `d` and `u` reside in `f`.
  func dominates(_ d: InstructionIdentity, use: Use, in f: IRFunction) -> Bool {
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
  var description: String {
    var result = "strict digraph D {\n\n"
    for (a, immediateDominator) in immediateDominators {
      if let b = immediateDominator {
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

  /// A node in the tree.
  typealias Node = BasicBlock.ID

  /// A map from node to its parent.
  private(set) var parents: [Node: Node?]

  /// Creates a spanning tree of `g` rooted at `root`.
  init(of g: ControlFlowGraph, rootedAt root: Node) {
    parents = [:]
    var work: [(vertex: Node, parent: Node??)] = [(root, .some(nil))]
    while let (v, parent) = work.popLast() {
      parents[v] = parent
      let children = g.successors(of: v).filter({ parents[$0] == nil })
      work.append(contentsOf: children.map({ ($0, .some(v)) }))
    }
  }

  /// Returns the parent of `v`.
  ///
  /// - Requires: `v` is in the tree.
  /// - Complexity: O(1).
  func parent(_ v: Node) -> Node? {
    parents[v]!
  }

  /// Sets `newParent` as `v`'s parent.
  ///
  /// - Requires: `v` and `newParent` are in the tree and distinct; `v` isn't the root.
  /// - Complexity: O(1).
  mutating func setParent(_ newParent: Node, forChild v: Node) {
    parents[v] = .some(newParent)
  }

  /// Returns collection containing `v` followed by all its ancestor, ordered by depth.
  ///
  /// - Requires: `v` is in the tree.
  /// - Complexity: O(*h*) where *h* is the height of `self`.
  func ancestors(_ v: Node) -> [Node] {
    var result = [v]
    while let parent = parents[result.last!]! { result.append(parent) }
    return result
  }

  /// Returns the deepest vertex that is ancestor of both `v` and `u`.
  ///
  /// - Requires: `v` and `u` are in the tree.
  /// - Complexity: O(*h*) where *h* is the height of `self`.
  func lowestCommonAncestor(_ v: Node, _ u: Node) -> Node {
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
