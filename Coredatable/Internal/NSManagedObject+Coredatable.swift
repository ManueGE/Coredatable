//
//  NSManagedObject+Coredatable.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal extension NSManagedObject {
    static func entity(inManagedObjectContext context: NSManagedObjectContext) -> NSEntityDescription {
        guard let model = context.managedObjectModel else {
            fatalError("Could not find managed object model for the provided context.")
        }
        
        let className = String(reflecting: self)
        
        for entity in model.entities {
            if entity.managedObjectClassName == className {
                return entity
            }
        }
        
        fatalError("Could not locate the entity for \(className).")
    }

    func applyValues<Keys: AnyCoreDataCodingKey>(from container: KeyedDecodingContainer<Keys.CodingKey>) throws {
        try entity.properties.forEach { property in
            guard let codingKey = Keys(propertyName: property.name),
                container.contains(codingKey.standardCodingKey)
                else { return }

            if let attribute = property as? NSAttributeDescription {
                try set(attribute, from: container, with: codingKey)
            } else if let relationship =  property as? NSRelationshipDescription {
                 try set(relationship, from: container, with: codingKey)
            }
        }
    }
    
    private func validateValue(_ value: Any?, forKey codingKey: AnyCoreDataCodingKey) throws {
        var valuePointer: AutoreleasingUnsafeMutablePointer<AnyObject?>
        if let value = value {
            var anyObjectValue = value as AnyObject
            valuePointer = AutoreleasingUnsafeMutablePointer(&anyObjectValue)
        } else {
            var null: NSObject? = nil
            valuePointer = AutoreleasingUnsafeMutablePointer(&null)
        }
        
        try validateValue(valuePointer, forKey: codingKey.propertyName)
    }
    
    private func set<Keys: AnyCoreDataCodingKey>(_ attribute: NSAttributeDescription, from container: KeyedDecodingContainer<Keys.CodingKey>, with codingKey: Keys) throws {
        let value = container.decodeAny(forKey: codingKey.standardCodingKey)
        try validateValue(value, forKey: codingKey)
        setValue(value, forKey: codingKey.propertyName)
    }
    
    private func set<Keys: AnyCoreDataCodingKey>(_ relationship: NSRelationshipDescription, from container: KeyedDecodingContainer<Keys.CodingKey>, with codingKey: Keys) throws {
        guard let className = relationship.destinationEntity?.managedObjectClassName,
            let codableClass = NSClassFromString(className) as? AnyCoreDataDecodable.Type
            else {
                #warning("Throw error for relationship not being codable")
                return
        }
        
        let standardKey = codingKey.standardCodingKey
        let childDecoder = try container.superDecoder(forKey: standardKey)
        if relationship.isToMany {
            let array = try codableClass.decodeArray(from: childDecoder)
            let value = NSSet(array: array)
            try validateValue(value, forKey: codingKey)
            setValue(value, forKey: codingKey.propertyName)
        } else {
            let value = try codableClass.init(from: childDecoder)
            try validateValue(value, forKey: codingKey)
            setValue(value, forKey: codingKey.propertyName)
        }
    }
}

private extension Decodable {
    static func decodeArray(with decoder: Decoder) throws -> [Any] {
        #warning("Should be `Many` instead of Array to improve performance")
        return try [Self].init(from: decoder)
    }
}

private extension NSManagedObjectContext {
    
    var managedObjectModel: NSManagedObjectModel? {
        if let persistentStoreCoordinator = persistentStoreCoordinator {
            return persistentStoreCoordinator.managedObjectModel
        }
        
        if let parent = parent {
            return parent.managedObjectModel
        }
        
        return nil
    }
}

