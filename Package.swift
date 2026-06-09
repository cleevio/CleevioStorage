// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [ ]

let package = Package(
    name: "CleevioStorageLibrary",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "CleevioStorage",
            targets: ["CleevioStorage"]),
        .library(name: "KeychainRepository", targets: ["KeychainRepository"])
    ],
    dependencies: [
        .package(url: "https://github.com/cleevio/CleevioCore.git", .upToNextMajor(from: .init(2, 1, 7))),
        .package(url: "https://github.com/parmar-mehul/KeychainAccess", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", .upToNextMajor(from: .init(1, 1, 0)))
    ],
    targets: [
        .target(
            name: "CleevioStorage",
            dependencies: [
                "CleevioCore"
            ],
            swiftSettings: swiftSettings),
        .target(name: "KeychainRepository", dependencies: [
            "CleevioCore",
            "CleevioStorage",
            "KeychainAccess"
        ],
                swiftSettings: swiftSettings),
        .testTarget(
            name: "CleevioStorageTests",
            dependencies: ["CleevioStorage", .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras")],
            swiftSettings: swiftSettings),
    ],
    swiftLanguageModes: [.v6]
)
