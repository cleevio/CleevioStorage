
@preconcurrency import Combine
import Foundation
import Observation
import CleevioCore

@available(macOS 10.15, *)
public final class StorageStream<Value: Sendable>: Sendable {
    private let onChange: (@Sendable (Value?) -> Void)?
    nonisolated private let currentValueSubject: CurrentValueSubject<Value?, Never>

    public var publisher: AnyPublisher<Value?, Never> {
        var id = ObjectIdentifier(self)
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

    required nonisolated public init(currentValue: Value?, onChange: (@Sendable (Value?) -> Void)? = nil) {
        self.currentValueSubject = CurrentValueSubject(currentValue)
        self.onChange = onChange
    }

    nonisolated public func store(_ value: Value?) {
        DispatchQueue.main.sync { [currentValueSubject] in // TODO: Check why this is needed
            currentValueSubject.send(value)
        }
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
public class ObservableStorageStream<Value: Sendable>: @unchecked Sendable {
    @ObservationIgnored
    let onChange: (@Sendable (Value?) -> Void)?
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

    required public init(currentValue: Value?, onChange: (@Sendable (Value?) -> Void)? = nil) {
        self.onChange = onChange
        self.storedValue = currentValue
    }
}
