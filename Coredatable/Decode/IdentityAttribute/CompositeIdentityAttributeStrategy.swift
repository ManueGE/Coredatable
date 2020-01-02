//
//  CompositeIdentityAttributeStrategy.swift
//  Coredatable
//
//  Created by Manu on 11/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal struct CompositeIdentityAttributeStrategy: IdentityAttributeStrategy {
    let propertyNames: [String]
    func existingObject<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: CoreDataKeyedDecodingContainer<ManagedObject>) throws -> ManagedObject? {
        
        let request = NSFetchRequest<ManagedObject>(entityName: ManagedObject.entity(inManagedObjectContext: context).name!)
        request.predicate = try predicate(for: ManagedObject.self, in: container, context: context)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    func decodeArray<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: UnkeyedDecodingContainer, decoder: Decoder) throws -> [ManagedObject] {
        var container = container
        var objects: [ManagedObject] = []
        while !container.isAtEnd {
            let objectContainer = try container.nestedContainer(keyedBy: ManagedObject.CodingKeys.Standard.self)
            let object = (try? existingObject(context: context, standardContainer: objectContainer)) ?? ManagedObject(context: context)
            try object.initialize(from: objectContainer)
            objects.append(object)
        }
        return objects
    }
    
    // MARK: - Helpers
    private func predicate<ManagedObject: CoreDataDecodable>(for _: ManagedObject.Type, in container: CoreDataKeyedDecodingContainer<ManagedObject>, context: NSManagedObjectContext) throws -> NSPredicate {
        
        let predicates = try ManagedObject.identityAttribute.propertyNames.map { (propertyName) -> NSPredicate in
            guard let codingKey = ManagedObject.CodingKeys(propertyName: propertyName),
                let identityAttribute = ManagedObject.entity(inManagedObjectContext: context).propertiesByName[propertyName] as? NSAttributeDescription,
                let identifier = container.decode(identityAttribute, forKey: codingKey) as? AnyHashable
                else {
                    let receivedKeys = container.allKeys.map { $0.stringValue }
                    throw CoreDataDecodingError.missingOrInvalidIdentityAttribute(class: ManagedObject.self, identityAttributes: [propertyName], receivedKeys: receivedKeys)
            }
            
            return NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: propertyName),
                                         rightExpression: NSExpression(forConstantValue: identifier),
                                         modifier: .direct,
                                         type: .equalTo,
                                         options: [])
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
