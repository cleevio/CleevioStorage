//
//  InMemoryStorage.swift
//
//
//  Created by Lukáš Valenta on 29.09.2023.
//

import Foundation
import CleevioCore

@available(macOS 10.15, *)
open class InMemoryStorage<Key: KeyRepresentable>: BaseStorage<Key>, @unchecked Sendable {
    var storage: [Key: Any] = [:]
    private let lock = NSRecursiveLock()
    private let cancelBag = CancelBag()

    open override func initialValue<T>(for key: Key) throws -> T? where T : Decodable, T : Encodable {
        lock.lock()

        defer {
            lock.unlock()
        }
        guard let value = storage[key] as? T? else { throw InMemoryStorageIncorrectTypeError() }
        return value
    }

    open override func store<T>(value: T?, for key: Key) throws where T : Decodable, T : Encodable {
        lock.lock()

        defer {
            lock.unlock()
        }
        storage[key] = value
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

struct InMemoryStorageIncorrectTypeError: Error {}
