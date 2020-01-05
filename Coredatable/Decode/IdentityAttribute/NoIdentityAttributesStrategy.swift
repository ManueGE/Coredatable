//
//  NoIdentityAttributesStrategy.swift
//  Coredatable
//
//  Created by Manu on 11/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal struct NoIdentityAttributesStrategy: IdentityAttributeStrategy {
    func existingObject<ManagedObject>(context: NSManagedObjectContext, decoder: Decoder) throws -> ManagedObject? where ManagedObject : CoreDataDecodable {
        return nil
    }
    
    func decodeArray<ManagedObject>(context: NSManagedObjectContext, decoder: Decoder) throws -> [ManagedObject] where ManagedObject : CoreDataDecodable {
        var container = try decoder.unkeyedContainer()
        var objects: [ManagedObject] = []
        while !container.isAtEnd {
            let object = ManagedObject(context: context)
            try object.initialize(from: container.superDecoder())
            objects.append(object)
        }
        return objects
    }
}
