//
//  InMemoryStorage.swift
//
//
//  Created by Lukáš Valenta on 29.09.2023.
//

import Foundation
import CleevioCore

open class InMemoryStorage<Key: Hashable>: BaseStorage<Key> {
    var storage: [Key: Any] = [:]
    private let cancelBag = CancelBag()

    open override func storageStream<T>(for key: Key, type: T.Type = T.self) -> StorageStream<T> where T : Decodable, T : Encodable {
        let stream = StorageStream<T>(currentValue: storage[key] as? T)
        stream.publisher
            .dropFirst()
            .sink { [weak self] value in
                self?.storage[key] = value
            }
            .store(in: cancelBag)
        return stream
    }
    
    open override func clearAll() throws {
        try super.clearAll()
        storage = [:]
    }
}
