// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Todo",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TodoKit", targets: ["TodoKit"]),
    ],
    targets: [
        .target(name: "TodoKit"),
        .executableTarget(name: "TodoApp", dependencies: ["TodoKit"]),
        .testTarget(name: "TodoKitTests", dependencies: ["TodoKit"]),
    ]
)