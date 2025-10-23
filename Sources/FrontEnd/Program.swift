import OrderedCollections
import Utilities

import struct Foundation.URL

/// A Dyva program.
public struct Program {

  /// The modules in the program.
  internal private(set) var modules = OrderedDictionary<FileName, Module>()

  /// Creates an empty program.
  public init() {}

  /// `true` if the program has errors.
  public var containsError: Bool {
    modules.values.contains(where: \.diagnostics.containsError)
  }

  /// The diagnostics of the issues in the program.
  public var diagnostics: some Collection<Diagnostic> {
    modules.values.map(\.diagnostics.elements).joined()
  }

  /// Adds the given source file in this program, loaded as the entry iff `isMain` is `true`.
  @discardableResult
  public mutating func load(
    _ s: SourceFile, asMain isMain: Bool
  ) -> (inserted: Bool, identity: Module.Identity) {
    if let m = modules.index(forKey: s.name) {
      return (inserted: false, identity: UInt32(m))
    } else {
      var m = Module(identity: UInt32(modules.count), isMain: isMain, source: s)
      defer { modules[s.name] = m }

      // Parse the file.
      do {
        try Parser.parse(s, into: &m)
      } catch let e as Diagnostic {
        m.addDiagnostic(e)
      } catch let e {
        unreachable("unexpected error: \(e)")
      }

      // Bail out if there was a parse error.
      guard !m.diagnostics.containsError else {
        modules[s.name] = m
        return (inserted: true, identity: m.identity)
      }

      // Assign scopes.
      let scoper = Scoper()
      scoper.visit(&m)

      // Lower to IR.
      var lowerer = Lowerer()
      lowerer.visit(&m)

      // Apply IR passes.
      for i in m.functions.values.indices {
        var log = DiagnosticSet()
        modify(&m.functions.values[i]) { (f) in
          f.eliminateDeadAccesses()
          f.checkYieldCoherence(reportingDiagnosticsTo: &log)
          f.closeRegions()
        }
        m.addDiagnostics(log)
      }

      return (inserted: true, identity: m.identity)
    }
  }

  /// Run the program.
  public mutating func run() throws {
    for m in modules.values {
      print(m)
    }
  }

  /// Projects the module identified by `m`.
  public subscript(m: Module.Identity) -> Module {
    get {
      modules.values[Int(m)]
    }
    _modify {
      yield &modules.values[Int(m)]
    }
  }

  /// Projects the node identified by `n`.
  public subscript<T: SyntaxIdentity>(n: T) -> any Syntax {
    self[n.module][n]
  }

  /// Projects the node identified by `n`.
  public subscript<T: Syntax>(n: T.ID) -> T {
    self[n.module][n]
  }

  /// Returns the tag of `n`.
  public func tag<T: SyntaxIdentity>(of n: T) -> SyntaxTag {
    self[n.module].tag(of: n)
  }

}
