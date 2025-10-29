import Foundation
import PackagePlugin

/// The SPM plugin generating compiler test cases as part of our build process.
@main struct DyvaTestsPlugin: BuildToolPlugin {

  func createBuildCommands(
    context: PackagePlugin.PluginContext, target: any PackagePlugin.Target
  ) async throws -> [PackagePlugin.Command] {
    let output = context.pluginWorkDirectoryURL
      .appending(component: "EndToEndTests+GeneratedTests.swift")

    let c = PackagePlugin.Command.buildCommand(
      displayName: "Generating compiler test cases into \(output)",
      executable: try context.tool(named: "dyva-tests").url,
      arguments: ["-o", output.path(percentEncoded: true)],
      environment: [:],
      inputFiles: [],
      outputFiles: [output])
    return [c]
  }

}
