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
    .executable(name: "dyva", targets: ["dyva"])
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
      name: "dyva",
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
      swiftSettings: commonSwiftSettings),

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
  ])
