// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOSDLS",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "iOSDLS",
            targets: ["iOSDLS"]),
    ],
    dependencies: [
      .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "iOSDLS",
            path: "iOSDLS/Sources",
            resources: [.process("Resources/Colors.xcassets")],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin")]
        ),
        .testTarget(
            name: "iOSDLSTests",
            dependencies: ["iOSDLS"],
            path: "iOSDLS/Tests"),
    ]
)
