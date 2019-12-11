//
//  CoreDataDecoder.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal struct CoreDataDecoder<ManagedObject: CoreDataDecodable> {
    private let decoder: Decoder
    private let context: NSManagedObjectContext
    
    init(decoder: Decoder) throws {
        guard let context = decoder.managedObjectContext else {
            throw CoreDataCodableError.missingContext(decoder: decoder)
        }
        self.decoder = decoder
        self.context = context
    }
    
    func decode() throws -> ManagedObject {
        let container = try decoder.container(keyedBy: ManagedObject.CodingKeys.CodingKey.self)
        return try context.tryPerformAndWait {
            let object = try ManagedObject.identityAttribute.strategy.existingObject(context: context, container: container) ?? ManagedObject.init(context: context)
            try object.applyValues(from: container)
            return object
        }
    }
    
    func decodeArray() throws -> [ManagedObject] {
        let container = try decoder.unkeyedContainer()
        return try context.tryPerformAndWait {
            return try ManagedObject.identityAttribute.strategy.decodeArray(context: context, container: container)
        }
    }
}

#warning("Somehow we need to insert elements by its id too")
#warning("Check groot details: contexts run on their own blocks, remove objects if fails...")
#warning("Include buitl in keypath coding keys")
