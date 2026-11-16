// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "swift-highlighting",
    platforms: [.macOS(.v27), .iOS(.v27), .tvOS(.v27), .watchOS(.v27), .visionOS(.v27)],
    products: [
        .library(name: "Highlighting", targets: ["Highlighting"]),
        .library(name: "Highlighting Swift", targets: ["Highlighting Swift"]),
    ],
    traits: [
        .trait(name: "Swift", description: "Highlighting Swift: Swift source by role, through swift-syntax and the compiler")
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "604.0.0"..<"605.0.0"),
        .package(url: "https://github.com/swift-compositions/swift-file-system.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-process.git", branch: "main"),
    ],
    targets: [
        .target(name: "Highlighting"),
        .target(
            name: "Highlighting Swift",
            dependencies: [
                .target(name: "Highlighting"),
                .product(name: "SwiftSyntax", package: "swift-syntax", condition: .when(traits: ["Swift"])),
                .product(name: "SwiftParser", package: "swift-syntax", condition: .when(traits: ["Swift"])),
                .product(name: "File System", package: "swift-file-system", condition: .when(traits: ["Swift"])),
                .product(name: "Process", package: "swift-process", condition: .when(traits: ["Swift"])),
            ]
        ),
        .testTarget(
            name: "Highlighting Swift Tests",
            dependencies: [
                .target(name: "Highlighting Swift")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
