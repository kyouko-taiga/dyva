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
    modules.values.contains(where: \.containsError)
  }

  /// The diagnostics of the issues in the program.
  public var diagnostics: some Collection<Diagnostic> {
    modules.values.map(\.diagnostics).joined()
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

      // Parse the file.
      do {
        try Parser.parse(s, into: &m)
      } catch let e as Diagnostic {
        m.addDiagnostic(e)
      } catch let e {
        unreachable("unexpected error: \(e)")
      }

      // Bail out if there was a parse error.
      guard !m.containsError else {
        return (inserted: true, identity: m.identity)
      }

      // Assign scopes.
      let scoper = Scoper()
      scoper.visit(&m)

      // Lower to IR.
      var lowerer = Lowerer()
      lowerer.visit(&m)

      for f in m.functions.values.indices {
        print(m.show(f))
      }

      modules[s.name] = m
      // load the imported modules
      let cwd: URL
      switch s.name {
      case .local(let url):
        cwd = url
      case _:
        cwd = URL.currentDirectory()
      }
      for importID in m.imports {
        let imp = m[importID]
        let path = URL.init(
          fileURLWithPath: String(m[imp.source].string), relativeTo: cwd)
        var source: SourceFile
        do {
          if path.hasDirectoryPath {
            source = try .init(contentsOf: path.appending(components: "index.dyva"))
          } else {
            source = try .init(contentsOf: path)
          }
          load(source, asMain: false)
        } catch let e {
          modules[s.name]!.addDiagnostic(.init(.error, "cannot read import: \(e)", at: imp.site))
        }
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
  internal subscript(m: Module.Identity) -> Module {
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
