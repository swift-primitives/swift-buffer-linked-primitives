# ``Buffer_Linked_Primitives``

A move-only, pool-backed linked list over the `Buffer` namespace — singly- or doubly-linked by a
compile-time link count, with O(1) front and back operations and support for noncopyable elements.

## Overview

`Buffer.Linked<N>` is a linked list whose nodes live in a generational node pool rather than in
individually allocated boxes. The link count `N` is a compile-time value: `Buffer.Linked<1>` is
singly-linked (next only; O(n) `removeBack`), while `Buffer.Linked<2>` is doubly-linked
(next + prev, giving O(1) `removeBack`). Insert and remove at the front, insert at the back, and
peek at either end are O(1). Every operation carries its element type, so the same buffer holds
copyable or noncopyable (`~Copyable`) elements without a separate variant.

The type is move-only over a move-only generational substrate, and it carries no deinitializer:
teardown belongs to the generational store, whose occupancy ledger destroys exactly the live
nodes — and their elements — when the buffer is dropped. Inserting past the current capacity
either throws `Buffer.Linked.Error.capacityExceeded` or, after a call to `ensureCapacity(_:)` or
`reserveAdditionalCapacity(_:)`, relocates the list into a larger pool.

```swift
import Buffer_Linked_Primitives

// The storage column is a generational node pool on the heap; name it once, then use the alias.
typealias List<Element: ~Copyable> =
    Buffer<Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<Element, 2>>>.Linked<2>

var queue: List<Int> = .init(minimumCapacity: 8)
try queue.insertBack(1)
try queue.insertBack(2)
try queue.insertFront(0)            // 0, 1, 2

let head = queue.removeFront()      // 0
queue.peekFront { print($0) }       // 1
```

Importing `Buffer_Linked_Primitives` brings in `Buffer.Linked` together with the `Buffer`,
`Storage`, and `Memory` vocabulary needed to spell its storage column.

## Topics

### The Linked Buffer

- ``Buffer/Linked``

### Supporting Types

- ``Node``
- ``Buffer/Linked/Error``

### Scope

- <doc:Buffer-Linked-Scope>
