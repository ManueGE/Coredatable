//
//  CoreDataDecoder.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal struct CoreDataDecoder<ManagedObject: CoreDataDecodable, Keys: AnyCoreDataCodingKey> {
    private let decoder: Decoder
    private let context: NSManagedObjectContext
    private let container: KeyedDecodingContainer<Keys.CodingKey>
    
    init(decoder: Decoder) throws {
        guard let context = decoder.managedObjectContext else {
            throw CoreDataCodableError.missingContext(decoder: decoder)
        }
        self.decoder = decoder
        self.context = context
        self.container = try decoder.container(keyedBy: Keys.CodingKey.self)
    }
    
    func decode() throws -> ManagedObject {
        let object = try existingObject() ?? ManagedObject.init(context: context)
        try applyValues(to: object)
        return object
    }
}

private extension CoreDataDecoder {
    #warning("This picks elements one by one, need a method to pick all the elements at once if array")
    func existingObject() throws -> ManagedObject? {
        switch ManagedObject.identityAttribute.kind {
        case .no:
            return nil
                        
        case let .single(propertyName):
            guard let codingKey = Keys(propertyName: propertyName),
                let value = container.decodeAny(forKey: codingKey.standardCodingKey) else {
                    let receivedKeys = container.allKeys.map { $0.key.stringValue }
                    throw CoreDataCodableError.missingIdentityAttribute(class: ManagedObject.self, identityAttributes: [propertyName], receivedKeys: receivedKeys)
            }
            
            let request = NSFetchRequest<ManagedObject>(entityName: ManagedObject.entity(inManagedObjectContext: context).name!)
            request.predicate = NSPredicate(format: "\(propertyName) == \(value)")
            return try context.fetch(request).first
            
        case let .composite(propertyNames):
            #warning("TODO multiple identity attribute")
            return nil
        }
    }
    
    func applyValues(to object: ManagedObject) throws {
        try object.entity.properties.forEach { property in
            guard let codingKey = Keys(propertyName: property.name),
                container.contains(codingKey.standardCodingKey)
                else { return }

            if let attribute = property as? NSAttributeDescription {
                try set(attribute, into: object, with: codingKey)
            } else if let relationship =  property as? NSRelationshipDescription {
                try set(relationship, into: object, with: codingKey)
            }
        }
    }
    
    func set(_ attribute: NSAttributeDescription, into object: ManagedObject, with codingKey: Keys) throws {
        let value = container.decodeAny(forKey: codingKey.standardCodingKey)
        try object.validateValue(value, forKey: codingKey)
        object.setValue(value, forKey: codingKey.propertyName)
    }
    
    func set(_ relationship: NSRelationshipDescription, into object: ManagedObject, with codingKey: Keys) throws {
        guard let className = relationship.destinationEntity?.managedObjectClassName,
            let codableClass = NSClassFromString(className) as? Decodable.Type
            else {
                #warning("Throw error for relationship not being codable")
                return
        }
        
        let standardKey = codingKey.standardCodingKey
        let childDecoder = try container.superDecoder(forKey: standardKey)
        if relationship.isToMany {
            let array = try codableClass.decodeArray(with: childDecoder)
            let value = NSSet(array: array)
            try object.validateValue(value, forKey: codingKey)
            object.setValue(value, forKey: codingKey.propertyName)
        } else {
            let value = try codableClass.init(from: childDecoder)
            try object.validateValue(value, forKey: codingKey)
            object.setValue(value, forKey: codingKey.propertyName)
        }
    }
}

private extension Decodable {
    static func decodeArray(with decoder: Decoder) throws -> [Any] {
        #warning("Should be `Many` instead of Array to improve performance")
        return try [Self].init(from: decoder)
    }
}

#warning("Somehow we need to insert elements by its id too")
