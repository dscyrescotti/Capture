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
        .package(path: "../Utility")
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Utility", package: "Utility")
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
