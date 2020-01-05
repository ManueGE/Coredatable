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

/// A protocol that must conform any `NSManagedObject` that needs to be decoded using `Coredatable`.
/// Just the `CodingKeys` typealias is required, all the other methods / properties are optional.
public protocol CoreDataDecodable: AnyCoreDataDecodable {
    /// The coding keys used to decode the objects
    associatedtype CodingKeys: AnyCoreDataCodingKey
    
    /// The identity attributes used to ensure uniqueness. Default is `.no`
    static var identityAttribute: IdentityAttribute { get }
    
    /// Allows modifying the container before start the decoding process
    static func container(for decoder: Decoder) throws -> AnyCoreDataKeyedDecodingContainer
    
    /// Override this method to perform custom decoding.
    func initialize(from decoder: Decoder) throws
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
    
    static func container(for decoder: Decoder) throws -> AnyCoreDataKeyedDecodingContainer {
        return try decoder.container(for: Self.self)
    }
    
    internal static func preparedContainer(for decoder: Decoder) throws -> CoreDataKeyedDecodingContainer<Self> {
        return try container(for: decoder).casted()
    }
    
    func initialize(from decoder: Decoder) throws {
        try defaultInitialization(from: decoder)
    }
    
    /// Runs the default initialization process taking all the Keys in account
    func defaultInitialization(from decoder: Decoder) throws {
        try defaultInitialization(from: decoder) { _ in true }
    }
    
    /// Runs the default initialization using only the specified keys
    func defaultInitialization(from decoder: Decoder, with keys: [CodingKeys]) throws {
        try defaultInitialization(from: decoder) { key in
            keys.contains { $0.stringValue == key.stringValue }
        }
    }
    
    /// Runs the default initialization skipping the given keys
    func defaultInitialization(from decoder: Decoder, skipping skippedKeys: [CodingKeys]) throws {
        try defaultInitialization(from: decoder) { key in
            !skippedKeys.contains { $0.stringValue == key.stringValue }
        }
    }
    
    /// Runs the default initialization including only the keys which return `true`in the given block
    func defaultInitialization(from decoder: Decoder, including where: @escaping (CodingKeys) -> Bool) throws {
        let container = try Self.preparedContainer(for: decoder)
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
    case propertyNotDecodable(class: NSManagedObject.Type, property: NSPropertyDescription)
    case invalidContainer(Decodable.Type, container: AnyCoreDataKeyedDecodingContainer)
}
