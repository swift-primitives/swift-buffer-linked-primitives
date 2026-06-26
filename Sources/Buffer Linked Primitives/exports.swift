// [MOD-005] umbrella for the linked family. It re-exports the type module so that
// `import Buffer_Linked_Primitives` brings in `Buffer<S>.Linked<N>` along with the vocabulary
// needed to spell its storage column.
@_exported public import Buffer_Linked_Primitive
