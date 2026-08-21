public import Storage_Generational_Primitives
public import Store_Primitive

public protocol __StoreGenerationalProtocol: ~Copyable {

    associatedtype Element: ~Copyable

    mutating func unshare()

    mutating func insert(_ element: consuming Element) -> Store.Generational.Handle

    mutating func remove(_ handle: Store.Generational.Handle) -> Element?

    subscript(_ handle: Store.Generational.Handle) -> Element { get set }
}

extension __StoreGenerationalProtocol where Self: ~Copyable {

    @inlinable
    public mutating func unshare() {}
}

extension Store.Generational {

    public typealias `Protocol` = __StoreGenerationalProtocol
}
