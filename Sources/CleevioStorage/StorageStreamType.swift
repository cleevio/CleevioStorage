import Foundation
import Combine

public protocol StorageStreamType<Value>: AnyObject, Sendable {
    associatedtype Value
    
    init(currentValue: Value?)
    
    @available(macOS 10.15, *)
    var publisher: AnyPublisher<Value?, Never> { get }
    var value: Value? { get }
    
    func store(_ value: Value?)
}

extension StorageStreamType {
    @available(iOS 15.0, macOS 13.0, *)
    public var stream: AsyncPublisher<AnyPublisher<Self.Value?, Never>> {
        publisher.values
    }
}
