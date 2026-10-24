// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FoldLogCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "FoldLogCore", targets: ["FoldLogCore"])],
    targets: [
        .target(name: "FoldLogCore", path: "FoldLog/Core"),
        .testTarget(name: "FoldLogCoreTests", dependencies: ["FoldLogCore"], path: "Tests")
    ]
)
