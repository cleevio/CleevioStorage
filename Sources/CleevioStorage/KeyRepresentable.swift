//
//  Created by Matěj Děcký on 15.07.2024.
//

import Foundation

public protocol KeyRepresentable: Hashable {
    associatedtype KeyValue
    // This has to be named differently then rawValue otherwise there is as issue within compile time with RawValue protocol.
    var keyValue: KeyValue { get }
}

public extension KeyRepresentable where Self: RawRepresentable, Self.RawValue == KeyValue {
    var keyValue: KeyValue { rawValue }
}

extension String: KeyRepresentable {
    public var keyValue: String { self }
}
