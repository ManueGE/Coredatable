//
//  CoreDataEncodable.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

/// A type erased protocol that is used internally to make the whole framework work.
/// You shouldn't conform this protocol manually ever, use `CoreDataEncodable` instead
public protocol AnyCoreDataEncodable: NSManagedObject, Encodable {
    static func encode(_ array: [Any], to encoder: Encoder, skipping: Set<NSRelationshipDescription>) throws
    func encode(to encoder: Encoder, skipping: Set<NSRelationshipDescription>) throws
}


/// A protocol that must conform any `NSManagedObject` that needs to be encoded using `Coredatable`.
/// Just the `CodingKeys` typealias is required, all the other methods / properties are optional.
public protocol CoreDataEncodable: AnyCoreDataEncodable {
    associatedtype CodingKeys: AnyCoreDataCodingKey
}

extension CoreDataEncodable {
    public func encode(to encoder: Encoder) throws {
        try encode(to: encoder, skipping: [])
    }
    
    public func encode(to encoder: Encoder, skipping: Set<NSRelationshipDescription>) throws {
        let encoder = CoreDataEncoder<Self>(encoder: encoder, skippingRelationships: skipping)
        try encoder.encode(self)
    }
    
    public static func encode(_ array: [Any], to encoder: Encoder, skipping: Set<NSRelationshipDescription>) throws {
        let castArray = array.compactMap { $0 as? Self }
        let coreDataEncoder = CoreDataEncoder<Self>(encoder: encoder, skippingRelationships: skipping)
        try coreDataEncoder.encode(castArray)
    }
}

internal extension Encodable {
    static func encode(_ array: [Any], to encoder: Encoder) throws {
        let castArray = array.compactMap { $0 as? Self }
        try castArray.encode(to: encoder)
    }
}

// MARK: - Error

public enum CoreDataEncodingError: Error {
    case relationshipNotEncodable(class: NSManagedObject.Type, relationship: NSRelationshipDescription)
}
