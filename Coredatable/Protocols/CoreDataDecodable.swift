//
//  CoreDataDecodable.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

public protocol CoreDataDecodable: NSManagedObject, Decodable {
    associatedtype CodingKeys: GenericCoreDataCodingKey
    static var identityAttribute: IdentityAttribute { get }
}

public extension CoreDataDecodable {
    init(from decoder: Decoder) throws {
        try self.init(from: decoder, codingKeys: CodingKeys.self)
    }
    
    init<Keys: GenericCoreDataCodingKey>(from decoder: Decoder, codingKeys: Keys.Type) throws {
        guard let context = decoder.managedObjectContext else {
            throw CoreDataCodableError.missingContext(decoder: decoder)
        }
        
        let container = try decoder.container(keyedBy: CoreDataCodingKeyWrapper<Keys>.self)
        let object = try Self.existingObject(context: context, container: container) ?? Self.init(context: context)
        try object.applyValuest(container: container)
        self.init(anotherManagedObject: object)
    }
    
    static var identityAttribute: IdentityAttribute { .no }
    
    private static func existingObject<Keys: GenericCoreDataCodingKey>(context: NSManagedObjectContext, container: KeyedDecodingContainer<CoreDataCodingKeyWrapper<Keys>>) throws -> Self? {
        switch identityAttribute {
        case .no:
            return nil
            
        case let .composed(propertyNames) where propertyNames.count == 0:
            return nil
            
        case let .composed(propertyNames) where propertyNames.count == 1:
            let propertyName = propertyNames.first!
            guard let codingKey = Keys(propertyName: propertyName),
                let value = container.decodeAny(forKey: codingKey.standardCodingKey) else {
                    let receivedKeys = container.allKeys.map { $0.key.stringValue }
                    throw CoreDataCodableError.missingIdentityAttribute(class: Self.self, identityAttributes: [propertyName], receivedKeys: receivedKeys)
            }
            
            let request = NSFetchRequest<Self>(entityName: Self.entity(inManagedObjectContext: context).name!)
            request.predicate = NSPredicate(format: "\(propertyName) == \(value)")
            return try context.fetch(request).first
            
        case let .composed(propertyNames):
            return nil
        }
    }
}

// MARK: - Error

public enum CoreDataCodableError: Error {
    case missingContext(decoder: Decoder)
    case missingIdentityAttribute(class: AnyClass, identityAttributes: [String], receivedKeys: [String])
}

// MARK: - Identity Attribute

public enum IdentityAttribute {
    case no
    case composed(Set<String>)
    static func single(_ string: String) -> IdentityAttribute {
        composed([string])
    }
}

extension IdentityAttribute: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: Self.StringLiteralType) {
        self = .single(value)
    }
}

extension IdentityAttribute: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = String
    public init(arrayLiteral elements: String...) {
        if elements.count == 0 {
            self = .no
        } else {
            self = .composed(Set(elements))
        }
    }
}
