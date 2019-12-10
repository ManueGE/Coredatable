//
//  CoreDataEncodable.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

public protocol CoreDataEncodable: NSManagedObject, Encodable {
    associatedtype CodingKeys: AnyCoreDataCodingKey
}

extension CoreDataEncodable {
    public func encode(to encoder: Encoder) throws {
        try encode(to: encoder, codingKeys: CodingKeys.self)
    }
    
    public func encode<Keys: AnyCoreDataCodingKey>(to encoder: Encoder, codingKeys: Keys.Type) throws {
        var container = encoder.container(keyedBy: Keys.CodingKey.self)
        try entity.attributesByName.forEach { item in
            
            guard let key = Keys(propertyName: item.key),
                let value = self.value(forKey: item.key)
                else { return }
            
            try container.encodeAny(value, forKey: key.standardCodingKey)
        }
    }
}