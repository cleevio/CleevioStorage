//
//  BaseStorage.swift
//  
//
//  Created by Lukáš Valenta on 12.04.2023.
//

import Foundation
import CleevioCore

@available(macOS 10.15, *)
open class BaseStorage<Key: Hashable>: StorageType, @unchecked Sendable {
    var storages: [Key: WeakBox<AnyObject>] = [:]
    private let lock = NSRecursiveLock()

    public init() { }

    public final func storage<T: Codable>(for key: Key, type: T.Type) -> StorageStream<T> {
        lock.lock()

        defer {
            lock.unlock()
        }

        if let storage = storages[key]?.unbox as? StorageStream<T> {
            return storage
        }

        let storage: StorageStream<T> = storageStream(for: key)
        storages[key] = .init(storage)

        return storage
    }

    open func storageStream<T: Codable>(for key: Key, type: T.Type = T.self) -> StorageStream<T> {
        fatalError("storageStream(for:, type:) has to be implemented")
    }

    @available(iOS 17.0, *)
    public final func observableStorage<T: Codable>(for key: Key, type: T.Type) -> ObservableStorageStream<T> {
        lock.lock()

        defer {
            lock.unlock()
        }

        if let storage = storages[key]?.unbox as? ObservableStorageStream<T> {
            return storage
        }

        let storage: ObservableStorageStream<T> = observableStorageStream(for: key)
        storages[key] = .init(storage)

        return storage
    }

    @available(iOS 17.0, *)
    open func observableStorageStream<T: Codable>(for key: Key, type: T.Type = T.self) -> ObservableStorageStream<T> {
        fatalError("storageStream(for:, type:) has to be implemented")
    }

    open func clearAll() throws {
        lock.lock()

        defer {
            lock.unlock()
        }

        storages.forEach {
            let store = $0.value.unbox as? StorageStream<Any>
            store?.store(nil)
        }
    }
}
