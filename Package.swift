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
        // MARK: - Type module (the lean ~Copyable Buffer.Linked type over its storage substrate)
        .library(name: "Buffer Linked Primitive", targets: ["Buffer Linked Primitive"]),
        // MARK: - [MOD-005] umbrella (re-exports the type module and the Buffer/Storage/Memory vocabulary)
        .library(name: "Buffer Linked Primitives", targets: ["Buffer Linked Primitives"]),
        .library(name: "Buffer Linked Primitives Test Support", targets: ["Buffer Linked Primitives Test Support"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-buffer-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-storage-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-storage-generational-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-heap-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-allocation-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-shared-primitives.git", branch: "main"),
    ],
    targets: [

        // MARK: - Type module — the un-phantomed Buffer<S>.Linked<N> over generational node storage
        .target(
            name: "Buffer Linked Primitive",
            dependencies: [
                .product(name: "Buffer Primitive", package: "swift-buffer-primitives"),
                .product(name: "Store Primitive", package: "swift-storage-primitives"),
                .product(name: "Storage Generational Primitives", package: "swift-storage-generational-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Memory Allocator Primitive", package: "swift-memory-allocation-primitives"),
                .product(name: "Memory Allocator Pool Primitives", package: "swift-memory-allocation-primitives"),
                .product(name: "Shared Primitive", package: "swift-shared-primitives"),
            ]
        ),

        // MARK: - Umbrella
        .target(
            name: "Buffer Linked Primitives",
            dependencies: [
                "Buffer Linked Primitive"
            ]
        ),

        // MARK: - Test Support
        .target(
            name: "Buffer Linked Primitives Test Support",
            dependencies: [
                "Buffer Linked Primitives"
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests
        .testTarget(
            name: "Buffer Linked Primitives Tests",
            dependencies: ["Buffer Linked Primitives", "Buffer Linked Primitives Test Support"]
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
