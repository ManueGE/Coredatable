//
//  NoIdentityAttributesStrategy.swift
//  Coredatable
//
//  Created by Manu on 11/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal struct NoIdentityAttributesStrategy: IdentityAttributeStrategy {
    func existingObject<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: CoreDataKeyedDecodingContainer<ManagedObject>) throws -> ManagedObject? {
        return nil
    }
    
    func decodeArray<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: UnkeyedDecodingContainer, decoder: Decoder) throws -> [ManagedObject] {
        var container = container
        var objects: [ManagedObject] = []
        while !container.isAtEnd {
            let objectContainer = try container.nestedContainer(keyedBy: ManagedObject.CodingKeys.Standard.self)
            let object = ManagedObject(context: context)
            try object.initialize(from: objectContainer)
            objects.append(object)
        }
        return objects
    }
}
