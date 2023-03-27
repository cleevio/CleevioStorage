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
    ],
    dependencies: [
        .package(url: "git@gitlab.cleevio.cz:cleevio-dev-ios/CleevioFramework-ios.git", branch: "feature/reworked-cleevio-framework-packages"),
    ],
    targets: [
        .target(
            name: "CleevioStorage",
            dependencies: [
                .product(name: "CleevioCore", package: "CleevioFramework-ios")
            ]),
        .testTarget(
            name: "CleevioStorageTests",
            dependencies: ["CleevioStorage"]),
    ]
)
