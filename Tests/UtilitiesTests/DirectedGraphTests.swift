import Testing
import Utilities

struct DirectedGraphTests {

  @Test func insertVertex() {
    var g = DirectedGraph<Int, Int>()
    var b: Bool

    b = g.insertVertex(0)
    #expect(b)
    b = g.insertVertex(1)
    #expect(b)
    b = g.insertVertex(0)
    #expect(!b)
  }

  @Test func vertices() {
    var g = DirectedGraph<Int, Int>()
    #expect(g.vertices.isEmpty)

    g.insertVertex(0)
    #expect(Array(g.vertices) == [0])
    g.insertEdge(from: 0, to: 1, labeledBy: 2)
    #expect(Array(g.vertices).sorted() == [0, 1])
  }

  @Test func insertEdge() {
    var g = DirectedGraph<Int, Int>()

    let x0 = g.insertEdge(from: 0, to: 0, labeledBy: 42)
    #expect(x0.inserted)
    #expect(x0.labelAfterInsert == 42)

    let x1 = g.insertEdge(from: 0, to: 1, labeledBy: 42)
    #expect(x1.inserted)
    #expect(x1.labelAfterInsert == 42)

    let x2 = g.insertEdge(from: 0, to: 0, labeledBy: 1337)
    #expect(!x2.inserted)
    #expect(x2.labelAfterInsert == 42)
  }

  @Test func insertEdgeWithoutLabel() {
    var g = DirectedGraph<Int, NoLabel>()
    var b: Bool

    b = g.insertEdge(from: 0, to: 0)
    #expect(b)
    b = g.insertEdge(from: 0, to: 1)
    #expect(b)
    b = g.insertEdge(from: 0, to: 0)
    #expect(!b)
  }

  @Test func removeEdge() {
    var g = DirectedGraph<Int, Int>()

    g.insertEdge(from: 0, to: 0, labeledBy: 42)
    #expect(g.removeEdge(from: 0, to: 0) == 42)
    #expect(g.removeEdge(from: 0, to: 0) == nil)
  }

  @Test func accessTarget() {
    var g = DirectedGraph<Int, Int>()

    g.insertEdge(from: 0, to: 0, labeledBy: 1)
    g.insertEdge(from: 0, to: 1, labeledBy: 2)
    #expect(g[from: 0, to: 0] == 1)
    #expect(g[from: 0, to: 1] == 2)
    #expect(g[from: 0, to: 2] == nil)
    #expect(g[from: 2, to: 0] == nil)

    g[from: 0, to: 2] = 3
    g[from: 2, to: 0] = 3
    #expect(g[from: 0, to: 2] == 3)
    #expect(g[from: 2, to: 0] == 3)
  }

  @Test func accessOutgoingEdges() {
    var g = DirectedGraph<Int, Int>()

    g.insertEdge(from: 0, to: 0, labeledBy: 1)
    g.insertEdge(from: 0, to: 1, labeledBy: 2)
    #expect(g[from: 0] == [0: 1, 1: 2])
    #expect(g[from: 2] == [:])

    g[from: 0] = [2: 3]
    g[from: 2] = [0: 3]
    #expect(g[from: 0] == [2: 3])
    #expect(g[from: 2] == [0: 3])
  }

  @Test func edges() {
    var g = DirectedGraph<Int, String>()

    let edges = [(0, "a", 1), (0, "b", 2), (1, "c", 3)]
    for e in edges {
      g[from: e.0, to: e.2] = e.1
    }
    #expect(g.edges.sorted().elementsEqual(edges, by: { $0 == $1 }))
  }

  @Test func bfs() {
    var g = DirectedGraph<Int, NoLabel>()
    g.insertEdge(from: 0, to: 1)
    g.insertEdge(from: 0, to: 2)
    g.insertEdge(from: 1, to: 3)
    g.insertEdge(from: 2, to: 3)

    let vertices = Array(g.bfs(from: 0))
    #expect(Set(vertices) == [0, 1, 2, 3])
    #expect(vertices.first == 0)
    #expect(vertices.last == 3)
  }

  @Test func isReachable() {
    var g = DirectedGraph<Int, NoLabel>()
    g.insertEdge(from: 0, to: 1)
    g.insertEdge(from: 0, to: 2)
    g.insertEdge(from: 1, to: 3)
    g.insertEdge(from: 2, to: 3)

    #expect(g.isReachable(3, from: 0))
    #expect(g.isReachable(2, from: 0))
    #expect(g.isReachable(3, from: 1))

    #expect(!g.isReachable(0, from: 3))
    #expect(!g.isReachable(2, from: 1))
  }

  @Test func equatable() {
    var g1 = DirectedGraph<Int, Bool>()
    g1.insertEdge(from: 0, to: 1, labeledBy: true)
    g1.insertEdge(from: 1, to: 0, labeledBy: false)

    var g2 = g1
    #expect(g1 == g2)
    g2.removeEdge(from: 0, to: 1)
    #expect(g1 != g2)
    g2.insertEdge(from: 0, to: 1, labeledBy: true)
    #expect(g1 == g2)
  }

  @Test func hashable() {
    var g1 = DirectedGraph<Int, Bool>()
    g1.insertEdge(from: 0, to: 1, labeledBy: true)
    g1.insertEdge(from: 1, to: 0, labeledBy: false)

    var h1 = Hasher()
    var h2 = Hasher()
    g1.hash(into: &h1)
    g1.hash(into: &h2)
    #expect(h1.finalize() == h2.finalize())

    var g2 = g1
    g2.removeEdge(from: 0, to: 1)

    h1 = Hasher()
    h2 = Hasher()
    g1.hash(into: &h1)
    g2.hash(into: &h2)
    #expect(h1.finalize() != h2.finalize())

    g2.insertEdge(from: 0, to: 1, labeledBy: true)
    h1 = Hasher()
    h2 = Hasher()
    g1.hash(into: &h1)
    g2.hash(into: &h2)
    #expect(h1.finalize() == h2.finalize())
  }

}

extension DirectedGraph<Int, String>.Edge {

  fileprivate static func == (_ l: Self, r: (Int, String, Int)) -> Bool {
    (l.source == r.0) && (l.label == r.1) && (l.target == r.2)
  }

}
