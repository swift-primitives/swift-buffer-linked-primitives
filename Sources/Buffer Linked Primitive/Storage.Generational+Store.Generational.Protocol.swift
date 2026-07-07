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

// MARK: - The bare move-only column conforms to the handle seam.
//
// Every witness already exists on `Storage.Generational` (the slot-map's identity surface):
// `insert(_:) -> Handle`, `remove(_:) -> Element?`, the validated `subscript(_ handle:)`.
// `unshare()` is the seam's no-op default — the bare store is statically unique.

extension Storage.Generational: Store.Generational.`Protocol`
where Allocation: ~Copyable, Element: ~Copyable {}
