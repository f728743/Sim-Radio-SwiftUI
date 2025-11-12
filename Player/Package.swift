// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Player",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Player",
            targets: ["Player"]
        )
    ],
    dependencies: [
        .package(path: "../SharedUtilities/"),
        .package(path: "../MediaLibrary/")
    ],
    targets: [
        .target(
            name: "Player",
            dependencies: [
                "SharedUtilities",
                "MediaLibrary"
            ]
        )
    ]
)
