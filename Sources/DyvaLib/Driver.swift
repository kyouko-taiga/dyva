import ArgumentParser
import Foundation
import FrontEnd
import Utilities

/// The top-level command of `dyva`.
public struct Driver: AsyncParsableCommand {

  /// Configuration for this command.
  public static let configuration = CommandConfiguration(commandName: "dyva")

  /// The input file or directory passed to the command.
  @Argument(transform: URL.init(fileURLWithPath:))
  private var input: URL

  @Flag(
    name: [.long],
    help: "Output the intermediate representation.")
  private var emitIR: Bool = false

  /// Creates a new instance with default options.
  public init() {}

  /// Executes the command, writing diagnostics to the standard error.
  public mutating func run() async throws {
    var c = SystemConsole()
    try await run(console: &c)
  }

  /// Executes the command, using `console` for interacting with standard streams.
  public mutating func run<C: Console>(
    console: inout C,
    showingPaths pathStyle: FileName.PathStyle = .absolute
  ) async throws {
    if input.hasDirectoryPath || (input.pathExtension != "dyva") {
      throw ValidationError("unexpected input: \(input.relativePath)")
    }

    var program = Program()
    let m = try program.load(SourceFile(contentsOf: input), asMain: true).identity

    render(program.diagnostics, to: &console.error, showingPaths: pathStyle)
    if program.containsError {
      throw ExitCode.failure
    }

    if emitIR {
      print(program[m].ir, to: &console.output)
    } else {
      try program.run()
    }
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
  private func render<T: Sequence<Diagnostic>, E: TextOutputStream>(
    _ ds: T, to stderr: inout E,
    showingPaths pathStyle: FileName.PathStyle = .absolute
  ) {
    let s: Diagnostic.TextOutputStyle = ProcessInfo.ansiTerminalIsConnected ? .styled : .unstyled
    for d in ds {
      d.render(into: &stderr, showingPaths: pathStyle, style: s)
    }
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
