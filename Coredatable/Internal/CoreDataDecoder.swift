//
//  CoreDataDecoder.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal struct CoreDataDecoder<ManagedObject: CoreDataDecodable, Keys: AnyCoreDataCodingKey> {
    private let decoder: Decoder
    private let context: NSManagedObjectContext
    private let container: KeyedDecodingContainer<Keys.CodingKey>
    
    init(decoder: Decoder) throws {
        guard let context = decoder.managedObjectContext else {
            throw CoreDataCodableError.missingContext(decoder: decoder)
        }
        self.decoder = decoder
        self.context = context
        self.container = try decoder.container(keyedBy: Keys.CodingKey.self)
    }
    
    func decode() throws -> ManagedObject {
        let object = try existingObject() ?? ManagedObject.init(context: context)
        try object.applyValues(from: container)
        return object
    }
}

private extension CoreDataDecoder {
    func existingObject() throws -> ManagedObject? {
        switch ManagedObject.identityAttribute.kind {
        case .no:
            return nil
                        
        case let .single(propertyName):
            guard let codingKey = Keys(propertyName: propertyName),
                let value = container.decodeAny(forKey: codingKey.standardCodingKey) else {
                    let receivedKeys = container.allKeys.map { $0.key.stringValue }
                    throw CoreDataCodableError.missingIdentityAttribute(class: ManagedObject.self, identityAttributes: [propertyName], receivedKeys: receivedKeys)
            }
            
            let request = NSFetchRequest<ManagedObject>(entityName: ManagedObject.entity(inManagedObjectContext: context).name!)
            request.predicate = NSPredicate(format: "\(propertyName) IN %@", [value])
            return try context.fetch(request).first
            
        case let .composite(propertyNames):
            #warning("TODO multiple identity attribute")
            return nil
        }
    }
}

#warning("Somehow we need to insert elements by its id too")
#warning("Check groot details: contexts run on their own blocks, remove objects if fails...")
#warning("Include buitl in keypath coding keys")
