// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Beeline",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_12)
    ],
    products: [
        .library(
            name: "Beeline",
            targets: ["Beeline"]),
    ],
    targets: [
        .target(
            name: "Beeline",
            path: "Beeline")
    ]
)
