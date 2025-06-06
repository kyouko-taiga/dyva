/// A diagnostic related to a region of Hylo source code.
public struct Diagnostic: Error, Hashable, Sendable {

  /// The severity of a diagnostic.
  public enum Level: Hashable, Comparable, Sendable {

    /// A note.
    case note

    /// An error that does not prevent compilation.
    case warning

    /// An unrecoverable error that prevents compilation.
    case error

  }

  /// The level of the diagnostic.
  public let level: Level

  /// The main description of the diagnostic.
  ///
  /// The message should be general and able to stand on its own.
  public let message: String

  /// The source code or source position (if empty) identified as the cause of the error.
  public let site: SourceSpan

  /// The sub-diagnostics.
  public let notes: [Diagnostic]

  /// Creates a new diagnostic.
  ///
  /// - Requires: elements of `notes` have `self.level == .note`
  public init(
    _ level: Level, _ message: String, at site: SourceSpan, notes: [Diagnostic] = []
  ) {
    precondition(notes.allSatisfy({ (n) in n.level == .note }))
    self.level = level
    self.message = message
    self.site = site
    self.notes = notes
  }

  /// Returns a copy of `self` with the given level.
  public func `as`(_ level: Level) -> Self {
    .init(level, message, at: site, notes: notes)
  }

}

extension Diagnostic: Comparable {

  public static func < (l: Self, r: Self) -> Bool {
    let s = l.site
    let t = r.site

    if s.source != t.source {
      return s.source.name.lexicographicallyPrecedes(t.source.name)
    } else if s.start != t.start {
      return s.start < t.start
    } else if l.level != r.level {
      return l.level > r.level
    } else if l.message != r.message {
      return l.message.lexicographicallyPrecedes(r.message)
    } else {
      return l.notes.lexicographicallyPrecedes(r.notes)
    }
  }

}

extension Diagnostic: CustomStringConvertible {

  public var description: String {
    "\(site.gnuStandardText()): \(level): \(message)"
  }

}
