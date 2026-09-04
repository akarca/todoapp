// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TodoApp",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "TodoKit"),
        .executableTarget(name: "TodoApp", dependencies: ["TodoKit"]),
        .testTarget(name: "TodoKitTests", dependencies: ["TodoKit"]),
    ]
)
