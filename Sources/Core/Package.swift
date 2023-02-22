// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "Core",
            targets: ["Core"]
        ),
    ],
    dependencies: [
        .package(path: "../Utility"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", .upToNextMajor(from: "0.1.0"))
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Utility", package: "Utility"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
