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
public import Store_Primitive

// MARK: - The storage column
//
// Every operation constrains the concrete spelling
// `S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>`, with the user
// element `E` as a free method parameter (the substrate's element is the node — the buffer's
// logical element is the node's payload, which a bare `S` cannot project).
//
// Link maintenance is performed directly over the generational handles (`nil` marks the end of
// the list): `links[0]` = next, `links[1]` = prev (`N >= 2`). The store's validated subscript
// guards every link write (occupancy plus generation), and the store's deinitializer owns all
// teardown.

// MARK: - Creation

extension Buffer.Linked where S: ~Copyable {
    /// Creates an empty linked list whose node store holds `minimumCapacity` nodes.
    @inlinable
    public init<E: ~Copyable>(minimumCapacity: Index<E>.Count)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        precondition(minimumCapacity > .zero, "capacity must be positive")
        let count = Int(bitPattern: minimumCapacity)
        self.init(storage: S.create(slotCapacity: Index<Node<E, N>>.Count(UInt(count))), capacity: count)
    }
}

// MARK: - Direct double-ended operations
//
// Each operation carries the user element as a free method parameter, because an extension cannot
// introduce one and a bare `S` cannot project the node's payload. The operations expose a direct
// surface (`insertFront` / `insertBack` / `removeFront` / `removeBack`).

extension Buffer.Linked where S: ~Copyable {
    /// Links a freshly inserted head node.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func insertFront<E: ~Copyable>(_ element: consuming E) throws(Self.Error)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        guard _count < _capacity else { throw .capacityExceeded }
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
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        guard _count < _capacity else { throw .capacityExceeded }
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
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        guard let handle = head else { return nil }
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
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        guard let handle = tail else { return nil }
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

extension Buffer.Linked where S: ~Copyable {
    /// Removes all elements from the list.
    ///
    /// The node store is retained.
    ///
    /// - Complexity: O(n)
    @inlinable
    public mutating func removeAll<E: ~Copyable>()
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        while removeFront() as E? != nil {}
    }
}

// MARK: - Traversal

extension Buffer.Linked where S: ~Copyable {
    /// Calls the given closure for each element, front to back.
    ///
    /// - Complexity: O(n)
    @inlinable
    public func forEach<E: ~Copyable, Failure: Swift.Error>(
        _ body: (borrowing E) throws(Failure) -> Void
    ) throws(Failure)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
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
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        precondition(N >= 2, "forEachReversed requires N >= 2 (doubly-linked)")
        var cursor = tail
        while let handle = cursor {
            try body(storage[handle].element)
            cursor = storage[handle].links[1]
        }
    }
}

// MARK: - Peek

extension Buffer.Linked where S: ~Copyable {
    /// Peeks at the front element without removing it; `nil` result if the list is empty.
    ///
    /// - Complexity: O(1)
    @inlinable
    public func peekFront<E: ~Copyable, R, Failure: Swift.Error>(
        _ body: (borrowing E) throws(Failure) -> R
    ) throws(Failure) -> R?
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
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
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        guard let handle = tail else { return nil }
        return try body(storage[handle].element)
    }
}

// MARK: - Growth

extension Buffer.Linked where S: ~Copyable {
    /// Grows the node store to at least `minimumCapacity`, relocating all elements into a fresh
    /// generational store in sequential (front-to-back) layout.
    ///
    /// The new capacity is `max(minimumCapacity, currentCapacity * 2, 4)`. The old store is
    /// fully drained through `remove` (its ledger empties), so dropping it destroys nothing —
    /// no double-teardown.
    ///
    /// - Complexity: O(n)
    @inlinable
    package mutating func _growTo<E: ~Copyable>(_ minimumCapacity: Int)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        guard _capacity < minimumCapacity else { return }
        let newCapacity = Swift.max(minimumCapacity, Swift.max(_capacity * 2, 4))
        // A single boundary conversion: `_growTo` works with `Int` internally.
        var newStorage = S.create(slotCapacity: Index<Node<E, N>>.Count(UInt(newCapacity)))

        var newHead: Store.Generational.Handle? = nil
        var newTail: Store.Generational.Handle? = nil
        var relocated = 0

        var cursor = head
        while let handle = cursor {
            cursor = storage[handle].links[0]
            guard let node = storage.remove(handle) else { continue }
            var links = InlineArray<N, Store.Generational.Handle?>(repeating: nil)
            if N >= 2 { links[1] = newTail }
            let fresh = newStorage.insert(Node(element: node.element, links: links))
            if let t = newTail {
                newStorage[t].links[0] = fresh
            }
            newTail = fresh
            if newHead == nil { newHead = fresh }
            relocated &+= 1
        }

        storage = newStorage
        head = newHead
        tail = newTail
        _count = relocated
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
