public import Buffer_Primitive
public import Memory_Allocator_Pool_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Ownership_Shared_Primitive
public import Storage_Generational_Primitives

extension Buffer.Linked where S: ~Copyable {

    @inlinable
    public init<E: ~Copyable>(minimumCapacity: Index<E>.Count)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        precondition(minimumCapacity > .zero, "capacity must be positive")
        let count = Int(bitPattern: minimumCapacity)
        self.init(
            storage: S.create(slotCapacity: Index<Node<E, N>>.Count(UInt(count))),
            capacity: count
        )
    }

    @inlinable
    package mutating func _growTo<E: ~Copyable>(_ minimumCapacity: Int)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        guard _capacity < minimumCapacity else { return }
        let newCapacity = Swift.max(minimumCapacity, Swift.max(_capacity * 2, 4))
        storage.grow(to: Index<Node<E, N>>.Count(UInt(newCapacity)))
        _capacity = newCapacity
    }

    @inlinable
    public mutating func ensureCapacity<E: ~Copyable>(_ minimumCapacity: Int)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        _growTo(minimumCapacity)
    }

    @inlinable
    public mutating func reserveAdditionalCapacity<E: ~Copyable>(_ additional: Int)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        _growTo(_count + additional)
    }
}

extension Buffer.Linked where S: ~Copyable {

    @inlinable
    public init<E>(minimumCapacity: Index<E>.Count)
    where
        S == Ownership.Shared<
            Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>
        >
    {
        precondition(minimumCapacity > .zero, "capacity must be positive")
        let count = Int(bitPattern: minimumCapacity)
        let store = Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>.create(
            slotCapacity: Index<Node<E, N>>.Count(UInt(count))
        )
        self.init(storage: Ownership.Shared(store), capacity: count)
    }

    @inlinable
    public init<E: ~Copyable>(minimumCapacity: Index<E>.Count)
    where
        S == Ownership.Shared<
            Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>
        >
    {
        precondition(minimumCapacity > .zero, "capacity must be positive")
        let count = Int(bitPattern: minimumCapacity)
        let store = Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>.create(
            slotCapacity: Index<Node<E, N>>.Count(UInt(count))
        )
        self.init(storage: Ownership.Shared(store), capacity: count)
    }

    @inlinable
    package mutating func _growTo<E: ~Copyable>(_ minimumCapacity: Int)
    where
        S == Ownership.Shared<
            Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>
        >
    {
        guard _capacity < minimumCapacity else { return }
        let newCapacity = Swift.max(minimumCapacity, Swift.max(_capacity * 2, 4))
        storage.grow(to: Index<Node<E, N>>.Count(UInt(newCapacity)))
        _capacity = newCapacity
    }

    @inlinable
    public mutating func ensureCapacity<E: ~Copyable>(_ minimumCapacity: Int)
    where
        S == Ownership.Shared<
            Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>
        >
    {
        _growTo(minimumCapacity)
    }

    @inlinable
    public mutating func reserveAdditionalCapacity<E: ~Copyable>(_ additional: Int)
    where
        S == Ownership.Shared<
            Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>
        >
    {
        _growTo(_count + additional)
    }
}
