// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "App",
            targets: ["App"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Routing"),
        .package(path: "../Feature")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Camera", package: "Feature"),
                .product(name: "Gallery", package: "Feature"),
                .product(name: "Routing", package: "Routing")
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
