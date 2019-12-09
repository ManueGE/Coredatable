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

