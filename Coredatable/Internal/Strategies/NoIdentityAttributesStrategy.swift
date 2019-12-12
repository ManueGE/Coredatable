//
//  NoIdentityAttributesStrategy.swift
//  Coredatable
//
//  Created by Manu on 11/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal struct NoIdentityAttributesStrategy: IdentityAttributeStrategy {
    func existingObject<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: KeyedDecodingContainer<ManagedObject.CodingKeys.Standard>) throws -> ManagedObject? {
        return nil
    }
    
    func decodeArray<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: UnkeyedDecodingContainer) throws -> [ManagedObject] {
        var container = container
        return try (0 ..< (container.count ?? 0)).map { _ in
            let objectContainer = try container.nestedContainer(keyedBy: ManagedObject.CodingKeys.Standard.self)
            let object = ManagedObject(context: context)
            try object.applyValues(from: objectContainer)
            return object
        }
    }
}
