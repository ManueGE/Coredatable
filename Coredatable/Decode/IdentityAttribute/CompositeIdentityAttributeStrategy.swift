//
//  CompositeIdentityAttributeStrategy.swift
//  Coredatable
//
//  Created by Manu on 11/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

#warning("TODO multiple identity attribute")
internal struct CompositeIdentityAttributeStrategy: IdentityAttributeStrategy {
    let propertyNames: [String]
    func existingObject<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: KeyedDecodingContainer<ManagedObject.CodingKeys.Standard>) throws -> ManagedObject? {
        return nil
    }
    
    func decodeArray<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: UnkeyedDecodingContainer, decoder: Decoder) throws -> [ManagedObject] {
        return []
    }
}
