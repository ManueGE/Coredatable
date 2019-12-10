//
//  CoreDataMultiDecoder.swift
//  Coredatable
//
//  Created by Manu on 10/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal struct CoreDataMultiDecoder<ManagedObject: CoreDataDecodable> {
    private let decoder: Decoder
    private let context: NSManagedObjectContext
    private let container: UnkeyedDecodingContainer
    
    init(decoder: Decoder) throws {
        guard let context = decoder.managedObjectContext else {
            throw CoreDataCodableError.missingContext(decoder: decoder)
        }
        self.decoder = decoder
        self.context = context
        self.container = try decoder.unkeyedContainer()
    }
    
    func decode() throws -> [ManagedObject] {
        switch ManagedObject.identityAttribute.kind {
        case .no:
            return try decodeWithoutMerge()
            
        case let .single(propertyName):
            return try decodeWithSingleIdentityAttribute(propertyName)
            
        case let .composite(propertyNames):
            #warning("TODO multiple identity attribute")
            return try decodeWithCompositeIdentityAttributes(propertyNames)
        }
    }
}

private extension CoreDataMultiDecoder {
    #warning("Maybe too much duplication with simple decoder. Check if can reuse things")
    private func decodeWithoutMerge() throws -> [ManagedObject] {
        var container = self.container
        return try (0 ..< (container.count ?? 0)).map { _ in
            let objectContainer = try container.nestedContainer(keyedBy: ManagedObject.CodingKeys.CodingKey.self)
            let object = ManagedObject(context: context)
            try object.applyValues(from: objectContainer)
            return object
        }
    }
    
    private func decodeWithSingleIdentityAttribute(_ propertyName: String) throws -> [ManagedObject] {
        guard let identityAttributeCodingKey = ManagedObject.CodingKeys(propertyName: propertyName) else {
            return []
        }
        
        // find ids
        var idsContainer = container
        var identifiers: [AnyHashable] = []
        var identityAttributes: [AnyHashable] = []
        var objectContainersById: [AnyHashable: KeyedDecodingContainer<ManagedObject.CodingKeys.CodingKey>] = [:]
        while !idsContainer.isAtEnd {
            let objectContainer = try idsContainer.nestedContainer(keyedBy: ManagedObject.CodingKeys.CodingKey.self)
            if let identifier = objectContainer.decodeAny(forKey: identityAttributeCodingKey.standardCodingKey) as? AnyHashable {
                identifiers.append(identifier)
                identityAttributes.append(identifier)
                objectContainersById[identifier] = objectContainer
            } else {
                #warning("Trhow error here?? if we dont' have identifier, maybe the seralization should fail?")
            }
        }
        
        // find existing objects
        let request = NSFetchRequest<ManagedObject>(entityName: ManagedObject.entity(inManagedObjectContext: context).name!)
        request.predicate = NSPredicate(format: "\(propertyName) IN %@", identityAttributes)
        let existingObjects = try context.fetch(request)
        let existingObjectsById: [AnyHashable: ManagedObject] = existingObjects.reduce(into: [:]) { (result, object) in
            if let identifier = object.value(forKey: identityAttributeCodingKey.propertyName) as? AnyHashable {
                result[identifier] = object
            }
        }
        
        // Create objects
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
    
    private func decodeWithCompositeIdentityAttributes(_ propertyNames: [String]) throws -> [ManagedObject] {
        return []
    }
}
