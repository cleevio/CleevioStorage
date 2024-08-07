import Foundation
import CleevioCore

@available(macOS 10.15, *)
open class UserDefaultsStorage<Key: KeyRepresentable>: BaseStorage<Key>, @unchecked Sendable where Key.KeyValue == String {
    enum StorageError: LocalizedError {
        case bundleNotFound
    }

    private let cancelBag = CancelBag()
    private let readQueue = DispatchQueue(label: "user_default_storage_ququq", qos: .default)

    private let store: UserDefaults
    private let errorLogging: ErrorLogging?
    
    public init(store: UserDefaults = .standard, errorLogging: ErrorLogging?) {
        self.store = store
        self.errorLogging = errorLogging
    }
    
    override public func storageStream<T: Codable>(for key: Key, type: T.Type = T.self) -> StorageStream<T> {
        let stream = StorageStream<T>(currentValue: store.get(key: key.keyValue, errorLogging: errorLogging))
        stream.publisher
            .dropFirst()
            .sink { [store] value in
                store.store(value, for: key.keyValue)
            }
            .store(in: cancelBag)
        return stream
    }

    @available(iOS 17.0, *)
    open override func observableStorageStream<T>(for key: Key, type: T.Type = T.self) -> ObservableStorageStream<T> where T : Decodable, T : Encodable {
        let stream = ObservableStorageStream<T>(currentValue: store.get(key: key.keyValue, errorLogging: errorLogging))
        let modelDidChange = AsyncStream {
            await withCheckedContinuation { continuation in
                let _ = withObservationTracking {
                    let _ = stream.value
                } onChange: {
                    continuation.resume()
                }
            }
        }

        Task {
            for await _ in modelDidChange {
                Task.detached(priority: .userInitiated) { [store] in
                    try await Task.sleep(nanoseconds: 10000000)
                    store.store(stream.value, for: key.keyValue)
                }
            }
        }
        return stream
    }

    override public func clearAll() throws {
        try super.clearAll()

        guard let domain = Bundle.main.bundleIdentifier else {
            throw StorageError.bundleNotFound
        }
        UserDefaults.resetStandardUserDefaults()
        store.removePersistentDomain(forName: domain)
    }
}

extension UserDefaults {
    func store<T: Codable>(_ value: T?, for key: String) {
        guard let value else {
            return removeObject(forKey: key)
        }
        let data = try? JSONEncoder().encode(value)
        set(data, forKey: key)
    }

    func get<T: Codable>(key: String, of type: T.Type = T.self, errorLogging: ErrorLogging?) -> T? {
        guard let data = value(forKey: key) as? Data else {
            return nil
        }
        do {
            let object = try JSONDecoder().decode(T.self, from: data)
            return object
        } catch {
            errorLogging?.log(error)
            return nil
        }
    }
}
