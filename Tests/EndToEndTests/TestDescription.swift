import Foundation
import FrontEnd
import Utilities

/// The input of an end-to-end test.
struct TestDescription {

  /// A test manifest.
  struct Manifest: Decodable {

    /// The options with which the input should be compiled.
    let options: [String]?

  }

  /// The root path of the program's sources.
  let root: URL

  /// `true` iff `self` describes a package.
  let isPackage: Bool

  /// The manifest of this test.
  let manifest: Manifest

  /// Creates an instance with the given properties.
  init(_ path: String, isPackage: Bool) {
    self.root = URL(filePath: path)
    self.isPackage = isPackage

    if isPackage {
      self.manifest = (try? Self.manifest(root)) ?? .init(options: [])
    } else if let s = Self.firstLine(of: root), s.starts(with: "#>") {
      self.manifest = .init(options: s.split(separator: " ").dropFirst().map(String.init(_:)))
    } else {
      self.manifest = .init(options: [])
    }
  }

  /// The arguments that should be passed to the `dyva` executable to run this test.
  var arguments: [String] {
    if let o = manifest.options {
      return o + [root.relativePath]
    } else {
      return [root.relativePath]
    }
  }

  /// Returns the expected contents of the standard stream `k` for this test.
  func expectation(for k: OutputStreamMock.Kind) -> OutputStreamMock? {
    if isPackage {
      let e = root.appendingPathComponent("package.\(k)")
      return try? .init(kind: k, contents: String(contentsOf: e, encoding: .utf8))
    } else {
      let e = root.deletingPathExtension().appendingPathExtension("\(k)")
      return try? .init(kind: k, contents: String(contentsOf: e, encoding: .utf8))
    }
  }

  /// Returns the manifest of the package at `root`.
  private static func manifest(_ root: URL) throws -> Manifest {
    let json = try Data(contentsOf: root.appendingPathComponent("package.json"))
    return try JSONDecoder().decode(Manifest.self, from: json)
  }

  /// Returns the first line of the file at `url`, which is encoded in UTF-8, or `nil`if that
  /// this file could not be read.
  private static func firstLine(of url: URL) -> Substring? {
    (try? String(contentsOf: url, encoding: .utf8))?.firstLine
  }

}
