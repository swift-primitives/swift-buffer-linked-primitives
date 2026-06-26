# Buffer Linked Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

A move-only, pool-backed linked list over the `Buffer` namespace: singly- or doubly-linked by a compile-time link count, with O(1) front and back insert/remove and support for noncopyable (`~Copyable`) elements.

---

## Quick Start

`Buffer.Linked<N>` is a linked list whose nodes live in a generational node pool rather than in individually allocated boxes. The link count `N` is a compile-time value: `Buffer.Linked<1>` is singly-linked (next only; O(n) `removeBack`), while `Buffer.Linked<2>` is doubly-linked (next + prev, giving O(1) `removeBack`). Every operation carries its element type, so the same buffer holds copyable or `~Copyable` elements without a separate variant.

```swift
import Buffer_Linked_Primitives

// The truthful storage spelling is a generational node pool on the heap.
// Name it once, then use the short alias.
typealias List<Element: ~Copyable> =
    Buffer<Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<Element, 2>>>.Linked<2>

// A doubly-linked deque of eight nodes.
var queue: List<Int> = .init(minimumCapacity: 8)
try queue.insertBack(1)
try queue.insertBack(2)
try queue.insertFront(0)            // 0, 1, 2

print(queue.count)                  // 3
let head: Int? = queue.removeFront()    // 0
queue.peekFront { print($0) }           // 1
```

Inserting past `minimumCapacity` either throws `Buffer.Linked.Error.capacityExceeded` (the direct `insert` path) or relocates into a larger pool when you call `ensureCapacity(_:)` / `reserveAdditionalCapacity(_:)` first. The buffer carries no `deinit`: teardown belongs to the generational store, whose occupancy ledger destroys exactly the live nodes — and their elements — when the buffer is dropped.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-buffer-linked-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Buffer Linked Primitives", package: "swift-buffer-linked-primitives"),
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux / Windows toolchain).

---

## Architecture

Two library products plus a test-support product. The list type is move-only over a move-only generational substrate; value semantics enter higher in the stack.

| Product | Target | Purpose |
|---------|--------|---------|
| `Buffer Linked Primitive` | `Sources/Buffer Linked Primitive/` | The lean move-only `Buffer<S>.Linked<N>` type — its stored state, double-ended insert/remove, traversal, peek, and relocating growth, plus the `Node<Element, N>` storage node and `Buffer.Linked.Error`. |
| `Buffer Linked Primitives` | `Sources/Buffer Linked Primitives/` | Umbrella — re-exports the type module and the `Buffer` / `Storage` / `Memory` vocabulary needed to spell the storage column. |
| `Buffer Linked Primitives Test Support` | `Tests/Support/` | Test conveniences: `DoublyLinked` / `SinglyLinked` aliases and an array-seeded initializer. |

Foundation-free.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |

---

## Related Packages

- [`swift-buffer-primitives`](https://github.com/swift-primitives/swift-buffer-primitives) — the `Buffer` namespace and capacity-growth vocabulary this discipline extends.

---

## Community

<!-- BEGIN: discussion -->
<!-- Discussion thread created at publication. -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
