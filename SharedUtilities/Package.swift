// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SharedUtilities",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SharedUtilities",
            targets: ["SharedUtilities"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            .upToNextMinor(from: "8.1.3")
        )
    ],
    targets: [
        .target(
            name: "SharedUtilities",
            dependencies: [
                "Kingfisher"
            ]
        )
    ]
)
