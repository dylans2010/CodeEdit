// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "{{PROJECT_NAME}}",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "{{PROJECT_NAME}}", path: "Sources")
    ]
)
