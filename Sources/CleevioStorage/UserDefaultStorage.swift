import Foundation
import CleevioCore

open class UserDefaultsStorage: StorageType {
    enum StorageError: LocalizedError {
        case bundleNotFound
    }

    private let cancelBag = CancelBag()

    private let store: UserDefaults
    private let errorLogging: ErrorLogging?
    
    public init(store: UserDefaults = .standard, errorLogging: ErrorLogging?) {
        self.store = store
        self.errorLogging = errorLogging
    }
    
    public func storage<T: Codable>(for key: String) -> StorageStream<T> {
        let stream = StorageStream<T>(currentValue: store.get(key: key, errorLogging: errorLogging))
        stream.publisher
            .dropFirst()
            .sink { [store] value in
                store.store(value, for: key)
            }
            .store(in: cancelBag)
        return stream
    }

    public func clearAll() throws {
        guard let domain = Bundle.main.bundleIdentifier else {
            throw StorageError.bundleNotFound
        }
        UserDefaults.resetStandardUserDefaults()
        store.removePersistentDomain(forName: domain)
    }
}

private extension UserDefaults {
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
