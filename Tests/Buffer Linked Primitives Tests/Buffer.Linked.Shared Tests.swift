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

import Buffer_Linked_Primitives
import Buffer_Linked_Primitives_Test_Support
import Testing

// MARK: - The Shared (CoW value-semantic) column
//
// `Buffer<Shared<Node, …Generational>>.Linked` is `Copyable` when the element is, and copies share
// the backing box until the first mutation restores uniqueness (a generation-preserving clone, so
// the buffer's head/tail/link handles keep resolving across the detach). These tests pin the value
// semantics the move-only column deliberately does not provide.

@Suite
struct LinkedSharedTests {

    private func collect(_ list: borrowing DoublyLinkedShared<Int>) -> [Int] {
        var out: [Int] = []
        list.forEach { (e: borrowing Int) in out.append(copy e) }
        return out
    }

    // MARK: - Functional parity with the move-only column

    @Test
    func `insert, forEach, remove on the Shared column`() throws {
        var list: DoublyLinkedShared<Int> = .init(minimumCapacity: 4)
        try list.insertBack(1)
        try list.insertBack(2)
        try list.insertFront(0)  // 0, 1, 2
        #expect(list.count == 3)
        #expect(collect(list) == [0, 1, 2])
        #expect(list.removeFront() == 0)
        #expect(list.removeBack() == 2)
        #expect(collect(list) == [1])
    }

    // MARK: - Value semantics (the whole point of the column)

    @Test
    func `copy then mutate leaves the original untouched`() throws {
        var a: DoublyLinkedShared<Int> = try .init([1, 2, 3], minimumCapacity: 8)
        var b = a              // shares the box
        try b.insertBack(4)    // first mutation → CoW detach
        #expect(collect(a) == [1, 2, 3])
        #expect(collect(b) == [1, 2, 3, 4])
        #expect(a.count == 3)
        #expect(b.count == 4)
    }

    @Test
    func `both copies are independently mutable after a detach`() throws {
        var a: DoublyLinkedShared<Int> = try .init([1, 2, 3], minimumCapacity: 8)
        var b = a
        try b.insertBack(4)        // b detaches
        #expect(a.removeFront() == 1)   // a is now unique → free mutation
        try a.insertBack(9)
        #expect(collect(a) == [2, 3, 9])
        #expect(collect(b) == [1, 2, 3, 4])
    }

    @Test
    func `removeFront on a shared copy does not disturb the sibling`() throws {
        var a: DoublyLinkedShared<Int> = try .init([10, 20, 30], minimumCapacity: 8)
        var b = a
        _ = b.removeFront()        // mutation → detach
        _ = b.removeFront()
        #expect(collect(a) == [10, 20, 30])
        #expect(collect(b) == [30])
    }

    // MARK: - Growth on the Shared column (handle-preserving)

    @Test
    func `growth preserves order and value semantics`() throws {
        var a: DoublyLinkedShared<Int> = .init(minimumCapacity: 2)
        try a.insertBack(1)
        try a.insertBack(2)
        #expect(a.isFull)
        var b = a                  // shares the box
        b.ensureCapacity(8)        // mutation → detach + grow b only
        try b.insertBack(3)
        #expect(collect(a) == [1, 2])
        #expect(collect(b) == [1, 2, 3])
        #expect(b.capacity >= 8)
        #expect(a.capacity == 2)
    }

    // MARK: - Singly-linked Shared column

    @Test
    func `singly-linked Shared column round-trips`() throws {
        var list: SinglyLinkedShared<Int> = try .init([5, 6, 7], minimumCapacity: 4)
        #expect(list.removeFront() == 5)
        #expect(list.removeBack() == 7)   // O(n) walk
        #expect(list.removeFront() == 6)
        #expect(list.isEmpty)
    }
}
