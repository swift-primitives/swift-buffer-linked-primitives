# Buffer Linked Primitives — Scope

What this package is, and what it deliberately leaves to its siblings.

## Overview

`swift-buffer-linked-primitives` provides the **linked-list buffer discipline** over the `Buffer`
namespace: a pool-backed linked list with O(1) front and back operations. It defines
``Buffer/Linked`` — a move-only list whose nodes live in a generational node pool — together with
its storage ``Node`` and its ``Buffer/Linked/Error``.

The link count `N` selects the node shape: ``Buffer/Linked`` with `N == 1` is singly-linked
(next only; O(n) `removeBack`), and `N >= 2` is doubly-linked (next + prev; O(1) `removeBack`).
It is one specialized buffer discipline among siblings — linear, ring, slab, slots, arena,
aligned, unbounded — each its own package. Every element type is supported, copyable or
noncopyable (`~Copyable`).

## Module shape

The package ships **two library modules**:

- A **type module** (`Buffer Linked Primitive`, singular) — the lean move-only `Buffer.Linked`
  value type, its storage `Node`, `Buffer.Linked.Error`, and the operations that touch the
  storage internals (double-ended insert and remove, traversal, peek, and relocating growth).
  These operations are `@inlinable` and live next to the storage so they remain inlinable across
  package boundaries.
- An **umbrella module** (`Buffer Linked Primitives`, plural) — re-exports the type module
  together with the `Buffer`, `Storage`, and `Memory` vocabulary needed to spell the storage
  column, so `import Buffer_Linked_Primitives` brings in the whole package.

A separate test-support product (`Buffer Linked Primitives Test Support`) supplies `DoublyLinked`
and `SinglyLinked` aliases and an array-seeded initializer for use in test targets.

## Core targets

| Module | Form | Holds |
|--------|------|-------|
| `Buffer Linked Primitive` | type | `Buffer.Linked`, `Node`, `Buffer.Linked.Error`, and the double-ended / traversal / peek / growth operations |
| `Buffer Linked Primitives` | umbrella | re-exports the type module and the `Buffer` / `Storage` / `Memory` vocabulary |

## Out of scope

| Capability | Belongs in |
|------------|------------|
| Other buffer disciplines (linear, ring, slab, slots, arena) | `swift-buffer-{linear,ring,slab,slots,arena}-primitives` |
| Aligned and unbounded buffer forms | `swift-buffer-aligned-primitives`, `swift-buffer-unbounded-primitives` |
| The `Buffer` namespace and capacity-growth vocabulary | `swift-buffer-primitives` |
| The generational node store and its handles | `swift-storage-generational-primitives`, `swift-storage-primitives` |
| The heap allocator and pool substrate | `swift-memory-heap-primitives`, `swift-memory-allocation-primitives` |
| Indices, offsets, and counts | `swift-index-primitives` |

## Evaluation rule

Additions are evaluated against this scope. A buffer form that is not the *linked* discipline
extracts to its own sibling package rather than growing this one. A new operation belongs here
only if it operates *on* a linked buffer; storage, node layout, and indexing concerns delegate to
the packages above.
