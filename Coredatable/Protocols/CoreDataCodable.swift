//
//  CoreDataCodable.swift
//  Coredatable
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

// MARK: - Codable
public typealias CoreDataCodable = CoreDataDecodable & CoreDataEncodable


// MARK: - Decodable

public protocol CoreDataDecodable: NSManagedObject, Decodable {
    associatedtype CodingKeys: GenericCoreDataCodingKey
}

public extension CoreDataDecodable {
    init(from decoder: Decoder) throws {
        try self.init(from: decoder, codingKeys: CodingKeys.self)
    }
    
    init<Keys: GenericCoreDataCodingKey>(from decoder: Decoder, codingKeys: Keys.Type) throws {
        let context = try DecodingContext(decoder: decoder, codingKeys: Keys.self)
        try self.init(decodingContext: context)
    }
}

public enum CoreDataCodableError: Error {
    case missingContext
}

// MARK: - Encodable

public protocol CoreDataEncodable: NSManagedObject, Encodable {
    associatedtype CodingKeys: GenericCoreDataCodingKey
}

extension CoreDataEncodable {
    public func encode(to encoder: Encoder) throws {
        try encode(to: encoder, codingKeys: CodingKeys.self)
    }
    
    public func encode<Keys: GenericCoreDataCodingKey>(to encoder: Encoder, codingKeys: Keys.Type) throws {
        var container = encoder.container(keyedBy: CoreDataCodingKeyWrapper<Keys>.self)
        try entity.attributesByName.forEach { item in
            
            guard let key = Keys(propertyName: item.key),
                let value = self.value(forKey: item.key)
                else { return }
            
            try container.encodeAny(value, forKey: key.standardCodingKey)
        }
    }
}
