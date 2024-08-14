//
//  ObservableStorageTests.swift
//  
//
//  Created by Matěj Děcký on 01.07.2024.
//

import XCTest
@testable import CleevioStorage
import ConcurrencyExtras

class UserDefaultsMock: UserDefaults {
    let lock = NSLock()
    private var dictionary: [String: Any?] = [:]

    override func value(forKey key: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }

        return dictionary[key] as Any?
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        lock.lock()
        defer { lock.unlock() }

        dictionary[defaultName] = value
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        dictionary.removeAll()
    }
}

@available(iOS 17.0, *)
@Observable
final class ObservableStorageTests: XCTestCase {
    static let storedKey = "test_key"
    let defaults = UserDefaultsMock()
    var storage: UserDefaultsStorage<String>!
    var observableStream: ObservableStorageStream<Int>!

    override func setUpWithError() throws {
        storage = .init(store: defaults, errorLogging: nil)
        observableStream = storage.observableStream(for: Self.storedKey, type: Int.self)
    }

    override func tearDown() async throws {
        defaults.reset()
    }
    
    func testValueStored() async throws {
        let storageStream: ObservableStorageStream<Int?> = storage.observableStream(for: Self.storedKey)
        await Task.yield()
        let expectation = expectation(description: "test")

        Task.detached { [defaults] in
            let value = 10
            storageStream.value = value
            for _ in 0...Int.max {
                let storedValue: Int? = try defaults.get(key: Self.storedKey)
                if value == storedValue {
                    expectation.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        await fulfillment(of: [expectation])
    }

    func testValueStoredLatestValue() async throws {
        let value = 10
        observableStream?.value = 1
        observableStream?.value = 5
        observableStream?.value = value
        let storedValue: Int? = try defaults.get(key: Self.storedKey)
        XCTAssertEqual(value, storedValue, "Stored value should be same as value")
    }

    func testTwoStreamsUseSameValue() {
        let value = 5
        let observableStream2 = storage.observableStream(for: Self.storedKey, type: Int.self)
        observableStream2.value = value
        XCTAssertEqual(observableStream?.value, value, "Streams should be synchronized")
    }

    func testObservableStorageStreamDataRace() async {
        let storageStream = ObservableStorageStream(currentValue: ["ahoj":"nazdar"])

        await withTaskGroup(of: Void.self) { group in
            for number in 0..<1000 {
                if number.isMultiple(of: 4) {
                    group.addTask {
                        print(storageStream.value?["test\(number-1)"] ?? "")
                    }
                } else {
                    group.addTask {
                        storageStream.value?["test\(number)"] = UUID().uuidString
                    }
                }
            }
        }
    }
}
