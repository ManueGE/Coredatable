//
//  NSManagedObject+Coredatable.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal extension CoreDataDecodable {
    func applyValues(from container: CoreDataKeyedDecodingContainer<CodingKeys>, policy: (CodingKeys) -> Bool) throws {
        try entity.properties.forEach { property in
            guard let codingKey = CodingKeys(propertyName: property.name),
                policy(codingKey),
                container.contains(codingKey)
                else { return }

            if let attribute = property as? NSAttributeDescription {
                try set(attribute, from: container, with: codingKey)
            } else if let relationship =  property as? NSRelationshipDescription {
                 try set(relationship, from: container, with: codingKey)
            }
        }
    }
    
    func setValue(_ value: Any?, forKey codingKey: CodingKeys) throws {
        try validateValue(value, forKey: codingKey)
        setValue(value, forKey: codingKey.propertyName)
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
    
    private func set(_ attribute: NSAttributeDescription, from container: CoreDataKeyedDecodingContainer<CodingKeys>, with codingKey: CodingKeys) throws {
        let value = container.decodeAny(forKey: codingKey)
        try setValue(value, forKey: codingKey)
    }
    
    private func set(_ relationship: NSRelationshipDescription, from container: CoreDataKeyedDecodingContainer<CodingKeys>, with codingKey: CodingKeys) throws {
        let className = relationship.destinationEntity?.managedObjectClassName ?? ""
        let theClass: AnyClass? = NSClassFromString(className)
        let childDecoder = try container.superDecoder(forKey: codingKey)
        
        if relationship.isToMany {
            let array: [Any]
            // We need the `if` because the two `decodeArray` methods are different because they belong to different protocol extensions
            if let codableClass = theClass as? AnyCoreDataDecodable.Type {
                array = try codableClass.decodeArray(from: childDecoder)
            } else if let codableClass = theClass as? Decodable.Type {
                array = try codableClass.decodeArray(from: childDecoder)
            } else {
                #warning("Throw error for relationship not being codable")
                return
            }
            let value = NSSet(array: array)
            try validateValue(value, forKey: codingKey)
            setValue(value, forKey: codingKey.propertyName)
        } else {
            guard let codableClass = theClass as? Decodable.Type else {
                #warning("Throw error for relationship not being codable")
                return
            }
            #warning("TODO: Write a test with regular codable NSManagedObject")
            let value = try codableClass.init(from: childDecoder)
            try validateValue(value, forKey: codingKey)
            setValue(value, forKey: codingKey.propertyName)
        }
    }
}
