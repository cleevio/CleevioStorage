import Testing
import CleevioStorage
import Foundation
import Combine

@Suite
struct StorageStreamTests {
    @Test
    func initialValue() async throws {
        let storageStream = StorageStream(currentValue: true)

        #expect(storageStream.value == true)
    }

    @Test
    func setValue() async throws {
        let storageStream = StorageStream(currentValue: true)
        storageStream.value = false

        #expect(storageStream.value == false)
    }

    @Test
    func onChangeCalledWhenSet() async throws {
        nonisolated(unsafe) var setValue: Bool?
        let storageStream = StorageStream(currentValue: true) {
            setValue = $0
        }
        storageStream.value = false

        #expect(setValue == false)
    }

    @Test
    func storageStreamAsyncWrite() async throws {
        @MainActor
        func initStorageStream() -> StorageStream<Bool> {
            .init(currentValue: true)
        }

        let storageStream = await initStorageStream()

        storageStream.value = false
        #expect(storageStream.value == false)
    }

    @Test
    func storageStreamAsyncWrite_parallel() async throws {
        @MainActor
        func initStorageStream() -> StorageStream<Bool> {
            .init(currentValue: true)
        }

        let storageStream = await initStorageStream()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                storageStream.value = [true, false].randomElement()
            }
        }
    }

    @Test
    func noMemoryLeak() async throws {
        weak var stream: StorageStream<Bool>?
        autoreleasepool {
            let newStream = StorageStream(currentValue: true)
            stream = newStream
        }

        #expect(stream == nil)
    }

    @Test
    func noMemoryLeak_withPublisher() async throws {
        weak var stream: StorageStream<Bool>?
        autoreleasepool {
            let newStream = StorageStream(currentValue: true)
            stream = newStream

            let _ = newStream.publisher
        }

        #expect(stream == nil)
    }

    @available(iOS 15.0, *)
    @Test
    func noDeinit_withPublisher() async throws {
        weak var stream: StorageStream<Bool>?
        var publisher: AnyPublisher<Bool?, Never>?

        autoreleasepool {
            let newStream = StorageStream(currentValue: Optional<Bool>.none)
            stream = newStream

            publisher = newStream.publisher
        }

        guard let publisher else {
            Issue.record("Should not be nil.")
            return
        }
    
        var isFirst = true
        for await value in publisher.values {
            if isFirst {
                stream?.value = true
                isFirst = false
            } else {
                #expect(value == true)
                break
            }
        }
    }
}
