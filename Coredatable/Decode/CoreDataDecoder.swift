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
        do {
            let container = try decoder.container(keyedBy: ManagedObject.CodingKeys.Standard.self)
            return try context.tryPerformAndWait {
                let object = try ManagedObject.identityAttribute.strategy.existingObject(context: context, container: container) ?? ManagedObject(context: context)
                try object.initialize(from: container)
                return object
            }
        } catch {
            return try decodeFromId(previousError: error)
        }
    }
    
    func decodeArray() throws -> [ManagedObject] {
        let container = try decoder.unkeyedContainer()
        return try context.tryPerformAndWait {
            return try ManagedObject.identityAttribute.strategy.decodeArray(context: context, container: container, decoder: decoder)
        }
    }
    
    private func decodeFromId(previousError: Error) throws -> ManagedObject {
        guard let strategy = ManagedObject.identityAttribute.strategy as? SingleIdentityAttributeStrategy else {
            throw previousError
        }
        do {
            let container = try decoder.singleValueContainer()
            return try strategy.decodeObject(context: context, container: container, decoder: decoder)
        } catch {
            throw previousError
        }
    }
}

#warning("Check groot details: contexts run on their own blocks, remove objects if fails...")
