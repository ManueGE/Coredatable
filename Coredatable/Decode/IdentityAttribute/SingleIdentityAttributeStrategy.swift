//
//  SingleIdentityAttributeStrategy.swift
//  Coredatable
//
//  Created by Manu on 11/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal struct SingleIdentityAttributeStrategy: IdentityAttributeStrategy {
    let propertyName: String
    
    func existingObject<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: CoreDataKeyedDecodingContainer<ManagedObject>) throws -> ManagedObject? {
        let identifier = try findIdentifier(for: ManagedObject.self, in: container, context: context)
        return try existingObjects(context: context, ids: [identifier]).first
    }
    
    func decodeArray<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: UnkeyedDecodingContainer, decoder: Decoder) throws -> [ManagedObject] {
        var identifiers: [AnyHashable] = []
        var objectContainersById: [AnyHashable: CoreDataKeyedDecodingContainer<ManagedObject>] = [:]
        // find the id for any object in the container
        var idsContainer = container
        while !idsContainer.isAtEnd {
            do {
                let objectContainer = try idsContainer.nestedContainer(keyedBy: ManagedObject.CodingKeys.Standard.self)
                let coreDataObjectContainer = try CoreDataKeyedDecodingContainer<ManagedObject>.from(objectContainer)
                let identifier = try findIdentifier(for: ManagedObject.self, in: coreDataObjectContainer, context: context) as AnyHashable
                identifiers.append(identifier)
                objectContainersById[identifier] = coreDataObjectContainer
            } catch {
                let identityAttribute = try self.identityAttribute(ManagedObject.self, context: context)
                if let identifier = idsContainer.decode(identityAttribute) as? AnyHashable {
                    identifiers.append(identifier)
                } else {
                    throw error
                }
            }
        }
        
        // find the existing objects with those ids
        let existingObjects: [ManagedObject] = try self.existingObjects(context: context, ids: identifiers.map { $0 })
        let existingObjectsById: [AnyHashable: ManagedObject] = existingObjects.reduce(into: [:]) { (result, object) in
            if let identifier = object.value(forKey: propertyName) as? AnyHashable {
                result[identifier] = object
            }
        }
        
        // Create or update objects
        return try identifiers.compactMap { identifier in
            guard let key = ManagedObject.CodingKeys(propertyName: propertyName) else {
                throw CoreDataDecodingError.missingOrInvalidIdentityAttribute(class: ManagedObject.self, identityAttributes: [propertyName], receivedKeys: [])
            }
            
            let rootObject = existingObjectsById[identifier] ?? ManagedObject(context: context)
            
            if let objectContainer = objectContainersById[identifier] {
                try rootObject.initialize(from: objectContainer)
            } else {
                let valueContainer = AnyValueKeyedDecodingContainer<ManagedObject>(value: identifier, codingKey: key, rootCodingPath: container.codingPath, decoder: decoder)
                try rootObject.initialize(from: valueContainer.standarized())
            }
            
            return rootObject
        }
    }
    
    func decodeObject<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: SingleValueDecodingContainer, decoder: Decoder) throws -> ManagedObject {
        var container = container
        let identityAttribute = try self.identityAttribute(ManagedObject.self, context: context)
        guard let codingKey = ManagedObject.CodingKeys(propertyName: propertyName),
            let identifier = container.decode(identityAttribute) else {
            throw CoreDataDecodingError.missingOrInvalidIdentityAttribute(class: ManagedObject.self, identityAttributes: [propertyName], receivedKeys: [])
        }
        let object = try existingObjects(context: context, ids: [identifier]).first ?? ManagedObject(context: context)
        let singleValueContainer = SingleValueKeyedDecodingContainer<ManagedObject>(singleValueContainer: container, codingKey: codingKey, decoder: decoder)
        try object.initialize(from: singleValueContainer.standarized())
        return object
    }
    
    // MARK: - Helpers
    private func findIdentifier<ManagedObject: CoreDataDecodable>(for _: ManagedObject.Type, in container: CoreDataKeyedDecodingContainer<ManagedObject>, context: NSManagedObjectContext) throws -> AnyHashable {
        let identityAttribute = try self.identityAttribute(ManagedObject.self, context: context)
        guard let codingKey = ManagedObject.CodingKeys(propertyName: propertyName),
            let value = container.decode(identityAttribute, forKey: codingKey) as? AnyHashable
            else {
                let receivedKeys = container.allKeys.map { $0.stringValue }
                throw CoreDataDecodingError.missingOrInvalidIdentityAttribute(class: ManagedObject.self, identityAttributes: [propertyName], receivedKeys: receivedKeys)
        }
        return value
    }
    
    private func existingObjects<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, ids: [Any]) throws -> [ManagedObject] {
        let request = NSFetchRequest<ManagedObject>(entityName: ManagedObject.entity(inManagedObjectContext: context).name!)
        if ids.count == 1 {
            request.fetchLimit = 1
        }
        request.predicate = NSPredicate(format: "\(propertyName) IN %@", ids)
        return try context.fetch(request)
    }
    
    private func identityAttribute<ManagedObject: CoreDataDecodable>(_: ManagedObject.Type, context: NSManagedObjectContext) throws -> NSAttributeDescription {
        let entity = ManagedObject.entity(inManagedObjectContext: context)
        guard let attribute = entity.propertiesByName[propertyName] as? NSAttributeDescription else {
            throw CoreDataDecodingError.missingOrInvalidIdentityAttribute(class: ManagedObject.self, identityAttributes: [propertyName], receivedKeys: [])
        }
        return attribute
    }
}

