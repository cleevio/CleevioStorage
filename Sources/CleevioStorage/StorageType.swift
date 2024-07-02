import Foundation

@available(macOS 10.15, *)
public protocol StorageType<Key> {
    associatedtype Key

    func storage<T: Codable>(for key: Key, type: T.Type) -> StorageStream<T>
    @available(iOS 17.0, *)
    func observableStorage<T: Codable>(for key: Key, type: T.Type) -> ObservableStorageStream<T>
    func clearAll() throws
}

@available(macOS 10.15, *)
public extension StorageType {
    func storage<T: Codable>(for key: Key) -> StorageStream<T> {
        storage(for: key, type: T.self)
    }

    @available(iOS 17.0, *)
    func observableStorage<T: Codable>(for key: Key) -> ObservableStorageStream<T> {
        observableStorage(for: key, type: T.self)
    }
}
