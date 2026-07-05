// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Buffer_Primitive
public import Storage_Generational_Primitives
public import Store_Primitive

extension Buffer where S: ~Copyable {

    /// A linked list over generational node storage, parameterized by link count.
    ///
    /// The `storage` field is a genuinely varying generic substrate; the full spelling is
    /// `Buffer<Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<Element, N>>>.Linked<N>`,
    /// where the substrate's element is the node and the buffer's logical element is the node's
    /// `element` payload (named by each operation). Links are generational handles
    /// (`Store.Generational.Handle?`, where `nil` marks the end of the list), so no recursive type
    /// arises.
    ///
    /// ## Link Count (N)
    ///
    /// - `N == 1`: singly-linked (next only; `removeBack` is O(n))
    /// - `N >= 2`: doubly-linked (next + prev; `removeBack` is O(1))
    ///
    /// ## Teardown
    ///
    /// This buffer carries no deinitializer and no teardown logic: liveness is tracked by the
    /// generational store (occupancy plus generation tokens), whose deinitializer destroys exactly
    /// the occupied nodes — including their elements — before the pool frees the bytes. The buffer
    /// is a thin access discipline (head and tail cursors plus links).
    ///
    /// ## Move-only
    ///
    /// `Buffer.Linked` is move-only over its move-only substrate; value semantics are not provided
    /// at this layer.
    @frozen
    public struct Linked<let N: Int>: ~Copyable {

        /// The generational node store.
        @usableFromInline
        package var storage: S

        /// Handle of the first node; `nil` when empty.
        @usableFromInline
        package var head: Store.Generational.Handle?

        /// Handle of the last node; `nil` when empty.
        @usableFromInline
        package var tail: Store.Generational.Handle?

        /// Number of elements (mirrors the storage's live occupancy; stored so the generic
        /// surface needs no concrete `S` constraint).
        @usableFromInline
        package var _count: Int

        /// Node capacity of the current storage (updated on growth).
        @usableFromInline
        package var _capacity: Int

        @inlinable
        package init(storage: consuming S, capacity: Int) {
            self.storage = storage
            self.head = nil
            self.tail = nil
            self._count = 0
            self._capacity = capacity
        }
    }
}

// MARK: - Generic surface (S-independent stored state)

extension Buffer.Linked where S: ~Copyable {
    /// Number of elements in the list.
    @inlinable
    public var count: Int { _count }

    /// Whether the list is empty.
    @inlinable
    public var isEmpty: Bool { _count == 0 }

    /// Node capacity (maximum number of nodes before growth is required).
    @inlinable
    public var capacity: Int { _capacity }

    /// Whether the node store is full (no free nodes remain).
    @inlinable
    public var isFull: Bool { _count == _capacity }
}

// MARK: - Conditional Conformances (Linked)

/// Copyability flows from the COLUMN (the S5 chain): `Buffer<Ownership.Shared<Node, …>>.Linked` is
/// `Copyable` exactly when the `Shared` box is — i.e. when the element is `Copyable` (the box is a
/// class reference, copies share until the first mutation restores uniqueness). The direct
/// move-only generational column never satisfies this, by design — it stays the zero-cost
/// statically-unique column.
extension Buffer.Linked: Copyable where S: Copyable {}

/// Sendable conformance for `Buffer.Linked`.
///
/// ## Safety Invariant
///
/// `Buffer.Linked` exclusively owns its node store (the move-only column is single-owner; the
/// `Shared` column restores uniqueness before every write — see `Box`); cross-thread transfer is
/// a move.
///
/// ## Non-Goals
///
/// - Not a shared concurrent linked buffer.
extension Buffer.Linked: @unsafe @unchecked Sendable where S: Sendable {}
