public import Storage_Generational_Primitives
public import Store_Primitive

public struct Node<Element: ~Copyable, let N: Int>: ~Copyable {

    public var element: Element

    public var links: InlineArray<N, Store.Generational.Handle?>

    @inlinable
    public init(element: consuming Element, links: InlineArray<N, Store.Generational.Handle?>) {
        self.element = element
        self.links = links
    }
}

extension Node: Copyable where Element: Copyable {}
