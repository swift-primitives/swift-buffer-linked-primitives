public import Buffer_Linked_Primitives

public typealias DoublyLinked<E: ~Copyable> =
    Buffer<Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, 2>>>.Linked<2>

public typealias SinglyLinked<E: ~Copyable> =
    Buffer<Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, 1>>>.Linked<1>

public typealias DoublyLinkedShared<E> =
    Buffer<Ownership.Shared<Node<E, 2>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, 2>>>>.Linked<2>

public typealias SinglyLinkedShared<E> =
    Buffer<Ownership.Shared<Node<E, 1>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, 1>>>>.Linked<1>

extension Buffer.Linked where S: ~Copyable {

    @inlinable
    public init<E>(_ elements: [E], minimumCapacity: Int) throws(Self.Error)
    where S == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>> {
        self.init(minimumCapacity: Index<E>.Count(UInt(Swift.max(minimumCapacity, Swift.max(elements.count, 1)))))
        for element in elements {
            try insertBack(element)
        }
    }

    @inlinable
    public init<E>(_ elements: [E], minimumCapacity: Int) throws(Self.Error)
    where S == Ownership.Shared<Node<E, N>, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Node<E, N>>> {
        self.init(minimumCapacity: Index<E>.Count(UInt(Swift.max(minimumCapacity, Swift.max(elements.count, 1)))))
        for element in elements {
            try insertBack(element)
        }
    }
}
