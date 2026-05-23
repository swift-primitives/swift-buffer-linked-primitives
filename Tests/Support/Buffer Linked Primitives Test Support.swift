public import Buffer_Linked_Primitives
public import Index_Primitives
public import Cardinal_Primitives

// MARK: - Linked

extension Buffer.Linked {
    // Swift 6.2 CopyPropagation crash: double-consume of Property.Inout.Typed.Valued
    public init(_ elements: [Element], minimumCapacity: UInt = 0) {
        let cap = Index<Node>.Count(Cardinal(Swift.max(UInt(elements.count), minimumCapacity)))
        var buffer = Self(minimumCapacity: cap)
        for element in elements {
            buffer.insert.back(element)
        }
        self = buffer
    }
}

extension Buffer.Linked.Small {
    // Swift 6.2 CopyPropagation crash: double-consume of Property.Inout.Typed.Valued
    public init(_ elements: [Element]) {
        var buffer = Self()
        for element in elements {
            buffer.insert.back(element)
        }
        self = buffer
    }
}
