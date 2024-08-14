import Foundation
import KeychainAccess
import CleevioCore
import CleevioStorage

@available(macOS 10.15, *)
open class KeychainStorage<Key: KeyRepresentable>: BaseStorage<Key>, @unchecked Sendable where Key.KeyValue == String {
    private let cancelBag = CancelBag()
    private let keychain: Keychain

    public init(keychain: Keychain, errorLogging: ErrorLogging?) {
        self.keychain = keychain
        super.init(errorLogging: errorLogging)
    }

    open override func initialValue<T>(for key: Key) throws -> T? where T : Decodable, T : Encodable {
        try keychain.get(key: key.keyValue)
    }

    open override func store<T>(value: T?, for key: Key) throws where T : Decodable, T : Encodable {
        try keychain.store(value, for: key.keyValue)
    }

    override public func clearAll() throws {
        try super.clearAll()
        try keychain.removeAll()
    }
}

private extension Keychain {
    func store<T: Codable>(_ value: T?, for key: String) throws {
        guard let value else {
            return try remove(key)
        }

        let data = try JSONEncoder().encode(value)
        try set(data, key: key)
    }

    func get<T: Codable>(key: String, of type: T.Type = T.self) throws -> T? {
        guard let data = self[data: key] else {
            return nil
        }
        let object = try JSONDecoder().decode(T.self, from: data)
        return object
    }
}
