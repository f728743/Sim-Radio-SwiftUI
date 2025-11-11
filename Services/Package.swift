// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Services",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Services",
            targets: ["Services"]
        )
    ],
    dependencies: [
        .package(path: "../SharedUtilities/")
    ],
    targets: [
        .target(
            name: "Services",
            dependencies: [
                "SharedUtilities"
            ]
        )
    ]
)
