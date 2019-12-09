//
//  AnyCoreDataCodingKey.swift
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
public protocol AnyCoreDataCodingKey {
    init?(stringValue: String)
    var stringValue: String { get }
    
    init?(propertyName: String)
    var propertyName: String { get }
}

/// Use this alias in string typed enums to make them conform `AnyCoreDataCodingKey` automatically
public typealias CoreDataCodingKey = AnyCoreDataCodingKey & CaseIterable


/// Extension which automatically implements `AnyCoreDataCodingKey` in string typed enums which are `CaseIterable` too.
/// It uses the raw nome of the enum case as `propertyName`.
/// It iterates over the cases to find one named as the `propertyName` to build instances from it.
public extension AnyCoreDataCodingKey where Self: RawRepresentable, RawValue == String, Self: CaseIterable {
    init?(stringValue: String) { self.init(rawValue: stringValue) }
    var stringValue: String { rawValue}
    
    init?(propertyName: String) {
        guard let key = Self.allCases.first(where: { propertyName == $0.propertyName }) else {
            return nil
        }
        self = key
    }
    var propertyName: String { String(describing: self) }
    
}


/// An implementation of `AnyCoreDataCodingKey` where all the properties of the json are taken in account
/// and they have exactly the same name as the json keys.
public struct CoreDataDefaultCodingKeys: AnyCoreDataCodingKey {
    public let stringValue: String
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    public init?(propertyName: String) {
        self.stringValue = propertyName
    }
    public var propertyName: String { stringValue }
}

// MARK: - CoreDataCodingKeyWrapper

/// A Wrapper to convert `AnyCoreDataCodingKey` into regular `CodingKey`
internal struct CoreDataCodingKeyWrapper<Key: AnyCoreDataCodingKey>: CodingKey {
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

internal extension AnyCoreDataCodingKey {
    var standardCodingKey: CoreDataCodingKeyWrapper<Self> { CoreDataCodingKeyWrapper(self) }
}
