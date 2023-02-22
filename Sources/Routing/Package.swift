// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Routing",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "Routing",
            targets: ["Routing"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Routing",
            dependencies: []
        ),
        .testTarget(
            name: "RoutingTests",
            dependencies: ["Routing"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
