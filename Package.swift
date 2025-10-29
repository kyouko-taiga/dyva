// swift-tools-version:6.0
import PackageDescription

/// Swttings common to all Swift targets.
let commonSwiftSettings: [SwiftSetting] = [
  .unsafeFlags(["-warnings-as-errors"])
]

let package = Package(
  name: "Dyva",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "dyva", targets: ["dyva-cli"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-algorithms.git",
      from: "1.2.0"),
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      from: "1.1.4"),
    .package(
      url: "https://github.com/apple/swift-collections.git",
      from: "1.1.0"),
  ],
  targets: [
    .executableTarget(
      name: "dyva-cli",
      dependencies: [
        .target(name: "DyvaLib")
      ],
      swiftSettings: commonSwiftSettings),

    .executableTarget(
      name: "dyva-tests",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      swiftSettings: commonSwiftSettings),

    .target(
      name: "DyvaLib",
      dependencies: [
        .target(name: "FrontEnd"),
        .target(name: "Utilities"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      swiftSettings: commonSwiftSettings),

    .target(
      name: "FrontEnd",
      dependencies: [
        .target(name: "Utilities"),
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(name: "Collections", package: "swift-collections"),
      ],
      swiftSettings: commonSwiftSettings),

    .target(
      name: "Utilities",
      dependencies: [
        .product(name: "Collections", package: "swift-collections")
      ],
      swiftSettings: commonSwiftSettings),

    .testTarget(
      name: "EndToEndTests",
      dependencies: [
        .target(name: "DyvaLib"),
        .target(name: "FrontEnd"),
        .target(name: "Utilities"),
      ],
      exclude: ["negative", "positive", "README.md"],
      swiftSettings: commonSwiftSettings,
      plugins: ["DyvaTestsPlugin"]),

    .testTarget(
      name: "FrontEndTests",
      dependencies: [
        .target(name: "FrontEnd")
      ],
      swiftSettings: commonSwiftSettings),

    .testTarget(
      name: "UtilitiesTests",
      dependencies: [
        .target(name: "Utilities")
      ],
      swiftSettings: commonSwiftSettings),

    .plugin(
      name: "DyvaTestsPlugin",
      capability: .buildTool(),
      dependencies: [
        .target(name: "dyva-tests")
      ]),
  ])
