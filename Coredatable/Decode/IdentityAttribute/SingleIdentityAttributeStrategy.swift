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
    
    func existingObject<ManagedObject>(context: NSManagedObjectContext, decoder: Decoder) throws -> ManagedObject? where ManagedObject : CoreDataDecodable {
        let container = try ManagedObject.preparedContainer(for: decoder)
        let identifier = try findIdentifier(for: ManagedObject.self, in: container, context: context)
        return try existingObjects(context: context, ids: [identifier]).first
    }
    
    func decodeArray<ManagedObject>(context: NSManagedObjectContext, decoder: Decoder) throws -> [ManagedObject] where ManagedObject : CoreDataDecodable {
        var identifiers: [AnyHashable] = []
        var decodersById: [AnyHashable: Decoder] = [:]
        // find the id for any object in the container
        let container = try decoder.unkeyedContainer()
        var idsContainer = container
        var decodersContainer = container
        while !decodersContainer.isAtEnd {
            do {
                let objectDecoder = try decodersContainer.superDecoder()
                let coreDataObjectContainer = try ManagedObject.preparedContainer(for: objectDecoder)
                let identifier = try findIdentifier(for: ManagedObject.self, in: coreDataObjectContainer, context: context) as AnyHashable
                identifiers.append(identifier)
                decodersById[identifier] = objectDecoder
                try idsContainer.skip()
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
            
            if let objectContainer = decodersById[identifier] {
                try rootObject.initialize(from: objectContainer)
            } else {
                let identityAttributeDecoder = IdentityAttributeDecoder(key: key.stringValue, value: .raw(identifier), decoder: decoder)
                try rootObject.initialize(from: identityAttributeDecoder)
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
        let identityAttributeDecoder = IdentityAttributeDecoder(key: codingKey.stringValue, value: .singleContainer(container), decoder: decoder)
        try object.initialize(from: identityAttributeDecoder)
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

// MARK: - Custom Decoder

private struct IdentityAttributeDecoder: Decoder {
    
    enum Value {
        case raw(Any?)
        case singleContainer(SingleValueDecodingContainer)
    }
    
    struct Container<Key: CodingKey> {
        let keyStringValue: String
        let value: Value
        let decoder: Decoder
        
        init(keyStringValue: String, value: Value, decoder: Decoder) {
            self.keyStringValue = keyStringValue
            self.value = value
            self.decoder = decoder
        }
    }
    
    private let key: String
    let value: Value
    let codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey : Any]
    
    init(key: String, value: Value, decoder: Decoder) {
        self.key = key
        self.value = value
        self.codingPath = decoder.codingPath
        self.userInfo = decoder.userInfo
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let rootContainer = Container<Key>(keyStringValue: key, value: value, decoder: self)
        return KeyedDecodingContainer(rootContainer)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("IdentityAttributeDecoder an just be used with keyed container")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError("IdentityAttributeDecoder an just be used with keyed container")
    }
}

extension IdentityAttributeDecoder.Container: KeyedDecodingContainerProtocol {
    var allKeys: [Key] { Key(stringValue: keyStringValue).map { [$0] } ?? [] }
    var codingPath: [CodingKey] { decoder.codingPath }
    
    func contains(_ key: Key) -> Bool {
        return key.stringValue == self.keyStringValue
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        switch value {
        case let .raw(raw):
            return raw == nil
        case let .singleContainer(container):
            return container.decodeNil()
        }
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        let context = DecodingError.Context(codingPath: codingPath + [key], debugDescription: "")
        switch value {
        case let .raw(raw):
            guard let _ = raw else {
                throw DecodingError.valueNotFound(T.self, context)
            }
            guard let casted = raw as? T else {
                throw DecodingError.typeMismatch(T.self, context)
            }
            return casted
            
        case let .singleContainer(container):
            return try container.decode(T.self)
        }
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
}

private struct Skip: Codable {}
extension UnkeyedDecodingContainer {
    mutating func skip() throws {
        _ = try decode(Skip.self)
    }
}
