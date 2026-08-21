public import Storage_Generational_Primitives
public import Store_Primitive

extension Storage.Generational: Store.Generational.`Protocol`
where Allocation: ~Copyable, Element: ~Copyable {}
