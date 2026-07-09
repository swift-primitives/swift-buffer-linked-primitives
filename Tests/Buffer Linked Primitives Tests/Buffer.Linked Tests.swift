import Buffer_Linked_Primitives
import Buffer_Linked_Primitives_Test_Support
import Testing

// MARK: - Fixtures

/// ~Copyable element with identity + recording deinit (teardown-oracle observation).
private struct Item: ~Copyable {
    let id: Int
    var value: Int
    init(_ id: Int, value: Int = 0) {
        self.id = id
        self.value = value
    }
    deinit { Probe.recordDestroy(id) }
}

/// Serialized destruction recorder (the suite below is `.serialized`).
private enum Probe {}

extension Probe {
    nonisolated(unsafe) static var _destroyed: [Int] = []
    static func reset() { unsafe _destroyed = [] }
    static func recordDestroy(_ id: Int) { unsafe _destroyed.append(id) }
    static var destroyed: [Int] { unsafe _destroyed }
    static var destroyedSorted: [Int] { unsafe _destroyed.sorted() }
}

@Suite(.serialized)
struct `Buffer.Linked Tests` {

    // MARK: - Insert / remove (all four combinations, doubly-linked)

    @Test
    func `insertFront and removeFront`() throws {
        var list: DoublyLinked<Int> = .init(minimumCapacity: 4)
        try list.insertFront(1)
        try list.insertFront(2)
        try list.insertFront(3)  // 3, 2, 1
        let c = list.count
        #expect(c == 3)
        #expect(list.removeFront() == 3)
        #expect(list.removeFront() == 2)
        #expect(list.removeFront() == 1)
        #expect(list.removeFront() as Int? == nil)
        let empty = list.isEmpty
        #expect(empty)
    }

    @Test
    func `insertBack and removeBack`() throws {
        var list: DoublyLinked<Int> = .init(minimumCapacity: 4)
        try list.insertBack(1)
        try list.insertBack(2)
        try list.insertBack(3)  // 1, 2, 3
        #expect(list.removeBack() == 3)
        #expect(list.removeBack() == 2)
        #expect(list.removeBack() == 1)
        #expect(list.removeBack() as Int? == nil)
    }

    @Test
    func `insertFront and removeBack`() throws {
        var list: DoublyLinked<Int> = .init(minimumCapacity: 4)
        try list.insertFront(1)
        try list.insertFront(2)
        try list.insertFront(3)  // 3, 2, 1
        #expect(list.removeBack() == 1)
        #expect(list.removeBack() == 2)
        #expect(list.removeBack() == 3)
    }

    @Test
    func `insertBack and removeFront`() throws {
        var list: DoublyLinked<Int> = .init(minimumCapacity: 4)
        try list.insertBack(1)
        try list.insertBack(2)
        try list.insertBack(3)  // 1, 2, 3
        #expect(list.removeFront() == 1)
        #expect(list.removeFront() == 2)
        #expect(list.removeFront() == 3)
    }

    // MARK: - Singly-linked (N == 1)

    @Test
    func `singly-linked removeBack walks`() throws {
        var list: SinglyLinked<Int> = .init(minimumCapacity: 4)
        try list.insertBack(1)
        try list.insertBack(2)
        try list.insertBack(3)
        #expect(list.removeBack() == 3)  // O(n) walk
        #expect(list.removeBack() == 2)
        #expect(list.removeBack() == 1)
        #expect(list.removeBack() as Int? == nil)
        let empty = list.isEmpty
        #expect(empty)
    }

    // MARK: - Traversal

    @Test
    func `forEach traverses front to back`() throws {
        let list: DoublyLinked<Int> = try .init([10, 20, 30], minimumCapacity: 4)
        var visited: [Int] = []
        list.forEach { (e: borrowing Int) in visited.append(copy e) }
        #expect(visited == [10, 20, 30])
    }

    @Test
    func `forEachReversed traverses back to front`() throws {
        let list: DoublyLinked<Int> = try .init([10, 20, 30], minimumCapacity: 4)
        var visited: [Int] = []
        list.forEachReversed { (e: borrowing Int) in visited.append(copy e) }
        #expect(visited == [30, 20, 10])
    }

    // MARK: - Peek

    @Test
    func `peekFront and peekBack`() throws {
        let list: DoublyLinked<Int> = try .init([10, 20, 30], minimumCapacity: 4)
        let front = list.peekFront { (e: borrowing Int) in copy e }
        let back = list.peekBack { (e: borrowing Int) in copy e }
        #expect(front == 10)
        #expect(back == 30)
        let c = list.count
        #expect(c == 3)  // peek does not remove
    }

