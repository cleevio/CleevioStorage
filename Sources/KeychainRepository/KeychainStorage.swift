import Foundation
import KeychainAccess
import CleevioCore
import CleevioStorage

@available(macOS 10.15, *)
open class KeychainStorage: BaseStorage<String> {
    private let cancelBag = CancelBag()
    private let keychain: Keychain
    private let errorLogging: ErrorLogging?

    public init(keychain: Keychain, errorLogging: ErrorLogging?) {
        self.keychain = keychain
        self.errorLogging = errorLogging
    }
    
    override public func storageStream<T: Codable>(for key: Key, type: T.Type = T.self) -> StorageStream<T> {
        let stream = StorageStream<T>(currentValue: keychain.get(key: key, errorLogging: errorLogging))
        stream.publisher
            .dropFirst()
            .sink { [keychain, errorLogging] value in keychain.store(value, for: key, errorLogging: errorLogging) }
            .store(in: cancelBag)
        return stream
    }

    override public func clearAll() throws {
        try super.clearAll()
        try keychain.removeAll()
    }
}

private extension Keychain {
    func store<T: Codable>(_ value: T?, for key: String, errorLogging: ErrorLogging?) {
        do {
            guard let value else {
                return try remove(key)
            }
            
            let data = try JSONEncoder().encode(value)
            try set(data, key: key)
        } catch {
            errorLogging?.log(error)
            assertionFailure()
            return
        }
    }

    func get<T: Codable>(key: String, of type: T.Type = T.self, errorLogging: ErrorLogging?) -> T? {
        guard let data = self[data: key] else {
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
