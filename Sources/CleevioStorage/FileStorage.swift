//
//  Created by Matěj Děcký on 15.07.2024.
//

import Foundation
import CleevioCore

public typealias Directory = FileManager.SearchPathDirectory

open class FileStorage<Key: KeyRepresentable>: BaseStorage<Key> where Key.KeyValue == String {
    private let cancelBag = CancelBag()

    private let fileManager: FileManager
    private let directory: Directory
    private let errorLogging: ErrorLogging?

    init(
        fileManager: FileManager = .default,
        directory: Directory = .cachesDirectory,
        errorLogging: ErrorLogging?
    ) {
        self.fileManager = fileManager
        self.directory = directory
        self.errorLogging = errorLogging
    }

    open override func storageStream<T: Codable>(for key: Key, type: T.Type = T.self) -> StorageStream<T> {
        let stream = StorageStream<T>(currentValue: fileManager.get(at: fileManager.cacheFile(for: key.keyValue, directory: directory), errorLogging: errorLogging))
        return stream
    }

    open override func clearAll() throws {
        try super.clearAll()
        guard let folderURL = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else { return }
        for file in try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil) where file.pathExtension == "clcache" {
            try fileManager.removeItem(at: file)
        }
    }
}

private extension FileManager {
    func cacheFile(for key: String, directory: Directory) -> URL {
        let folderURLs = urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )

        return folderURLs[0].appendingPathComponent(key + ".clcache")
    }
}

extension FileManager {
    func store<T: Codable>(_ value: T?, for url: URL) throws {
        guard let value else {
            try removeItem(at: url)
            return
        }
        let data = try JSONEncoder().encode(value)

        try data.write(to: url, options: .atomic)
    }

    func get<T: Codable>(at url: URL, of type: T.Type = T.self, errorLogging: ErrorLogging?) -> T? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        do {
            let object = try JSONDecoder().decode(T.self, from: data)
            return object
        } catch {
            errorLogging?.log(error)
            return nil
        }
    }
}
