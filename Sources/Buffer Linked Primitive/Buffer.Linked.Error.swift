public import Buffer_Primitive

extension Buffer.Linked where S: ~Copyable {

    public enum Error: Swift.Error, Sendable, Equatable {

        case capacityExceeded
    }
}
