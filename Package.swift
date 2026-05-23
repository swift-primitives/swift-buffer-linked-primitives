// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-buffer-linked-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: "Buffer Linked Primitive", targets: ["Buffer Linked Primitive"]),
        .library(name: "Buffer Linked Primitives", targets: ["Buffer Linked Primitives"]),
        .library(name: "Buffer Linked Inline Primitives", targets: ["Buffer Linked Inline Primitives"]),
        .library(name: "Buffer Linked Primitives Test Support", targets: ["Buffer Linked Primitives Test Support"]),
    ],
    dependencies: [
        .package(path: "../swift-buffer-primitives"),
        .package(path: "../swift-storage-primitives"),
        .package(path: "../swift-storage-pool-primitives"),
        .package(path: "../swift-link-primitives"),
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-affine-primitives"),
        .package(path: "../swift-ordinal-primitives"),
        .package(path: "../swift-memory-primitives"),
        .package(path: "../swift-sequence-primitives"),
        .package(path: "../swift-cardinal-primitives"),
    ],
    targets: [
        .target(
            name: "Buffer Linked Primitive",
            dependencies: [
                .product(name: "Buffer Primitive", package: "swift-buffer-primitives"),
                .product(name: "Buffer Growth Primitives", package: "swift-buffer-primitives"),
                .product(name: "Storage Pool Primitives", package: "swift-storage-pool-primitives"),
                .product(name: "Storage Inline Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Initialization Primitives", package: "swift-storage-primitives"),
                .product(name: "Link Primitives", package: "swift-link-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Primitives", package: "swift-memory-primitives"),
                .product(name: "Affine Primitives", package: "swift-affine-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
            ]
        ),
        .target(
            name: "Buffer Linked Primitives",
            dependencies: [
                "Buffer Linked Primitive",
                .product(name: "Storage Pool Primitives", package: "swift-storage-pool-primitives"),
                .product(name: "Link Primitives", package: "swift-link-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Primitives", package: "swift-memory-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),
        .target(
            name: "Buffer Linked Inline Primitives",
            dependencies: [
                "Buffer Linked Primitive",
                "Buffer Linked Primitives",
                .product(name: "Storage Pool Primitives", package: "swift-storage-pool-primitives"),
                .product(name: "Storage Inline Primitives", package: "swift-storage-primitives"),
                .product(name: "Link Primitives", package: "swift-link-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Primitives", package: "swift-memory-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),
        // MARK: - Test Support
        .target(
            name: "Buffer Linked Primitives Test Support",
            dependencies: [
                "Buffer Linked Primitives",
                "Buffer Linked Inline Primitives",
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Primitives Test Support", package: "swift-memory-primitives"),
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests
        .testTarget(
            name: "Buffer Linked Primitives Tests",
            dependencies: ["Buffer Linked Primitives", "Buffer Linked Primitives Test Support"]
        ),
        .testTarget(
            name: "Buffer Linked Inline Primitives Tests",
            dependencies: ["Buffer Linked Inline Primitives", "Buffer Linked Primitives Test Support"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = [
        .enableExperimentalFeature("BuiltinModule"),
        .enableExperimentalFeature("RawLayout"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
