// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CleevioStorageLibrary",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CleevioStorage",
            targets: ["CleevioStorage"]),
        .library(name: "KeychainRepository", targets: ["KeychainRepository"])
    ],
    dependencies: [
        .package(url: "git@gitlab.cleevio.cz:cleevio-dev-ios/CleevioFramework-ios.git", branch: "feature/reworked-cleevio-framework-packages"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "CleevioStorage",
            dependencies: [
                .product(name: "CleevioCore", package: "CleevioFramework-ios")
            ]),
        .target(name: "KeychainRepository", dependencies: ["CleevioCore", "CleevioStorage", "KeychainAccess"]),
        .testTarget(
            name: "CleevioStorageTests",
            dependencies: ["CleevioStorage"]),
    ]
)
