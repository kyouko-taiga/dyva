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

extension Module {

  /// Returns an error reporting an ambiguous reference to the function expressed by `f`.
  internal func ambiguousCallee(of e: Call.ID, candidates: [IRFunction.Identity]) -> Diagnostic {
    let f = self[e].callee

    var m: String
    if candidates.isEmpty {
      m = "no viable candidate for calling '\(show(f))'"
    } else {
      m = "multiple candidates for calling '\(show(f))'"
    }

    if self[e].style == .parenthesized {
      m.write("as a function")
    } else {
      m.write("as a subscript")
    }

    if !self[e].arguments.isEmpty {
      m.write(" with labels (")
      for a in self[e].arguments {
        m.write(a.label?.value ?? "_")
        m.write(":")
      }
      m.write(")")
    }

    return .init(.error, m, at: anchorForDiagnostic(about: f))
  }

  /// Returns an error indicating that `e` is not a valid integer literal.
  internal func invalidIntegerLiteral(_ e: IntegerLiteral.ID) -> Diagnostic {
    let a = anchorForDiagnostic(about: e)
    return .init(.error, "cannot represent '\(self[e].value)' as a 64-bit signed integer", at: a)
  }

  /// Returns an error indicating that `d` is an invalid redeclaration.
  internal func invalidRedeclaration(of d: FunctionDeclaration.ID) -> Diagnostic {
    .init(.error, "invalid redeclaration of \(self[d].name)", at: anchorForDiagnostic(about: d))
  }

  /// Returns an error indicating that yield statements cannot occur functions.
  internal func invalidYield(_ n: Yield.ID) -> Diagnostic {
    .init(.error, "'yield' can only occur in a subscript", at: self[n].introducer.site)
  }

  /// Returns an error indicating that `d` requires an implementation.
  internal func missingImplementation(of d: FunctionDeclaration.ID) -> Diagnostic {
    .init(.error, "\(self[d].name) requires an implementation", at: anchorForDiagnostic(about: d))
  }

  /// Returns an error indicating that `n` is undefined.
  internal func undefinedSymbol(_ n: Name, at site: SourceSpan) -> Diagnostic {
    .init(.error, "undefined symbol '\(n)'", at: site)
  }

}

extension IRFunction {

  /// Returns an error indicating that `second` yields after `first` already did.
  internal func extraneousYield(
    _ second: InstructionIdentity, first: InstructionIdentity
  ) -> Diagnostic {
    let n = Diagnostic(
      .note, "value already projected here",
      at: .empty(at: instructions[first].anchor.start))
    return .init(
      .error, "subscript cannot project more than once",
      at: .empty(at: instructions[second].anchor.start),
      notes: [n])
  }

  /// Returns an error indicating that a yield statement is missing.
  internal func missingYield(at site: SourceSpan) -> Diagnostic {
    .init(.error, "subscript must yield before returning", at: site)
  }

}
