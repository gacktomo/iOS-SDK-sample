// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UISDK",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "UISDK", targets: ["UISDK"]),
    ],
    targets: [
        .target(
            name: "UISDK",
            path: "UISDK",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
