public import Buffer_Primitive
public import Storage_Generational_Primitives
public import Store_Primitive

extension Buffer.Linked where S: Store.Generational.`Protocol`, S: ~Copyable {

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

    @inlinable
    public mutating func removeBack<E: ~Copyable>() -> E?
    where S.Element == Node<E, N> {
        guard let handle = tail else { return nil }
        storage.unshare()
        let previous: Store.Generational.Handle?
        if N >= 2 {
            previous = storage[handle].links[1]
        } else {

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

extension Buffer.Linked where S: Store.Generational.`Protocol`, S: ~Copyable {

    @inlinable
    public mutating func removeAll<E: ~Copyable>()
    where S.Element == Node<E, N> {
        while removeFront() as E? != nil {}
    }
}

extension Buffer.Linked where S: Store.Generational.`Protocol`, S: ~Copyable {

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

extension Buffer.Linked where S: Store.Generational.`Protocol`, S: ~Copyable {

    @inlinable
    public func peekFront<E: ~Copyable, R, Failure: Swift.Error>(
        _ body: (borrowing E) throws(Failure) -> R
    ) throws(Failure) -> R?
    where S.Element == Node<E, N> {
        guard let handle = head else { return nil }
        return try body(storage[handle].element)
    }

    @inlinable
    public func peekBack<E: ~Copyable, R, Failure: Swift.Error>(
        _ body: (borrowing E) throws(Failure) -> R
    ) throws(Failure) -> R?
    where S.Element == Node<E, N> {
        guard let handle = tail else { return nil }
        return try body(storage[handle].element)
    }
}
