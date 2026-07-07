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

// MARK: - Store.Generational.`Protocol` (Hoisted as __StoreGenerationalProtocol)

/// The generational slot-map HANDLE capability — the seam `Buffer<S>.Linked<N>` rides.
///
/// A deletable convenience code-share vehicle ([API-IMPL-023]): the linked family writes its
/// node operations ONCE over this seam, and both ratified columns conform — the bare move-only
/// generational store (`Storage<…Pool>.Generational<Node>`) and the `Shared` CoW box over it.
/// The canonical spellings stay concrete; this protocol exists only so the link-maintenance ops
/// (`insert` → handle, `subscript(handle)`, `remove`) are not pinned per column.
///
/// ## Why the HANDLE surface, not the positional `Store.`Protocol`` seam
///
/// A slot-map's occupancy is sparse and its positions are non-canonical after removals, so the
/// dense-prefix positional seam (`subscript(slot:)` / `initialize(at:)` / `move(at:)`) is the
/// wrong surface for a linked list. Link maintenance is performed over generational handles
/// (`Store.Generational.Handle?`, `nil` = end of list); this seam exposes exactly that.
///
/// ## The mutation gate
///
/// `unshare()` is the copy-on-write gate, defaulted to a no-op: the bare store is
/// statically unique and inherits it; the `Shared` column overrides it (restoring uniqueness).
/// Generic mutating ops call it before their first write, so the same body is CoW-correct on the
/// `Shared` column and free on the move-only column. The seam's own mutators ALSO self-gate
/// (`Shared+Generational.swift`) — defense in depth + `Sendable` soundness.
public protocol __StoreGenerationalProtocol: ~Copyable {
    /// The element stored in each slot — the linked node.
    associatedtype Element: ~Copyable

    /// The copy-on-write gate (defaulted no-op; `Shared` overrides). Generic code calls this
    /// before its first write in any semantic mutation.
    mutating func unshare()

    /// Inserts an element; returns a fresh handle to its slot.
    mutating func insert(_ element: consuming Element) -> Store.Generational.Handle

    /// Removes the element at `handle` (moved out); `nil` if the handle is stale or invalid.
    mutating func remove(_ handle: Store.Generational.Handle) -> Element?

    /// Validated access to the element at `handle`.
    ///
    /// Spelled `{ get set }` — `{ _read _modify }` does not parse as a protocol subscript
    /// requirement on Apple Swift 6.3.2 — and witnessed with `_read` / `_modify` coroutines,
    /// which carry the `~Copyable` element without a copy.
    subscript(_ handle: Store.Generational.Handle) -> Element { get set }
}

// MARK: - Default (statically-unique stores)

extension __StoreGenerationalProtocol where Self: ~Copyable {
    /// Plain stores have no shared backing to restore; the gate is a no-op.
    @inlinable
    public mutating func unshare() {}
}

// MARK: - Namespace Typealias

extension Store.Generational {
    /// The generational slot-map HANDLE capability contract.
    ///
    /// `Store.Generational.`Protocol`` is the seam both linked-family columns conform to — the
    /// bare move-only generational store and the `Shared` CoW box over it. Declared at module
    /// scope as `__StoreGenerationalProtocol` and aliased here per the hoisted-protocol idiom
    /// ([PKG-NAME-006]); `associatedtype Element: ~Copyable` relies on the
    /// `SuppressedAssociatedTypes` experimental feature.
    public typealias `Protocol` = __StoreGenerationalProtocol
}
