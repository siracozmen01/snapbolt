// swift-tools-version: 6.0
// The dependency rules in docs/architecture.md are enforced here: feature modules depend only on
// SnapboltCore, and only the app target (outside this package) sees concrete feature modules.
import PackageDescription

let core: Target.Dependency = "SnapboltCore"
let testSupport: Target.Dependency = "SnapboltTestSupport"

let featureModules = [
    "SnapboltCapture",
    "SnapboltOverlay",
    "SnapboltUpload",
    "SnapboltSettings",
    "SnapboltHistory",
    "SnapboltSystem",
    "SnapboltWorkflow",
]

/// Feature modules that have a `<Module>Tests` target. Each plan task adds its module here.
let testedModules = [
    "SnapboltWorkflow",
    "SnapboltUpload",
    "SnapboltCapture",
    "SnapboltOverlay",
    "SnapboltSettings",
    "SnapboltHotkeys",
    "SnapboltHistory",
]

let package = Package(
    name: "SnapboltKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(
            name: "SnapboltKit",
            targets: ["SnapboltCore", "SnapboltHotkeys"] + featureModules
        )
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", .upToNextMinor(from: "3.1.0"))
    ],
    targets: [
        .target(name: "SnapboltCore"),
        .target(name: "SnapboltHotkeys", dependencies: [core, "KeyboardShortcuts"]),
        .target(name: "SnapboltTestSupport", dependencies: [core]),
        .testTarget(name: "SnapboltCoreTests", dependencies: [core, testSupport]),
    ]
        + featureModules.map { .target(name: $0, dependencies: [core]) }
        + testedModules.map { .testTarget(name: "\($0)Tests", dependencies: [.byName(name: $0), core, testSupport]) },
    swiftLanguageModes: [.v6]
)
