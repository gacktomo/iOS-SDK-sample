// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChildSDK",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "ChildSDK", targets: ["ChildSDK"]),
    ],
    dependencies: [
        .package(path: "../UISDK"),
    ],
    targets: [
        .target(
            name: "ChildSDK",
            dependencies: ["UISDK"],
            path: "ChildSDK",
            exclude: ["ChildSDK.docc"],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
