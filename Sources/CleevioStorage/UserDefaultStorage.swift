import Foundation
import CleevioCore

@available(macOS 10.15, *)
open class UserDefaultsStorage<Key: KeyRepresentable>: BaseStorage<Key>, @unchecked Sendable where Key.KeyValue == String {
    enum StorageError: LocalizedError {
        case bundleNotFound
    }

    private let cancelBag = CancelBag()

    private let store: UserDefaults
    
    public init(store: UserDefaults = .standard, errorLogging: ErrorLogging?) {
        self.store = store
        super.init(errorLogging: errorLogging)
    }

    open override func initialValue<T>(for key: Key) throws -> T? where T : Decodable, T : Encodable {
        try store.get(key: key.keyValue)
    }

    open override func store<T>(value: T?, for key: Key) throws where T : Decodable, T : Encodable {
        try store.store(value, for: key.keyValue)
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
    func store<T: Codable>(_ value: T?, for key: String) throws {
        guard let value else {
            return removeObject(forKey: key)
        }
        let data = try JSONEncoder().encode(value)
        set(data, forKey: key)
    }

    func get<T: Codable>(key: String, of type: T.Type = T.self) throws -> T? {
        guard let data = value(forKey: key) as? Data else {
            return nil
        }
        let object = try JSONDecoder().decode(T.self, from: data)
        return object
    }
}
