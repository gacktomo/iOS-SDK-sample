// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChildrenSDK",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "ChildrenSDK", targets: ["ChildrenSDK"]),
    ],
    targets: [
        .target(
            name: "ChildrenSDK",
            path: "ChildrenSDK",
            exclude: ["ChildrenSDK.docc"]
        ),
    ]
)
