//
//  CoreDataDecodable.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

public protocol CoreDataDecodable: AnyCoreDataDecodable {
    associatedtype CodingKeys: AnyCoreDataCodingKey
    static var identityAttribute: IdentityAttribute { get }
    func initialize(from container: CoreDataDecodingContainer<CodingKeys>) throws
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
    
    func initialize(from container: CoreDataDecodingContainer<CodingKeys>) throws {
        try defaultInitialization(from: container)
    }
        
    internal func initialize(from container: KeyedDecodingContainer<CodingKeys.Standard>) throws {
        try initialize(from: CoreDataDecodingContainer(container: container))
    }
    
    #warning("excluding and including keys is not tested")
    func defaultInitialization(from container: CoreDataDecodingContainer<CodingKeys>) throws {
        try defaultInitialization(from: container) { _ in true }
    }
    
    func defaultInitialization(from container: CoreDataDecodingContainer<CodingKeys>, with keys: [CodingKeys]) throws {
        try defaultInitialization(from: container) { key in
            keys.contains { $0.stringValue == key.stringValue }
        }
    }
    
    func defaultInitialization(from container: CoreDataDecodingContainer<CodingKeys>, skipping skippedKeys: [CodingKeys]) throws {
        try defaultInitialization(from: container) { key in
            !skippedKeys.contains { $0.stringValue == key.stringValue }
        }
    }
    
    func defaultInitialization(from container: CoreDataDecodingContainer<CodingKeys>, including where: @escaping (CodingKeys) -> Bool) throws {
        try applyValues(from: container.container, policy: `where`)
    }
}
/// A type erased protocol that is used internally to make the whole framework work.
/// You shouldn't conform this protocol manually ever, use `CoreDataDecodable` instead
public protocol AnyCoreDataDecodable: NSManagedObject, Decodable {
    static func decodeArray(from decoder: Decoder) throws -> [Any]
}

internal extension Decodable {
    static func decodeArray(from decoder: Decoder) throws -> [Any] {
        return try [Self].init(from: decoder)
    }
}

// MARK: - CoreDataDecodingContainer
#warning("Need to add decoding, contains, allkeys...")
#warning("Need to test all this method with a custom entity")
#warning("Probanly keypath keys doesn't work. Add the cganges to support it.")
#warning("Custom serialization can be tested: a) compounding 2 keys, b) changing received type")
#warning("Should include tests for unexpected id types (expecting an int and coming a string, maybe)")
public struct CoreDataDecodingContainer<CodingKeys: AnyCoreDataCodingKey> {
    let container: KeyedDecodingContainer<CodingKeys.Standard>
    
    public var codingPath: [CodingKeys] { container.codingPath.compactMap { CodingKeys(stringValue: $0.stringValue) } }
    
    public var allKeys: [CodingKeys] { container.allKeys.compactMap { CodingKeys(stringValue: $0.stringValue) } }
    
    public func contains(_ key: CodingKeys) -> Bool {
        container.contains(coreDataKey: key)
    }
    
    public func decodeNil(forKey key: CodingKeys) throws -> Bool {
        let c = container.nestedContainer(forCoreDataKey: key) ?? container
        return try c.decodeNil(forKey: key.standarized)
    }
    
    public func decode<T>(_ type: T.Type, forKey key: CodingKeys) throws -> T where T : Decodable {
        let c = container.nestedContainer(forCoreDataKey: key) ?? container
        return try c.decode(T.self, forKey: key.standarized)
    }
    
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: CodingKeys) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let c = container.nestedContainer(forCoreDataKey: key) ?? container
        return try c.nestedContainer(keyedBy: NestedKey.self, forKey: key.standarized)
    }
    
    public func nestedUnkeyedContainer(forKey key: CodingKeys) throws -> UnkeyedDecodingContainer {
        let c = container.nestedContainer(forCoreDataKey: key) ?? container
        return try c.nestedUnkeyedContainer(forKey: key.standarized)
    }
    
    public func superDecoder() throws -> Decoder {
        try container.superDecoder()
    }
    
    public func superDecoder(forKey key: CodingKeys) throws -> Decoder {
        try container.superDecoder(forKey: key.standarized)
    }
}


// MARK: - Error

public enum CoreDataCodableError: Error {
    case missingContext(decoder: Decoder)
    case missingOrInvalidIdentityAttribute(class: AnyClass, identityAttributes: [String], receivedKeys: [String])
}
