// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Storage_Generational_Primitives
public import Store_Primitive

/// A linked-list node living in generational storage — the element plus `N` links.
///
/// The links are generational handles (`Store.Generational.Handle?`, the non-generic carrier),
/// not pointers or boxes: a node never contains a node and the storage never contains itself,
/// which lets `Buffer<S>.Linked` hold a genuinely varying
/// `S == Storage<…Pool>.Generational<Node<Element, N>>`. A `nil` link marks the end of the list.
///
/// Link convention: `links[0]` = next; `links[1]` = prev (when `N >= 2`).
///
/// This type is declared at module level rather than nested under `Buffer<S>.Linked`, because the
/// substrate `S` names the node and a nested spelling would recurse.
public struct Node<Element: ~Copyable, let N: Int>: ~Copyable {
    /// The user element this node carries.
    public var element: Element

    /// The generational links — `links[0]` = next, `links[1]` = prev (`N >= 2`); `nil` = end.
    public var links: InlineArray<N, Store.Generational.Handle?>

    /// Creates a node carrying the given element and its link handles.
    @inlinable
    public init(element: consuming Element, links: InlineArray<N, Store.Generational.Handle?>) {
        self.element = element
        self.links = links
    }
}

// MARK: - Conditional Conformance

/// A node is `Copyable` exactly when its element is: the links are an `InlineArray` of trivially
/// `Copyable` generational handles. This is the leaf of the S5 copyability chain — it is what
/// makes `Shared<Node<E, N>, …>` (and thus `Buffer<Shared<…>>.Linked`) `Copyable` when `E` is.
extension Node: Copyable where Element: Copyable {}
