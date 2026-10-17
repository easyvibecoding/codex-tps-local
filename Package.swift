// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "CodexTPSLocal",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "CodexTPSCore", targets: ["CodexTPSCore"]),
    .executable(name: "CodexTPSLocal", targets: ["CodexTPSLocal"]),
    .executable(name: "codex-tps-local-snapshot", targets: ["CodexTPSSnapshot"]),
  ],
  targets: [
    .target(name: "CodexTPSCore"),
    .executableTarget(name: "CodexTPSLocal", dependencies: ["CodexTPSCore"]),
    .executableTarget(name: "CodexTPSSnapshot", dependencies: ["CodexTPSCore"]),
    .testTarget(name: "CodexTPSCoreTests", dependencies: ["CodexTPSCore"]),
  ]
)
