//
//  CoreDataCodingKey.swift
//  Coredatable
//
//  Created by Manu on 08/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

/// A `CodingKey` replacement used to handle `CoreDataCodable`
/// The reason of having this instead of using default `CodingKey` is that in a `CodingKey` enum, there is no way to access the raw name of the case,
/// and we need it to use it as property name in a core data entity.
/// For that reason, we build this protocol and any enum that implements it (and no `CodingKey`) can access its case name.
public protocol CoreDataCodingKey {
    init?(stringValue: String)
    var stringValue: String { get }
    var propertyName: String { get }
}

/// Extension which automatically implements CoreDataCodingKey in `RawRepresentable` where `RawValue` is `String`
/// It uses the raw nome of the enum case as property name
public extension CoreDataCodingKey where Self: RawRepresentable, RawValue == String {
    init?(stringValue: String) { self.init(rawValue: stringValue) }
    var stringValue: String { rawValue}
    var propertyName: String { String(describing: self) }
    
}

/// An implementation of `CoreDataCodingKey` where all the properties are taken in account
/// and they have exactly the same name as the json keys.
public struct CoreDataDefaultCodingKeys: CoreDataCodingKey {
    public let stringValue: String
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
    public var propertyName: String { stringValue }
}

// MARK: - CoreDataCodingKeyWrapper

/// A Wrapper to convert `CoreDataCodingKey` into regular `CodingKey`
internal struct CoreDataCodingKeyWrapper<Key: CoreDataCodingKey>: CodingKey {
    let key: Key
    var stringValue: String { key.stringValue }
    
    fileprivate init(_ key: Key) {
        self.key = key
    }
    
    init?(stringValue: String) {
        guard let key = Key(stringValue: stringValue) else {
            return nil
        }
        self.init(key)
    }
    
    let intValue: Int? = nil
    
    init?(intValue: Int) { return nil }
}

extension CoreDataCodingKey {
    var standardCodingKey: CoreDataCodingKeyWrapper<Self> { CoreDataCodingKeyWrapper(self) }
}
