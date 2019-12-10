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
    
    func validateValue(_ value: Any?, forKey codingKey: AnyCoreDataCodingKey) throws {
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

