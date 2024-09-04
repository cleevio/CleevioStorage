// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
// Only for development checks
//    SwiftSetting.unsafeFlags([
//        "-Xfrontend", "-strict-concurrency=complete",
//        "-Xfrontend", "-warn-concurrency",
//        "-Xfrontend", "-enable-actor-data-race-checks",
//    ])
]

let package = Package(
    name: "CleevioStorageLibrary",
    platforms: [
        .iOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "CleevioStorage",
            targets: ["CleevioStorage"]),
        .library(name: "KeychainRepository", targets: ["KeychainRepository"])
    ],
    dependencies: [
        .package(url: "git@gitlab.cleevio.cz:cleevio-dev-ios/CleevioCore.git", .upToNextMajor(from: .init(2, 1, 7))),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
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
    ]
)
