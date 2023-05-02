import Combine

@available(macOS 10.15, *)
open class StorageStream<Value>: StorageStreamType {
    public var publisher: AnyPublisher<Value?, Never> {
        currentValueSubject.eraseToAnyPublisher()
    }

    public var value: Value? {
        currentValueSubject.value
    }

    private let currentValueSubject: CurrentValueSubject<Value?, Never>

    required public init(currentValue: Value?) {
        self.currentValueSubject = CurrentValueSubject(currentValue)
    }

    public func store(_ value: Value?) {
        currentValueSubject.send(value)
    }
}
