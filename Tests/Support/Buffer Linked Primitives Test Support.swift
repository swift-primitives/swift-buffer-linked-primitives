public import Buffer_Linked_Primitives

// MARK: - Test conveniences over the storage column

/// The doubly-linked heap column.
public typealias DoublyLinked<E: ~Copyable> =
    Buffer<Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, 2>>>.Linked<2>

/// The singly-linked heap column.
public typealias SinglyLinked<E: ~Copyable> =
    Buffer<Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, 1>>>.Linked<1>

/// The doubly-linked `Shared` (CoW value-semantic) heap column.
public typealias DoublyLinkedShared<E> =
    Buffer<Ownership.Shared<Node<E, 2>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, 2>>>>.Linked<2>

/// The singly-linked `Shared` (CoW value-semantic) heap column.
public typealias SinglyLinkedShared<E> =
    Buffer<Ownership.Shared<Node<E, 1>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, 1>>>>.Linked<1>

extension Buffer.Linked where S: ~Copyable {
    /// Creates a linked list populated back-to-back from an array (test convenience, move-only column).
    @inlinable
    public init<E>(_ elements: [E], minimumCapacity: Int) throws(Self.Error)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        self.init(minimumCapacity: Index<E>.Count(UInt(Swift.max(minimumCapacity, Swift.max(elements.count, 1)))))
        for element in elements {
            try insertBack(element)
        }
    }

    /// Creates a linked list populated back-to-back from an array (test convenience, `Shared` column).
    @inlinable
    public init<E>(_ elements: [E], minimumCapacity: Int) throws(Self.Error)
    where S == Ownership.Shared<Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>> {
        self.init(minimumCapacity: Index<E>.Count(UInt(Swift.max(minimumCapacity, Swift.max(elements.count, 1)))))
        for element in elements {
            try insertBack(element)
        }
    }
}
