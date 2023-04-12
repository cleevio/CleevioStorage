import Foundation

@available(macOS 10.15, *)
public protocol StorageType<Key> {
    associatedtype Key

    func storage<T: Codable>(for key: Key, type: T.Type) -> StorageStream<T>
    func clearAll() throws
}

extension StorageType {
    func storage<T: Codable>(for key: Key) -> StorageStream<T> {
        storage(for: key, type: T.self)
    }
}