// MARK: - Custom Containers
/// These containers are used to be able to create a new KeyedDecodingContainer from other values.
private protocol IdentifierContainer: KeyedDecodingContainerProtocol {
    associatedtype ManagedObject: CoreDataDecodable
    var decoder: Decoder { get }
    var codingKey: ManagedObject.CodingKeys { get }
    var rootCodingPath: [CodingKey] { get }
}

extension IdentifierContainer {
    
    var allKeys: [CoreDataCodingKeyStandarizer<ManagedObject.CodingKeys>] { [codingKey.standarized] }
    
    var codingPath: [CodingKey] { rootCodingPath + [codingKey.standarized] }
    
    func contains(_ key: CoreDataCodingKeyStandarizer<ManagedObject.CodingKeys>) -> Bool {
        return key.stringValue == codingKey.standarized.stringValue
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "")
        if contains(key) {
            throw DecodingError.typeMismatch(Dictionary<AnyHashable, Any>.self, context)
        } else {
            throw DecodingError.keyNotFound(key, context)
        }
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "")
        if contains(key) {
            throw DecodingError.typeMismatch(Array<Any>.self, context)
        } else {
            throw DecodingError.keyNotFound(key, context)
        }
    }
    
    func superDecoder() throws -> Decoder {
        decoder
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        decoder
    }

    func standarized() -> KeyedDecodingContainer<Key> {
        return KeyedDecodingContainer(self)
    }
}

/// Creates a `KeyedDecodingContainer` using a `SingleValueDecodingContainer`
private struct SingleValueKeyedDecodingContainer<ManagedObject: CoreDataDecodable>: IdentifierContainer {
    typealias Key = ManagedObject.CodingKeys.Standard
    
    let singleValueContainer: SingleValueDecodingContainer
    let codingKey: ManagedObject.CodingKeys
    let decoder: Decoder
    
    var rootCodingPath: [CodingKey] { singleValueContainer.codingPath }
        
    func decodeNil(forKey key: CoreDataCodingKeyStandarizer<ManagedObject.CodingKeys>) throws -> Bool {
        singleValueContainer.decodeNil()
    }
    
    func decode<T>(_ type: T.Type, forKey key: CoreDataCodingKeyStandarizer<ManagedObject.CodingKeys>) throws -> T where T : Decodable {
        try singleValueContainer.decode(T.self)
    }
}

/// Creates a `KeyedDecodingContainer` using any value.
private struct AnyValueKeyedDecodingContainer<ManagedObject: CoreDataDecodable>: IdentifierContainer {
    typealias Key = ManagedObject.CodingKeys.Standard
    
    let value: Any
    let codingKey: ManagedObject.CodingKeys
    let rootCodingPath: [CodingKey]
    let decoder: Decoder

    func decodeNil(forKey key: CoreDataCodingKeyStandarizer<ManagedObject.CodingKeys>) throws -> Bool {
        return false
    }
    
    func decode<T>(_ type: T.Type, forKey key: CoreDataCodingKeyStandarizer<ManagedObject.CodingKeys>) throws -> T where T : Decodable {
        if let value = value as? T {
            return value
        } else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "")
            throw DecodingError.typeMismatch(T.self, context)
        }
    }
}
