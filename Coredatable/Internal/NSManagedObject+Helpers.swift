//
//  NSManagedObject+Helpers.swift
//  Coredatable
//
//  Created by Manu on 12/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

extension NSManagedObject {
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

extension NSManagedObjectContext {
    
    fileprivate var managedObjectModel: NSManagedObjectModel? {
        if let persistentStoreCoordinator = persistentStoreCoordinator {
            return persistentStoreCoordinator.managedObjectModel
        }
        if let parent = parent {
            return parent.managedObjectModel
        }
        return nil
    }
    
    internal func tryPerformAndWait<T>(_ block: () throws -> T) throws -> T {
        var result: T? = nil
        var exception: Error? = nil
        performAndWait {
            do {
                result = try block()
            } catch {
                exception = error
            }
        }
        
        try exception.map { throw $0 }
        return result!
    }
}
