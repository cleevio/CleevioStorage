import Combine
import Foundation
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
public class ObservableStorageStream<Value>: @unchecked Sendable {
    // Locking to prevent data race and achieve sendability
    @ObservationIgnored 
    private let lock = NSLock()
    private var storedValue: Value?

    public var value: Value? {
        get {
            defer { lock.unlock() }
            lock.lock()
            return storedValue
        } set {
            lock.lock()
            storedValue = newValue
            lock.unlock()
        }
    }

    required public init(currentValue: Value?) {
        self.value = currentValue
    }
}