    // MARK: - Growth

    @Test
    func `growth preserves elements and order`() throws {
        var list: DoublyLinked<Int> = .init(minimumCapacity: 2)
        try list.insertBack(1)
        try list.insertBack(2)
        let full = list.isFull
        #expect(full)
        list.ensureCapacity(8)  // relocating growth
        let cap = list.capacity
        #expect(cap >= 8)
        try list.insertBack(3)
        var visited: [Int] = []
        list.forEach { (e: borrowing Int) in visited.append(copy e) }
        #expect(visited == [1, 2, 3])
        #expect(list.removeBack() == 3)
        #expect(list.removeFront() == 1)
    }

    @Test
    func `reserveAdditionalCapacity grows relative to count`() throws {
        var list: DoublyLinked<Int> = .init(minimumCapacity: 2)
        try list.insertBack(1)
        list.reserveAdditionalCapacity(7)
        let cap = list.capacity
        #expect(cap >= 8)
        let c = list.count
        #expect(c == 1)
    }

    // MARK: - Capacity limit

    @Test
    func `insert past capacity throws capacityExceeded`() throws {
        var list: DoublyLinked<Int> = .init(minimumCapacity: 2)
        try list.insertBack(1)
        try list.insertBack(2)
        var didThrow = false
        do throws(DoublyLinked<Int>.Error) {
            try list.insertBack(3)
        } catch {
            didThrow = error == .capacityExceeded
        }
        #expect(didThrow)
        let c = list.count
        #expect(c == 2)
    }

    // MARK: - Remove all

    @Test
    func `removeAll clears list and the store is reusable`() throws {
        var list: DoublyLinked<Int> = try .init([1, 2, 3], minimumCapacity: 4)
        list.removeAll()
        let c = list.count
        let empty = list.isEmpty
        #expect(c == 0)
        #expect(empty)
        try list.insertBack(9)  // slots recycle
        #expect(list.removeFront() == 9)
    }

    // MARK: - Count tracking

    @Test
    func `count tracks inserts and removes`() throws {
        var list: DoublyLinked<Int> = .init(minimumCapacity: 4)
        let c0 = list.count
        #expect(c0 == 0)
        try list.insertFront(1)
        try list.insertBack(2)
        let c2 = list.count
        #expect(c2 == 2)
        _ = list.removeFront() as Int?
        let c1 = list.count
        #expect(c1 == 1)
        _ = list.removeBack() as Int?
        let cEnd = list.count
        let empty = list.isEmpty
        #expect(cEnd == 0)
        #expect(empty)
    }

    // MARK: - Teardown (the generational store destroys exactly the live nodes)

    @Test
    func `teardown destroys every live element exactly once`() throws {
        Probe.reset()
        do {
            var list: DoublyLinked<Item> = .init(minimumCapacity: 4)
            try list.insertBack(Item(1, value: 10))
            try list.insertBack(Item(2, value: 20))
            try list.insertFront(Item(3, value: 30))
            let mid = Probe.destroyed
            #expect(mid.isEmpty)  // moves, not copies
        }  // buffer dies → the generational oracle fires
        let ds = Probe.destroyedSorted
        #expect(ds == [1, 2, 3])
    }

    @Test
    func `removed element is destroyed by the caller, not the oracle`() throws {
        Probe.reset()
        do {
            var list: DoublyLinked<Item> = .init(minimumCapacity: 4)
            try list.insertBack(Item(7, value: 70))
            try list.insertBack(Item(8, value: 80))
            guard let taken = list.removeFront() as Item? else {
                Issue.record("expected an element")
                return
            }
            let tid = taken.id
            #expect(tid == 7)
            let dMid = Probe.destroyed
            #expect(dMid.isEmpty)  // still alive in `taken`
            _ = consume taken
            let dTaken = Probe.destroyedSorted
            #expect(dTaken == [7])
        }
        let ds = Probe.destroyedSorted
        #expect(ds == [7, 8])  // the remaining node via the oracle
    }

    // MARK: - Move-only element surface (singly)

    @Test
    func `move-only elements flow through insert, peek, remove`() throws {
        Probe.reset()
        do {
            var list: SinglyLinked<Item> = .init(minimumCapacity: 2)
            try list.insertFront(Item(4, value: 40))
            let v = list.peekFront { (e: borrowing Item) in e.value }
            #expect(v == 40)
            guard let taken = list.removeFront() as Item? else {
                Issue.record("expected an element")
                return
            }
            let tv = taken.value
            #expect(tv == 40)
            _ = consume taken
        }
        let ds = Probe.destroyedSorted
        #expect(ds == [4])
    }
}
