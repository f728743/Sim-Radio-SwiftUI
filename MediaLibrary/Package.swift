// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MediaLibrary",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "MediaLibrary",
            targets: ["MediaLibrary"]
        )
    ],
    dependencies: [
        .package(path: "../SharedUtilities/"),
        .package(path: "../DesignSystem/")
    ],
    targets: [
        .target(
            name: "MediaLibrary",
            dependencies: [
                "SharedUtilities",
                "DesignSystem"
            ]
        )
    ]
)
