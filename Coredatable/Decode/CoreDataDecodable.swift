//
//  CoreDataDecodable.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

/// A type erased protocol that is used internally to make the whole framework work.
/// You shouldn't conform this protocol manually ever, use `CoreDataDecodable` instead
public protocol AnyCoreDataDecodable: NSManagedObject, Decodable {
    static func decodeArray(from decoder: Decoder) throws -> [Any]
}

public protocol CoreDataDecodable: AnyCoreDataDecodable {
    associatedtype CodingKeys: AnyCoreDataCodingKey
    static var identityAttribute: IdentityAttribute { get }
    static func prepare(_ container: CoreDataKeyedDecodingContainer<Self>) throws -> CoreDataKeyedDecodingContainer<Self>
    func initialize(from container: CoreDataKeyedDecodingContainer<Self>) throws
}

public extension CoreDataDecodable {
    init(from decoder: Decoder) throws {
        let coreDataDecoder = try CoreDataDecoder<Self>(decoder: decoder)
        self.init(anotherManagedObject: try coreDataDecoder.decode())
    }

    static var identityAttribute: IdentityAttribute { .no }
        
    static func decodeArray(from decoder: Decoder) throws -> [Any] {
        let coreDataDecoder = try CoreDataDecoder<Self>(decoder: decoder)
        return try coreDataDecoder.decodeArray()
    }
    
    static func prepare(_ container: CoreDataKeyedDecodingContainer<Self>) throws -> CoreDataKeyedDecodingContainer<Self> {
        return container
    }
    
    func initialize(from container: CoreDataKeyedDecodingContainer<Self>) throws {
        try defaultInitialization(from: container)
    }
        
    internal func initialize(from container: KeyedDecodingContainer<CodingKeys.Standard>) throws {
        try initialize(from: .from(container))
    }
    
    func defaultInitialization(from container: CoreDataKeyedDecodingContainer<Self>) throws {
        try defaultInitialization(from: container) { _ in true }
    }
    
    func defaultInitialization(from container: CoreDataKeyedDecodingContainer<Self>, with keys: [CodingKeys]) throws {
        try defaultInitialization(from: container) { key in
            keys.contains { $0.stringValue == key.stringValue }
        }
    }
    
    func defaultInitialization(from container: CoreDataKeyedDecodingContainer<Self>, skipping skippedKeys: [CodingKeys]) throws {
        try defaultInitialization(from: container) { key in
            !skippedKeys.contains { $0.stringValue == key.stringValue }
        }
    }
    
    func defaultInitialization(from container: CoreDataKeyedDecodingContainer<Self>, including where: @escaping (CodingKeys) -> Bool) throws {
        try applyValues(from: container, policy: `where`)
    }
}

internal extension Decodable {
    static func decodeArray(from decoder: Decoder) throws -> [Any] {
        return try [Self].init(from: decoder)
    }
}

// MARK: - Error

public enum CoreDataDecodingError: Error {
    case missingContext(decoder: Decoder)
    case missingOrInvalidIdentityAttribute(class: AnyClass, identityAttributes: [String], receivedKeys: [String])
    case relationshipNotDecodable(class: NSManagedObject.Type, relationship: NSRelationshipDescription)
}
