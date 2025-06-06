import Foundation

/// The name of a file.
public enum FileName: Hashable, Sendable {

  /// A local path to a file.
  case local(URL)

  /// A unique identifier for a file that only exists in memory.
  case virtual(Int)

  /// Returns `true` iff `self` is ordered before `other` in a dictionary.
  public func lexicographicallyPrecedes(_ other: Self) -> Bool {
    switch (self, other) {
    case (.local(let a), .local(let b)):
      return a.standardizedFileURL.path().lexicographicallyPrecedes(b.standardizedFileURL.path())
    case (.virtual(let a), .virtual(let b)):
      return a < b
    case (.virtual, _):
      return false
    case (.local, _):
      return true
    }
  }

  /// Returns a textual description of `self`'s path relative to `base`.
  public func gnuPath(relativeTo base: URL) -> String? {
    guard base.isFileURL, case .local(let path) = self else { return nil }
    let source = path.standardized.pathComponents
    let prefix = base.standardized.pathComponents

    // Identify the end of the common prefix.
    var i = 0
    while (i != prefix.count) && (i != source.count) && (prefix[i] == source[i]) {
      i += 1
    }

    if (i == source.count) && (i == prefix.count) {
      return "."
    } else {
      var result = Array(repeating: "..", count: prefix.count - i)
      result.append(contentsOf: source[i...])
      return result.joined(separator: "/")
    }
  }

  /// The way in which a file path may be shown.
  public enum PathStyle {

    /// File paths are shown absolute.
    case absolute

    /// File paths are shown relative to a base URL.
    case relative(to: URL)

  }

}

extension FileName: CustomStringConvertible {

  public var description: String {
    switch self {
    case .local(let p):
      return p.relativePath
    case .virtual(let i):
      return "virtual://\(String(UInt(bitPattern: i), radix: 36))"
    }
  }

}
