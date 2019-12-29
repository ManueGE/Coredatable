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
public struct CoreDataDecodingContainer<CodingKeys: AnyCoreDataCodingKey> {
    let container: KeyedDecodingContainer<CodingKeys.Standard>
}

// MARK: - Error

public enum CoreDataCodableError: Error {
    case missingContext(decoder: Decoder)
    case missingOrInvalidIdentityAttribute(class: AnyClass, identityAttributes: [String], receivedKeys: [String])
}
