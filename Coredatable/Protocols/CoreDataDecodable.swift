//
//  CoreDataDecodable.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

public protocol CoreDataDecodable: NSManagedObject, Decodable {
    associatedtype CodingKeys: AnyCoreDataCodingKey
    static var identityAttribute: IdentityAttribute { get }
}

public extension CoreDataDecodable {
    init(from decoder: Decoder) throws {
        try self.init(from: decoder, codingKeys: CodingKeys.self)
    }
    
    init<Keys: AnyCoreDataCodingKey>(from decoder: Decoder, codingKeys: Keys.Type) throws {
        let coreDataDecoder = try CoreDataDecoder<Self, Keys>(decoder: decoder)
        self.init(anotherManagedObject: try coreDataDecoder.decode())
    }
    
    static var identityAttribute: IdentityAttribute { .no }
}

// MARK: - Error

public enum CoreDataCodableError: Error {
    case missingContext(decoder: Decoder)
    case missingIdentityAttribute(class: AnyClass, identityAttributes: [String], receivedKeys: [String])
}
