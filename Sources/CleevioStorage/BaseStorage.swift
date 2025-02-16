//
//  BaseStorage.swift
//  
//
//  Created by Lukáš Valenta on 12.04.2023.
//

import Foundation
import CleevioCore

@available(macOS 10.15, *)
open class BaseStorage<Key: KeyRepresentable>: StorageType, @unchecked Sendable {
    struct StorageKey: Hashable {
        let kind: Kind
        let key: Key

        enum Kind { case stream, observableStream }
    }

    public let errorLogging: ErrorLogging?
    nonisolated(unsafe) private var storages: [StorageKey: WeakBox<AnyObject>] = [:]
    private let lock = NSRecursiveLock()

    public init(errorLogging: ErrorLogging?) {
        self.errorLogging = errorLogging
    }

    public final func stream<T: Codable & Sendable>(for key: Key, type: T.Type = T.self) -> StorageStream<T> {
        lock.lock()

        defer {
            lock.unlock()
        }

        let key = StorageKey(kind: .stream, key: key)

        if let storage = storages[key]?.unbox as? StorageStream<T> {
            return storage
        }

        let storage: StorageStream<T> = StorageStream(currentValue: _initialValue(for: key.key)) { [weak self] in
            self?._store(value: $0, for: key.key)
        }

        storages[key] = .init(storage)


        return storage
    }

    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    public final func observableStream<T: Codable & Sendable>(for key: Key, type: T.Type = T.self) -> ObservableStorageStream<T> {
        lock.lock()

        defer {
            lock.unlock()
        }

        let key = StorageKey(kind: .observableStream, key: key)

        if let storage = storages[key]?.unbox as? ObservableStorageStream<T> {
            return storage
        }

        let storage: ObservableStorageStream<T> = ObservableStorageStream(currentValue: _initialValue(for: key.key)) { [weak self] in
            self?._store(value: $0, for: key.key)
        }

        storages[key] = .init(storage)

        return storage
    }

    open func initialValue<T: Codable & Sendable>(for key: Key) throws -> T? {
        fatalError("initialValue(for:) has to be implemented")
    }

    open func store<T: Codable & Sendable>(value: T?, for key: Key) throws {
        fatalError("store(for:type:) has to be implemented")
    }

    private func _initialValue<T: Codable & Sendable>(for key: Key) -> T? {
        do {
            return try initialValue(for: key)
        } catch {
            errorLogging?.log(KeyError(key: key, error: error))
            return nil
        }
    }

    private func _store<T: Codable & Sendable>(value: T?, for key: Key) {
        do {
            try store(value: value, for: key)
        } catch {
            errorLogging?.log(KeyError(key: key, error: error))
        }
    }

    open func clearAll() throws {
        lock.lock()

        defer {
            lock.unlock()
        }

        storages.forEach {
            let store = $0.value.unbox as? StorageStream<Sendable>
            store?.value = nil
        }
    }
}

struct KeyError<Key: KeyRepresentable>: Error {
    let key: Key
    let error: Error
}
