//
//  ObservableStorageTests.swift
//  
//
//  Created by Matěj Děcký on 01.07.2024.
//

import XCTest
@testable import CleevioStorage

@available(iOS 17.0, *)
@Observable
final class ObservableStorageTests: XCTestCase {
    static let storedKey = "test_key"
    let defaults = UserDefaults.standard
    let storage = UserDefaultsStorage<String>(errorLogging: nil)
    var observableStream: ObservableStorageStream<Int>?

    override func setUpWithError() throws {
        observableStream = storage.observableStorage(for: Self.storedKey, type: Int.self)
    }

    override func tearDown() async throws {
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
    }

    func testValueStored() async throws {
        let value = 10
        observableStream?.value = value
        try await Task.sleep(for: .seconds(1))
        let storedValue: Int? = defaults.get(key: Self.storedKey, errorLogging: nil)
        XCTAssertEqual(value, storedValue, "Stored value should be same as value")
    }

    func testValueStoredLatestValue() async throws {
        let value = 10
        observableStream?.value = 1
        observableStream?.value = 5
        observableStream?.value = value
        try await Task.sleep(for: .seconds(1))
        let storedValue: Int? = defaults.get(key: Self.storedKey, errorLogging: nil)
        XCTAssertEqual(value, storedValue, "Stored value should be same as value")
    }

    func testTwoStreamsUseSameValue() {
        let value = 5
        let observableStream2 = storage.observableStorage(for: Self.storedKey, type: Int.self)
        observableStream2.value = value
        XCTAssertEqual(observableStream?.value, value, "Streams should be synchronized")
    }

    func testObservableStorageStreamDataRace() async {
        let storageStream = ObservableStorageStream(currentValue: ["ahoj":"nazdar"])

        await withTaskGroup(of: Void.self) { group in
            for number in 0..<1000 {
                if number.isMultiple(of: 4) {
                    group.addTask {
                        print(storageStream.value?["test\(number-1)"])
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
