
@preconcurrency import Combine
import Foundation
import Observation
import CleevioCore

fileprivate let queue = DispatchQueue(label: "StorageStreamPublisher")

@available(macOS 10.15, *)
public final class StorageStream<Value: Sendable>: Sendable {
    private let onChange: (@Sendable (Value?) -> Void)?
    nonisolated(unsafe) private weak var valueSubject: PassthroughSubject<Value?, Never>?
    private let lock = NSRecursiveLock()
    nonisolated(unsafe) private var storedValue: Value?
    nonisolated(unsafe) private(set) var associatedObjectID = UUID()

    public var value: Value? {
        get {
            defer { lock.unlock() }
            lock.lock()
            return storedValue
        } set {
            store(newValue)
        }
    }

    public var publisher: AnyPublisher<Value?, Never> {
        defer { lock.unlock() }
        lock.lock()

        var valueSubjet = self.valueSubject

        if self.valueSubject == nil {
            queue.sync {
                valueSubjet = .init()
                self.valueSubject = valueSubjet
            }
        }

        let publisher = Publishers.Merge(Just(storedValue).eraseToAnyPublisher(), valueSubject!.eraseToAnyPublisher()).eraseToAnyPublisher()
        setAssociatedObject(base: valueSubject!, key: &associatedObjectID, value: self)
        return publisher
    }

    required nonisolated public init(currentValue: Value?, onChange: (@Sendable (Value?) -> Void)? = nil) {
        self.storedValue = currentValue
        self.onChange = onChange
    }

    nonisolated public func store(_ value: Value?) {
        defer { lock.unlock() }
        lock.lock()

        valueSubject?.send(value)
        storedValue = value
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
