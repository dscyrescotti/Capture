// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Feature",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "Camera",
            targets: ["Camera"]
        ),
        .library(
            name: "Gallery",
            targets: ["Gallery"]
        ),
        .library(
            name: "Photo",
            targets: ["Photo"]
        )
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Routing"),
        .package(path: "../Utility")
    ],
    targets: [
        .target(
            name: "Camera",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Routing", package: "Routing"),
                .product(name: "Utility", package: "Utility")
            ]
        ),
        .target(
            name: "Gallery",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Routing", package: "Routing"),
                .product(name: "Utility", package: "Utility")
            ]
        ),
        .target(
            name: "Photo",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Routing", package: "Routing")
            ]
        ),
        .testTarget(
            name: "FeatureTests",
            dependencies: ["Camera"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
