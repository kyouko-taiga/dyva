import DyvaLib

@main struct Command {

  /// Runs Dyva's top-level command.
  static func main() async throws {
    var command = Driver.parseOrExit(Array(CommandLine.arguments.dropFirst()))
    do {
      try await command.run()
    } catch let e {
      Driver.exit(withError: e)
    }
  }

}
