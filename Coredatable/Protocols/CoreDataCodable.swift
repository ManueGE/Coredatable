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
    associatedtype CodingKeys: CoreDataCodingKey
}

public extension CoreDataDecodable {
    init<Keys: CoreDataCodingKey>(from decoder: Decoder, codingKeys: Keys.Type) throws {
        let context = try DecodingContext(decoder: decoder, codingKeys: Keys.self)
        try self.init(decodingContext: context)
    }
    
    init(from decoder: Decoder) throws {
        try self.init(from: decoder, codingKeys: CodingKeys.self)
    }
}

public protocol UsingDefaultKeys: NSManagedObject {}

public extension UsingDefaultKeys {
    typealias CodingKeys = CoreDataDefaultCodingKeys
}

public enum CoreDataCodableError: Error {
    case missingContext
}

// MARK: - Encodable

public protocol CoreDataEncodable: NSManagedObject, Decodable { }
