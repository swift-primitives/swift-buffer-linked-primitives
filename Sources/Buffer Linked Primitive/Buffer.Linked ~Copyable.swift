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

// MARK: - The COLUMN-GENERIC surface (rides the `Store.Generational.`Protocol`` handle seam)
//
// Every node operation is written ONCE over the seam both ratified columns conform to — the bare
// move-only generational store and the `Shared` CoW box over it. Each method carries the user
// element `E` as a free parameter and pins `S.Element == Node<E, N>` (an extension cannot
// introduce a free element parameter; a bare `S` cannot project the node's payload). Link
// maintenance runs over generational handles (`nil` marks the end of the list): `links[0]` = next,
// `links[1]` = prev (`N >= 2`). The validated handle subscript guards every link write (occupancy
// plus generation); the store's deinitializer owns all teardown.
//
// Semantic mutations call `storage.unshare()` before their first write, so the same
// generic body is copy-on-write-correct on the `Shared` column and free on the move-only column.
// CONSTRUCTION and GROWTH pin per column (they need a concrete allocator) — see
// `Buffer.Linked+Columns.swift`.

// MARK: - Direct double-ended operations

extension Buffer.Linked where S: Store.Generational.`Protocol`, S: ~Copyable {
    /// Links a freshly inserted head node.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func insertFront<E: ~Copyable>(_ element: consuming E) throws(Self.Error)
    where S.Element == Node<E, N> {
        guard _count < _capacity else { throw .capacityExceeded }
        storage.unshare()
        var links = InlineArray<N, Store.Generational.Handle?>(repeating: nil)
        links[0] = head
        let handle = storage.insert(Node(element: element, links: links))
        if N >= 2, let old = head {
            storage[old].links[1] = handle
        }
        head = handle
        if tail == nil { tail = handle }
        _count &+= 1
    }

    /// Links a freshly inserted tail node.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func insertBack<E: ~Copyable>(_ element: consuming E) throws(Self.Error)
    where S.Element == Node<E, N> {
        guard _count < _capacity else { throw .capacityExceeded }
        storage.unshare()
        var links = InlineArray<N, Store.Generational.Handle?>(repeating: nil)
        if N >= 2 { links[1] = tail }
        let handle = storage.insert(Node(element: element, links: links))
        if let old = tail {
            storage[old].links[0] = handle
        }
        tail = handle
        if head == nil { head = handle }
        _count &+= 1
    }

    /// Unlinks and returns the head element.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func removeFront<E: ~Copyable>() -> E?
    where S.Element == Node<E, N> {
        guard let handle = head else { return nil }
        storage.unshare()
        let next = storage[handle].links[0]
        guard let node = storage.remove(handle) else { return nil }
        head = next
        if N >= 2, let n = next {
            storage[n].links[1] = nil
        }
        if head == nil { tail = nil }
        _count &-= 1
        return node.element
    }

    /// Unlinks and returns the tail element.
    ///
    /// - Complexity: O(1) for `N >= 2`; O(n) for `N == 1`
    @inlinable
    public mutating func removeBack<E: ~Copyable>() -> E?
    where S.Element == Node<E, N> {
        guard let handle = tail else { return nil }
        storage.unshare()
        let previous: Store.Generational.Handle?
        if N >= 2 {
            previous = storage[handle].links[1]
        } else {
            // Singly-linked: walk to the node whose next is the tail.
            var walk = head
            var found: Store.Generational.Handle? = nil
            while let cursor = walk, cursor != handle {
                if storage[cursor].links[0] == handle { found = cursor }
                walk = storage[cursor].links[0]
            }
            previous = found
        }
        guard let node = storage.remove(handle) else { return nil }
        tail = previous
        if let p = previous {
            storage[p].links[0] = nil
        }
        if tail == nil { head = nil }
        _count &-= 1
        return node.element
    }
}

// MARK: - Remove All

extension Buffer.Linked where S: Store.Generational.`Protocol`, S: ~Copyable {
    /// Removes all elements from the list.
    ///
    /// The node store is retained.
    ///
    /// - Complexity: O(n)
    @inlinable
    public mutating func removeAll<E: ~Copyable>()
    where S.Element == Node<E, N> {
        while removeFront() as E? != nil {}
    }
}

// MARK: - Traversal

extension Buffer.Linked where S: Store.Generational.`Protocol`, S: ~Copyable {
    /// Calls the given closure for each element, front to back.
    ///
    /// - Complexity: O(n)
    @inlinable
    public func forEach<E: ~Copyable, Failure: Swift.Error>(
        _ body: (borrowing E) throws(Failure) -> Void
    ) throws(Failure)
    where S.Element == Node<E, N> {
        var cursor = head
        while let handle = cursor {
            try body(storage[handle].element)
            cursor = storage[handle].links[0]
        }
    }

    /// Calls the given closure for each element, back to front.
    ///
    /// - Precondition: `N >= 2` (doubly-linked).
    /// - Complexity: O(n)
    @inlinable
    public func forEachReversed<E: ~Copyable, Failure: Swift.Error>(
        _ body: (borrowing E) throws(Failure) -> Void
    ) throws(Failure)
    where S.Element == Node<E, N> {
        precondition(N >= 2, "forEachReversed requires N >= 2 (doubly-linked)")
        var cursor = tail
        while let handle = cursor {
            try body(storage[handle].element)
            cursor = storage[handle].links[1]
        }
    }
}

// MARK: - Peek

extension Buffer.Linked where S: Store.Generational.`Protocol`, S: ~Copyable {
    /// Peeks at the front element without removing it; `nil` result if the list is empty.
    ///
    /// - Complexity: O(1)
    @inlinable
    public func peekFront<E: ~Copyable, R, Failure: Swift.Error>(
        _ body: (borrowing E) throws(Failure) -> R
    ) throws(Failure) -> R?
    where S.Element == Node<E, N> {
        guard let handle = head else { return nil }
        return try body(storage[handle].element)
    }

    /// Peeks at the back element without removing it; `nil` result if the list is empty.
    ///
    /// - Complexity: O(1)
    @inlinable
    public func peekBack<E: ~Copyable, R, Failure: Swift.Error>(
        _ body: (borrowing E) throws(Failure) -> R
    ) throws(Failure) -> R?
    where S.Element == Node<E, N> {
        guard let handle = tail else { return nil }
        return try body(storage[handle].element)
    }
}
