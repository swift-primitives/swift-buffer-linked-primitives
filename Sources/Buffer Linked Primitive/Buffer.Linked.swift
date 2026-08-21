public import Buffer_Primitive
public import Storage_Generational_Primitives
public import Store_Primitive

extension Buffer where S: ~Copyable {

    @frozen
    public struct Linked<let N: Int>: ~Copyable {

        @usableFromInline
        package var storage: S

        @usableFromInline
        package var head: Store.Generational.Handle?

        @usableFromInline
        package var tail: Store.Generational.Handle?

        @usableFromInline
        package var _count: Int

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

extension Buffer.Linked where S: ~Copyable {

    @inlinable
    public var count: Int { _count }

    @inlinable
    public var isEmpty: Bool { _count == 0 }

    @inlinable
    public var capacity: Int { _capacity }

    @inlinable
    public var isFull: Bool { _count == _capacity }
}

extension Buffer.Linked: Copyable where S: Copyable {}

extension Buffer.Linked: @unchecked Sendable where S: Sendable {}
