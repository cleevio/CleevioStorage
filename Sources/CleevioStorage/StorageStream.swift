import Combine
import Observation

@available(macOS 10.15, *)
open class StorageStream<Value>: @unchecked Sendable {
    public var publisher: AnyPublisher<Value?, Never> {
        currentValueSubject.eraseToAnyPublisher()
    }

    public var value: Value? {
        get {
            currentValueSubject.value
        } set {
            store(newValue)
        }
    }

    private let currentValueSubject: CurrentValueSubject<Value?, Never>

    required public init(currentValue: Value?) {
        self.currentValueSubject = CurrentValueSubject(currentValue)
    }

    public func store(_ value: Value?) {
        currentValueSubject.send(value)
    }
}

@available(iOS 17.0, *)
@available(macOS 14.0, *)
@Observable
public class ObservableStorageStream<Value> {
    public var value: Value?

    required public init(currentValue: Value?) {
        self.value = currentValue
    }
}
