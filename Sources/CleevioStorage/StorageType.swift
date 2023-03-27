import Foundation

public protocol StorageType<Key> {
    associatedtype Key

    func storage<T: Codable>(for key: Key) -> StorageStream<T>
    func clearAll() throws
}
