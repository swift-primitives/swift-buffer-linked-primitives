public import Buffer_Primitive
public import Storage_Generational_Primitives

extension Buffer.Linked where S: ~Copyable {

    @inlinable
    public func makeIterator<E: Copyable>() -> [E].Iterator
    where S: Store.Generational.`Protocol`, S.Element == Node<E, N> {
        var elements: [E] = []
        forEach { (element: borrowing E) in elements.append(copy element) }
        return elements.makeIterator()
    }

    @inlinable
    public func first<E: Copyable>() -> E?
    where S: Store.Generational.`Protocol`, S.Element == Node<E, N> {
        peekFront { (element: borrowing E) in copy element }
    }

    @inlinable
    public func last<E: Copyable>() -> E?
    where S: Store.Generational.`Protocol`, S.Element == Node<E, N> {
        peekBack { (element: borrowing E) in copy element }
    }
}
