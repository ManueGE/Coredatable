//
//  CoreDataDecoder.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal struct CoreDataDecoder<ManagedObject: CoreDataDecodable, Keys: AnyCoreDataCodingKey> {
    private let context: NSManagedObjectContext
    private let container: KeyedDecodingContainer<Keys.CodingKey>
    
    init(decoder: Decoder) throws {
        guard let context = decoder.managedObjectContext else {
            throw CoreDataCodableError.missingContext(decoder: decoder)
        }
        
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
    func existingObject() throws -> ManagedObject? {
        switch ManagedObject.identityAttribute {
        case .no:
            return nil
            
        case let .composed(propertyNames) where propertyNames.count == 0:
            return nil
            
        case let .composed(propertyNames) where propertyNames.count == 1:
            let propertyName = propertyNames.first!
            guard let codingKey = Keys(propertyName: propertyName),
                let value = container.decodeAny(forKey: codingKey.standardCodingKey) else {
                    let receivedKeys = container.allKeys.map { $0.key.stringValue }
                    throw CoreDataCodableError.missingIdentityAttribute(class: ManagedObject.self, identityAttributes: [propertyName], receivedKeys: receivedKeys)
            }
            
            let request = NSFetchRequest<ManagedObject>(entityName: ManagedObject.entity(inManagedObjectContext: context).name!)
            request.predicate = NSPredicate(format: "\(propertyName) == \(value)")
            return try context.fetch(request).first
            
        case let .composed(propertyNames):
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
        /*
        #warning("TODO rest of the cases")
        if relationship.isToMany {
            let data = try container.nestedUnkeyedContainer(forKey: standardKey)
            #warning("Serialize contents")
            let set = NSMutableSet()
            array.forEach { set.add($0) }
            object.setValue(set.copy(), forKey: codingKey.propertyName)
        } else {
            let data = try container.nestedContainer(keyedBy: CoreDataDefaultCodingKeys.CodingKey.self, forKey: standardKey)
        }*/
    }
}
