import DyvaLib
import Foundation
import Testing

struct EndToEndTests {

  /// The root URL of the negative test cases.
  private static let negativeRoot = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("negative")

  /// The root URL of the positive test cases.
  private static let positiveRoot = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("positive")

  /// Runs `test` expecting at least one error.
  func negative(_ test: TestDescription) async throws {
    var dyva = try Driver.parse(test.arguments)

    // The program should throw.
    var console = ConsoleMock()
    try await #require(throws: Error.self) {
      try await dyva.run(
        console: &console,
        showingPaths: .relative(to: Self.negativeRoot))
    }

    // Check if the standard streams matches their expectations.
    if let o = test.expectation(for: .stdout) {
      checkExpectation(o, against: console.output.contents, for: test)
    }
    if let e = test.expectation(for: .stderr) {
      checkExpectation(e, against: console.error.contents, for: test)
    }
  }

  /// Runs `test` expecting no error.
  func positive(_ test: TestDescription) async throws {
    var dyva = try Driver.parse(test.arguments)

    // The program should not throw.
    var console = ConsoleMock()
    try await dyva.run(
      console: &console,
      showingPaths: .relative(to: Self.positiveRoot))

    // Check if the standard streams matches their expectations.
    if let o = test.expectation(for: .stdout) {
      checkExpectation(o, against: console.output.contents, for: test)
    }
    if let e = test.expectation(for: .stderr) {
      checkExpectation(e, against: console.error.contents, for: test)
    }
  }

  /// Checks if the contents of `observed` matches those of `expected`, reporting that `test`
  /// failed if they dont.
  private func checkExpectation(
    _ expected: OutputStreamMock, against observed: String, for test: TestDescription
  ) {
    let lhs = expected.contents.split(whereSeparator: \.isNewline)
    let rhs = observed.split(whereSeparator: \.isNewline)
    let delta = lhs.difference(from: rhs).inferringMoves()

    if !delta.isEmpty {
      let report = """
        observed output does match expecation:
        \(Self.explain(difference: delta, relativeTo: lhs))
        """
      Issue.record(Comment(rawValue: report))
      writeObservation(.init(kind: expected.kind, contents: observed), for: test)
    }
  }

  /// Attempts to write a file describing that `stream` has been observed after running `test`.
  private func writeObservation(
    _ stream: OutputStreamMock, for test: TestDescription
  ) {
    if test.isPackage {
      let o = test.root.appendingPathComponent("package.\(stream.kind).observed")
      try? stream.contents.write(to: o, atomically: true, encoding: .utf8)
    } else {
      let o = test.root.deletingPathExtension().appendingPathExtension("\(stream.kind).observed")
      try? stream.contents.write(to: o, atomically: true, encoding: .utf8)
    }
  }

  /// Returns a message explaining `delta`, which is the result of comparing `expectation` to some
  /// observed result.
  private static func explain(
    difference delta: CollectionDifference<String.SubSequence>,
    relativeTo expectation: [Substring]
  ) -> String {
    var patch: [[(Character, Substring)]] = []

    for change in delta {
      switch change {
      case .insert(let i, let line, _):
        while patch.count <= i { patch.append([]) }
        patch[i].append(("+", line))
      case .remove(let i, let line, _):
        while patch.count <= i { patch.append([]) }
        patch[i].append(("-", line))
      }
    }

    var report = ">"

    for i in patch.indices {
      if patch[i].isEmpty && (i < expectation.count) {
        report.write("\n \(expectation[i])")
      } else {
        for (m, line) in patch[i] { report.write("\n\(m)\(line)") }
      }
    }

    return report
  }

}
