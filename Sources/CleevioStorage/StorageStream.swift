
import Combine
import Foundation
import Observation
import CleevioCore

@available(macOS 10.15, *)
open class StorageStream<Value>: @unchecked Sendable {
    var onChange: ((Value?) -> Void)?

    public private(set) lazy var id = ObjectIdentifier(self)
    private let currentValueSubject: CurrentValueSubject<Value?, Never>

    public var publisher: AnyPublisher<Value?, Never> {
        let publisher = currentValueSubject.eraseToAnyPublisher()
        setAssociatedObject(base: self, key: &id, value: self)
        return publisher
    }

    public var value: Value? {
        get {
            currentValueSubject.value
        } set {
            store(newValue)
        }
    }

    required public init(currentValue: Value?) {
        self.currentValueSubject = CurrentValueSubject(currentValue)
    }

    public func store(_ value: Value?) {
        currentValueSubject.send(value)
        onChange?(value)
    }
}

extension StorageStream: Identifiable { }
extension StorageStream: Equatable {
    public static func == (lhs: StorageStream<Value>, rhs: StorageStream<Value>) -> Bool {
        lhs.id == rhs.id
    }
}

extension StorageStream: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@available(watchOS 10.0, *)
@available(iOS 17.0, *)
@available(macOS 14.0, *)
@Observable
public class ObservableStorageStream<Value>: @unchecked Sendable {
    var onChange: ((Value?) -> Void)?
    // Locking to prevent data race and achieve sendability
    @ObservationIgnored 
    private let lock = NSRecursiveLock()
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
            onChange?(newValue)
        }
    }

    required public init(currentValue: Value?) {
        self.value = currentValue
    }
}
