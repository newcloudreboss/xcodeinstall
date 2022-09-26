// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xcodeinstall",
    platforms: [
        .macOS(.v12)
    ],    
    products: [
        .executable(name: "xcodeinstall", targets: ["xcodeinstall"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "6.1.0"),
        .package(url: "https://github.com/sebsto/CLIlib/", from: "0.1.0")
        //.package(path: "../CLIlib")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "xcodeinstall",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SotoSecretsManager", package: "soto"),
                .product(name: "CLIlib", package: "CLIlib")
            ]
        ),
        .testTarget(
            name: "xcodeinstallTests",
            dependencies: ["xcodeinstall"]),
    ]
)
