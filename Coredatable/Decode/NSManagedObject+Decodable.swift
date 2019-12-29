//
//  NSManagedObject+Coredatable.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal extension CoreDataDecodable {
    func applyValues<Keys: AnyCoreDataCodingKey>(from container: KeyedDecodingContainer<Keys.Standard>, policy: (Keys) -> Bool) throws {
        try entity.properties.forEach { property in
            guard let codingKey = Keys(propertyName: property.name),
                policy(codingKey),
                let nestedContainer = container.nestedContainer(forCoreDataKey: codingKey),
                nestedContainer.contains(codingKey.standarized)
                else { return }

            if let attribute = property as? NSAttributeDescription {
                try set(attribute, from: nestedContainer, with: codingKey)
            } else if let relationship =  property as? NSRelationshipDescription {
                 try set(relationship, from: nestedContainer, with: codingKey)
            }
        }
    }
    
    func setValue<Keys: AnyCoreDataCodingKey>(_ value: Any?, forKey codingKey: Keys) throws {
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
    
    private func set<Keys: AnyCoreDataCodingKey>(_ attribute: NSAttributeDescription, from container: KeyedDecodingContainer<Keys.Standard>, with codingKey: Keys) throws {
        let value = container.decodeAny(forKey: codingKey.standarized)
        try setValue(value, forKey: codingKey)
    }
    
    private func set<Keys: AnyCoreDataCodingKey>(_ relationship: NSRelationshipDescription, from container: KeyedDecodingContainer<Keys.Standard>, with codingKey: Keys) throws {
        let className = relationship.destinationEntity?.managedObjectClassName ?? ""
        let theClass: AnyClass? = NSClassFromString(className)
        let standardKey = codingKey.standarized
        let childDecoder = try container.superDecoder(forKey: standardKey)
        
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
