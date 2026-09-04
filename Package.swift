// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "JustTodo",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "JustTodoKit"),
        .executableTarget(name: "JustTodoApp", dependencies: ["JustTodoKit"]),
        .testTarget(name: "JustTodoKitTests", dependencies: ["JustTodoKit"]),
    ]
)