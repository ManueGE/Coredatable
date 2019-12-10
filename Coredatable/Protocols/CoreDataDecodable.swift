//
//  CoreDataDecodable.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

public protocol CoreDataDecodable: NSManagedObject, AnyCoreDataDecodable {
    associatedtype CodingKeys: AnyCoreDataCodingKey
    static var identityAttribute: IdentityAttribute { get }
}

public extension CoreDataDecodable {
    init(from decoder: Decoder) throws {
        try self.init(from: decoder, codingKeys: CodingKeys.self)
    }
    
    #warning("maybe not needed. Check after all the work is done, including custom decode init")
    init<Keys: AnyCoreDataCodingKey>(from decoder: Decoder, codingKeys: Keys.Type) throws {
        let coreDataDecoder = try CoreDataDecoder<Self, Keys>(decoder: decoder)
        self.init(anotherManagedObject: try coreDataDecoder.decode())
    }
    
    static var identityAttribute: IdentityAttribute { .no }
    
    static func decodeArray(from decoder: Decoder) throws -> [Any] {
        return try CoreDataMultiDecoder<Self>(decoder: decoder).decode()
    }
}

/// A type erased protocol that is used internally to make the whole framework work.
/// You shouldn't conform this protocol manually ever, use `CoreDataDecodable` instead
public protocol AnyCoreDataDecodable: Decodable {
    static func decodeArray(from decoder: Decoder) throws -> [Any]
}


// MARK: - Error

public enum CoreDataCodableError: Error {
    case missingContext(decoder: Decoder)
    case missingIdentityAttribute(class: AnyClass, identityAttributes: [String], receivedKeys: [String])
}
