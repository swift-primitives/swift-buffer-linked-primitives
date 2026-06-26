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

// MARK: - Iteration entry point + first / last conveniences
//
// `makeIterator` snapshots the elements front-to-back through the safe `forEach` node-walk and
// hands back a stdlib iterator over that snapshot (a linked list has no contiguous span to vend a
// borrowing span-iterator over; the snapshot is a true snapshot — a later mutation of the source
// does not disturb it). The linked ADTs forward this for their iteration / `==` faces. Holding the
// live `Shared` column in a value-type iterator and reading it through the seam's coroutine
// subscript miscompiles on Apple Swift 6.3.2 (SIGSEGV), so the snapshot path is the sound one.
// `first` / `last` lift the boundary elements out by value — both columns, through peek.

extension Buffer.Linked where S: ~Copyable {
    /// A forward iterator over a snapshot of the elements, head to tail.
    @inlinable
    public func makeIterator<E: Copyable>() -> [E].Iterator
    where S: Store.Generational.`Protocol`, S.Element == Node<E, N> {
        var elements: [E] = []
        forEach { (element: borrowing E) in elements.append(copy element) }
        return elements.makeIterator()
    }

    /// The first (head) element, or `nil` when empty.
    @inlinable
    public func first<E: Copyable>() -> E?
    where S: Store.Generational.`Protocol`, S.Element == Node<E, N> {
        peekFront { (element: borrowing E) in copy element }
    }

    /// The last (tail) element, or `nil` when empty.
    @inlinable
    public func last<E: Copyable>() -> E?
    where S: Store.Generational.`Protocol`, S.Element == Node<E, N> {
        peekBack { (element: borrowing E) in copy element }
    }
}
