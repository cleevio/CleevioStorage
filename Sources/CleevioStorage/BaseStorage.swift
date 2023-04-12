//
//  BaseStorage.swift
//  
//
//  Created by Lukáš Valenta on 12.04.2023.
//

import Foundation

open class BaseStorage<Key: Hashable>: StorageType {
    var storages: [Key: any StorageStreamType] = [:]
    private let lock = NSRecursiveLock()

    public init() { }

    public final func storage<T: Codable>(for key: Key, type: T.Type) -> StorageStream<T> {
        lock.lock()

        defer {
            lock.unlock()
        }

        if let storage = storages[key] as? StorageStream<T> {
            return storage
        }

        let storage: StorageStream<T> = storageStream(for: key)
        storages[key] = storage

        return storage
    }

    open func storageStream<T: Codable>(for key: Key, type: T.Type = T.self) -> StorageStream<T> {
        fatalError("storageStream(for:, type:) has to be implemented")
    }

    open func clearAll() throws {
        lock.lock()

        defer {
            lock.unlock()
        }

        storages.forEach {
            let store = $0.value as? StorageStream<Any>
            store?.store(nil)
        }
    }
}
