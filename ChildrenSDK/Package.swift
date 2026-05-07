// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChildrenSDK",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "ChildrenSDK", targets: ["ChildrenSDK"]),
    ],
    dependencies: [
        .package(path: "../UISDK"),
    ],
    targets: [
        .target(
            name: "ChildrenSDK",
            dependencies: ["UISDK"],
            path: "ChildrenSDK",
            exclude: ["ChildrenSDK.docc"],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
