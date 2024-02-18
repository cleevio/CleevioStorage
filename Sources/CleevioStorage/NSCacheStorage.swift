//
//  NSCacheStorage.swift
//
//
//  Created by Lukáš Valenta on 29.09.2023.
//

import Foundation
import CleevioCore

/// A storage class that uses `NSCache` to efficiently manage and store objects associated with specific keys.
open class NSCacheStorage<Key: Hashable>: BaseStorage<Key>, @unchecked Sendable {
    /// The internal `NSCache` instance used for object storage.
    @usableFromInline
    let cache: NSCache<WrappedKey, AnyObject>
    private let cancelBag = CancelBag()
    
    // MARK: - Initialization
    
    /// Initializes a new `NSCacheStorage` instance.
    ///
    /// - Parameter cache: An optional `NSCache` instance to use for storage. If not provided, a new one will be created.
    @inlinable
    public init(cache: NSCache<WrappedKey, AnyObject> = .init()) {
        self.cache = cache
    }
    
    open override func storageStream<T>(for key: Key, type: T.Type = T.self) -> StorageStream<T> where T : Decodable, T : Encodable {
        let stream = StorageStream<T>(currentValue: getObject(forKey: key))
        stream.publisher
            .dropFirst()
            .sink { [weak self] value in
                self?.setObject(WrappedValue(value: value), forKey: key)
            }
            .store(in: cancelBag)
        return stream
    }
    
    open override func clearAll() throws {
        try super.clearAll()
        cache.removeAllObjects()
    }
    
    /// A wrapped key class to make it conform to the `Hashable` protocol for use with `NSCache`.
    public final class WrappedKey: Hashable {
        public static func == (lhs: NSCacheStorage<Key>.WrappedKey, rhs: NSCacheStorage<Key>.WrappedKey) -> Bool {
            lhs.key == rhs.key
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(key)
        }
        
        @usableFromInline
        let key: Key
        
        @inlinable
        init(key: Key) {
            self.key = key
        }
    }
    
    /// A wrapper class for values to be stored in the cache.
    public final class WrappedValue<Value> {
        @usableFromInline
        let value: Value
        
        @inlinable
        init(value: Value) {
            self.value = value
        }
    }
    
    /// Retrieves an object of the specified type from the cache.
    ///
    /// - Parameter key: The key associated with the object.
    /// - Returns: The object of the specified type if found in the cache, otherwise `nil`.
    private func getObject<T>(forKey key: Key) -> T? {
        let wrappedKey = WrappedKey(key: key)
        let cachedObject = cache.object(forKey: wrappedKey) as? WrappedValue<T>
        return cachedObject?.value
    }
    
    /// Sets an object in the cache.
    ///
    /// - Parameters:
    ///   - object: The object to be stored in the cache.
    ///   - key: The key associated with the object.
    private func setObject<T: AnyObject>(_ object: T?, forKey key: Key) {
        let wrappedKey = WrappedKey(key: key)
        if let object = object {
            cache.setObject(object, forKey: wrappedKey)
        } else {
            cache.removeObject(forKey: wrappedKey)
        }
    }
}
