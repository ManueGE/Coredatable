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
    
    func existingObject<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: KeyedDecodingContainer<ManagedObject.CodingKeys.CodingKey>) throws -> ManagedObject? {
        let identifier = try findIdentifier(for: ManagedObject.self, in: container)
        return try existingObjects(context: context, ids: [identifier]).first
    }
    
    func decodeArray<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: UnkeyedDecodingContainer) throws -> [ManagedObject] {
        var identifiers: [AnyHashable] = []
        var objectContainersById: [AnyHashable: KeyedDecodingContainer<ManagedObject.CodingKeys.CodingKey>] = [:]
        
        // find the id for any object in the container
        var idsContainer = container
        while !idsContainer.isAtEnd {
            let objectContainer = try idsContainer.nestedContainer(keyedBy: ManagedObject.CodingKeys.CodingKey.self)
            let identifier = try findIdentifier(for: ManagedObject.self, in: objectContainer) as AnyHashable
            identifiers.append(identifier)
            objectContainersById[identifier] = objectContainer
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
            guard let objectContainer = objectContainersById[identifier] else { return nil }
            let rootObject: ManagedObject
            if let existingObject = existingObjectsById[identifier] {
                rootObject = existingObject
            } else {
                rootObject = ManagedObject(context: context)
                rootObject.setValue(identifier, forKey: propertyName)
            }
            try rootObject.applyValues(from: objectContainer)
            return rootObject
        }
    }
    
    // MARK: - Helpers
    private func findIdentifier<ManagedObject: CoreDataDecodable>(for _: ManagedObject.Type, in container: KeyedDecodingContainer<ManagedObject.CodingKeys.CodingKey>) throws -> AnyHashable {
        guard let codingKey = ManagedObject.CodingKeys(propertyName: propertyName),
            let value = container.decodeAny(forKey: codingKey.standardCodingKey) as? AnyHashable
            else {
                let receivedKeys = container.allKeys.map { $0.key.stringValue }
                throw CoreDataCodableError.missingOrInvalidIdentityAttribute(class: ManagedObject.self, identityAttributes: [propertyName], receivedKeys: receivedKeys)
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
}
