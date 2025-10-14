import ArgumentParser
import Foundation
import FrontEnd
import Utilities

/// The top-level command of `hc`.
@main struct CommandLine: AsyncParsableCommand {

  /// Configuration for this command.
  public static let configuration = CommandConfiguration(commandName: "dyva")

  /// The input file or directory passed to the command.
  @Argument(transform: URL.init(fileURLWithPath:))
  private var input: URL

  /// Creates a new instance with default options.
  public init() {}

  /// Executes the command.
  public mutating func run() async throws {
    if input.hasDirectoryPath || (input.pathExtension != "dyva") {
      throw ValidationError("unexpected input: \(input.relativePath)")
    }

    var program = Program()
    let source = try SourceFile(contentsOf: input)
    program.load(source, asMain: true)

    render(program.diagnostics)
    if program.containsError {
      CommandLine.exit(withError: ExitCode.failure)
    }

    try program.run()
  }

  /// Returns an array with the URLs of the source files in `inputs` and their subdirectories.
  private func sourceURLs(recursivelyContainedIn inputs: [URL]) throws -> [URL] {
    var sources: [URL] = []
    for url in inputs {
      if url.hasDirectoryPath {
        SourceFile.forEachURL(in: url) { (u) in sources.append(u) }
      } else if url.pathExtension == "dyva" {
        sources.append(url)
      } else {
        throw ValidationError("unexpected input: \(url.relativePath)")
      }
    }
    return sources.sorted(by: { (a, b) in a.lexicographicallyPrecedes(b) })
  }

  /// Renders the given diagnostics to the standard error.
  private func render<T: Sequence<Diagnostic>>(_ ds: T) {
    let s: Diagnostic.TextOutputStyle = ProcessInfo.ansiTerminalIsConnected ? .styled : .unstyled
    var o = ""
    for d in ds {
      d.render(into: &o, showingPaths: .absolute, style: s)
    }
    var stderr = StandardError()
    print(o, to: &stderr)
  }

  /// Writes `message` to the standard error and exit.
  private func fatal(_ message: String) {
    var stderr = StandardError()
    print(message, to: &stderr)
    CommandLine.exit(withError: ExitCode.failure)
  }

}

extension ProcessInfo {

  /// `true` iff the terminal supports coloring.
  fileprivate static let ansiTerminalIsConnected =
    !["", "dumb", nil].contains(processInfo.environment["TERM"])

}

extension ContinuousClock.Instant.Duration {

  /// The value of `self` in nanoseconds.
  fileprivate var ns: Int64 { components.attoseconds / 1_000_000_000 }

  /// The value of `self` in microseconds.
  fileprivate var μs: Int64 { ns / 1_000 }

  /// The value of `self` in milliseconds.
  fileprivate var ms: Int64 { μs / 1_000 }

  /// A human-readable representation of `self`.
  fileprivate var human: String {
    guard abs(ns) >= 1_000 else { return "\(ns)ns" }
    guard abs(μs) >= 1_000 else { return "\(μs)μs" }
    guard abs(ms) >= 1_000 else { return "\(ms)ms" }
    return formatted()
  }

}

extension URL {

  /// Returns `true` iff the path of `self` lexicographically precedes that of `other`.
  fileprivate func lexicographicallyPrecedes(_ other: URL) -> Bool {
    let lhs = self.standardizedFileURL.path(percentEncoded: false)
    let rhs = other.standardizedFileURL.path(percentEncoded: false)
    return lhs.lexicographicallyPrecedes(rhs)
  }

}
