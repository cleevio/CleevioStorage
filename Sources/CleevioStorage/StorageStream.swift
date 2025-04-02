
@preconcurrency import Combine
import Foundation
import Observation
import CleevioCore

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
            lock.lock()
            storedValue = newValue
            lock.unlock()

            onChange?(newValue)

            if let valueSubject {
                DispatchQueue.main.async {
                    valueSubject.send(newValue)
                }
            }
        }
    }

    public var publisher: AnyPublisher<Value?, Never> {
        defer { lock.unlock() }
        lock.lock()

        var valueSubject = self.valueSubject

        if self.valueSubject == nil {
            valueSubject = .init()
            self.valueSubject = valueSubject
        }

        let publisher = Publishers.Merge(Just(storedValue).eraseToAnyPublisher(), valueSubject!.eraseToAnyPublisher()).eraseToAnyPublisher()
        setAssociatedObject(base: valueSubject!, key: &associatedObjectID, value: self)
        return publisher
    }

    required nonisolated public init(currentValue: Value?, onChange: (@Sendable (Value?) -> Void)? = nil) {
        self.storedValue = currentValue
        self.onChange = onChange
    }

    @available(*, deprecated, message: "Directly set storage stream's value")
    nonisolated public func store(_ value: Value?) {
        self.value = value
    }
}

@available(macOS 10.15, *)
extension StorageStream: Identifiable { }
@available(macOS 10.15, *)
extension StorageStream: Equatable {
    public static func == (lhs: StorageStream<Value>, rhs: StorageStream<Value>) -> Bool {
        lhs.id == rhs.id
    }
}

@available(macOS 10.15, *)
extension StorageStream: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@available(watchOS 10.0, *)
@available(iOS 17.0, *)
@available(macOS 14.0, *)
@Observable
public final class ObservableStorageStream<Value: Sendable>: @unchecked Sendable {
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
