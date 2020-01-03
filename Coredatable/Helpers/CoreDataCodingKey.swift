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
    /// Creates  a new instance with the given string value
    init?(stringValue: String)
    
    /// Returns the string value of the receier
    var stringValue: String { get }
    
    /// Creates a key for the given property name
    init?(propertyName: String)
    
    /// Returns the name of the equivalent property of the `NSManagedObject`
    var propertyName: String { get }
    
    /// The string used to split the different path components. Default is `.`
    var keyPathDelimiter: String { get }
}

public extension AnyCoreDataCodingKey {
    var keyPathDelimiter: String { "." }
    var keyPathComponents: [String] { stringValue.components(separatedBy: keyPathDelimiter)}
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
/// It conforms `ExpressibleByStringLiteral`, so can be created as plain arrays. 
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

extension CoreDataDefaultCodingKeys: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.stringValue = value
    }
}

// MARK: - CoreDataCodingKeyStandarizer

internal protocol CoreDataStandardCodingKey: CodingKey {
    associatedtype CoreDataKey: AnyCoreDataCodingKey
    init(_ stringValue: String)
}

/// A wrapper to convert `AnyCoreDataCodingKey` into standard `CodingKey`
internal struct CoreDataCodingKeyStandarizer<CoreDataKey: AnyCoreDataCodingKey>: CoreDataStandardCodingKey {
    private(set) var stringValue: String
    
    init(_ stringValue: String) {
        self.stringValue = stringValue
    }
    
    fileprivate init(_ key: CoreDataKey) {
        self.stringValue = key.keyPathComponents.last ?? key.stringValue
    }
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    let intValue: Int? = nil
    
    init?(intValue: Int) { return nil }
}

internal extension AnyCoreDataCodingKey {
    typealias Standard = CoreDataCodingKeyStandarizer<Self>
    var standarized: Standard { Standard(self) }
}
