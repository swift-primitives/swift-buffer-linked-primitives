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

public import Shared_Primitive
public import Storage_Generational_Primitives
public import Store_Primitive
public import Memory_Heap_Primitives
public import Memory_Allocator_Primitive
public import Memory_Allocator_Pool_Primitives

// MARK: - The `Shared` CoW column conforms to the handle seam.
//
// Witnesses are the self-gating forwarders on `Shared` (swift-shared-primitives'
// `Shared+Generational.swift`): `insert` / `remove` / `subscript(_ handle:)` restore uniqueness
// before writing; `prepareForMutation()` is `Shared`'s own CoW gate. The conformance is pinned to
// the heap-pool generational column — the only column that owns the handle surface.

extension Shared: Store.Generational.`Protocol`
where Element: ~Copyable, B == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element> {}
