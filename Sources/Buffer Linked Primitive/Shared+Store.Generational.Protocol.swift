public import Memory_Allocator_Pool_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Ownership_Shared_Primitive
public import Storage_Generational_Primitives
public import Store_Primitive

extension Ownership.Shared: Store.Generational.`Protocol`
where Element: ~Copyable, B == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element> {}
