import Foundation

@available(macOS 10.15, *)
public protocol StorageType<Key> {
    associatedtype Key

    func storage<T: Codable>(for key: Key) -> StorageStream<T>
    func clearAll() throws
}
