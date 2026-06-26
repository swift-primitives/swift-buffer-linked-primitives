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
public import Memory_Allocator_Pool_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Storage_Generational_Primitives
public import Shared_Primitive

// MARK: - The COLUMN-PINNED surface: construction and growth
//
// Construction and growth cannot ride the handle seam (it carries no concrete-allocator
// capability by design), so each appears once per ratified column — the direct move-only
// generational store, and the `Shared` CoW box over it (whose grow self-gates inside `Shared`).
// Growth is handle-PRESERVING: `Storage.Generational.grow(to:)` relocates the elements into a
// fresh slot universe index-aligned, so the buffer's head/tail/link handles keep resolving — no
// relink is needed. The pins are `where ==` clauses on METHODS (extensions cannot introduce a
// free element parameter; methods can).

// MARK: - Move-only column (the default ownership column)

extension Buffer.Linked where S: ~Copyable {
    /// Creates an empty linked list whose node store holds `minimumCapacity` nodes.
    @inlinable
    public init<E: ~Copyable>(minimumCapacity: Index<E>.Count)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        precondition(minimumCapacity > .zero, "capacity must be positive")
        let count = Int(bitPattern: minimumCapacity)
        self.init(storage: S.create(slotCapacity: Index<Node<E, N>>.Count(UInt(count))), capacity: count)
    }

    /// Grows the node store to at least `minimumCapacity`, preserving handles index-aligned.
    ///
    /// The new capacity is `max(minimumCapacity, currentCapacity * 2, 4)`. The store relocates
    /// the live nodes into a fresh slot universe at the SAME indices, so head/tail/links keep
    /// resolving — no relink.
    ///
    /// - Complexity: O(n)
    @inlinable
    package mutating func _growTo<E: ~Copyable>(_ minimumCapacity: Int)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        guard _capacity < minimumCapacity else { return }
        let newCapacity = Swift.max(minimumCapacity, Swift.max(_capacity * 2, 4))
        storage.grow(to: Index<Node<E, N>>.Count(UInt(newCapacity)))
        _capacity = newCapacity
    }

    /// Ensures the node store can hold at least `minimumCapacity` nodes (relocating growth).
    ///
    /// - Complexity: O(n) when growth occurs.
    @inlinable
    public mutating func ensureCapacity<E: ~Copyable>(_ minimumCapacity: Int)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        _growTo(minimumCapacity)
    }

    /// Ensures there is room for at least `additional` more nodes.
    ///
    /// - Complexity: O(n) when growth occurs.
    @inlinable
    public mutating func reserveAdditionalCapacity<E: ~Copyable>(_ additional: Int)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        _growTo(_count + additional)
    }
}

// MARK: - Shared CoW column (the value-semantic column)

extension Buffer.Linked where S: ~Copyable {
    /// Creates an empty CoW (value-semantic) linked list on the `Shared` column.
    ///
    /// The element is statically `Copyable` HERE: the construction site is where the column's
    /// clone strategy is captured (`Shared`'s constructors split on element copyability).
    @inlinable
    public init<E>(minimumCapacity: Index<E>.Count)
    where S == Shared<Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>> {
        precondition(minimumCapacity > .zero, "capacity must be positive")
        let count = Int(bitPattern: minimumCapacity)
        let store = Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>.create(
            slotCapacity: Index<Node<E, N>>.Count(UInt(count))
        )
        self.init(storage: Shared(store), capacity: count)
    }

    /// Creates an empty statically-unique linked list of move-only elements on the `Shared`
    /// column (the boxed flavor of the move-only regime — useful when the box's O(1) move matters).
    @inlinable
    public init<E: ~Copyable>(minimumCapacity: Index<E>.Count)
    where S == Shared<Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>> {
        precondition(minimumCapacity > .zero, "capacity must be positive")
        let count = Int(bitPattern: minimumCapacity)
        let store = Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>.create(
            slotCapacity: Index<Node<E, N>>.Count(UInt(count))
        )
        self.init(storage: Shared(store), capacity: count)
    }

    /// Grows the node store on the `Shared` column (uniqueness restored FIRST, inside `Shared.grow`).
    ///
    /// - Complexity: O(n)
    @inlinable
    package mutating func _growTo<E: ~Copyable>(_ minimumCapacity: Int)
    where S == Shared<Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>> {
        guard _capacity < minimumCapacity else { return }
        let newCapacity = Swift.max(minimumCapacity, Swift.max(_capacity * 2, 4))
        storage.grow(to: Index<Node<E, N>>.Count(UInt(newCapacity)))
        _capacity = newCapacity
    }

    /// Ensures the node store can hold at least `minimumCapacity` nodes (`Shared` column).
    ///
    /// - Complexity: O(n) when growth occurs.
    @inlinable
    public mutating func ensureCapacity<E: ~Copyable>(_ minimumCapacity: Int)
    where S == Shared<Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>> {
        _growTo(minimumCapacity)
    }

    /// Ensures there is room for at least `additional` more nodes (`Shared` column).
    ///
    /// - Complexity: O(n) when growth occurs.
    @inlinable
    public mutating func reserveAdditionalCapacity<E: ~Copyable>(_ additional: Int)
    where S == Shared<Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>> {
        _growTo(_count + additional)
    }
}
