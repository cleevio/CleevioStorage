//
//  InMemoryStorage.swift
//
//
//  Created by Lukáš Valenta on 29.09.2023.
//

import Foundation
import CleevioCore

open class InMemoryStorage<Key: Hashable>: BaseStorage<Key>, @unchecked Sendable {
    var storage: [Key: Any] = [:]
    private let lock = NSRecursiveLock()
    private let cancelBag = CancelBag()

    open override func storageStream<T>(for key: Key, type: T.Type = T.self) -> StorageStream<T> where T : Decodable, T : Encodable {
        let stream = StorageStream<T>(currentValue: storage[key] as? T)
        stream.publisher
            .dropFirst()
            .sink { [weak self] value in
                self?.lock.lock()

                defer {
                    self?.lock.unlock()
                }
                
                self?.storage[key] = value
            }
            .store(in: cancelBag)
        return stream
    }
    
    open override func clearAll() throws {
        lock.lock()

        defer {
            lock.unlock()
        }

        try super.clearAll()
        storage = [:]
    }
}
