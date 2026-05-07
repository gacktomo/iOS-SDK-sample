// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ParentSDK",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "ParentSDK", targets: ["ParentSDK"]),
    ],
    dependencies: [
        .package(path: "../ChildrenSDK"),
    ],
    targets: [
        .target(
            name: "ParentSDK",
            dependencies: ["ChildrenSDK"],
            path: "ParentSDK",
            exclude: ["ParentSDK.docc"]
        ),
    ]
)
