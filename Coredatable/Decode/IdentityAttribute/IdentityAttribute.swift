//
//  IdentityAttribute.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

public struct IdentityAttribute {
    private let propertyNames: [String]
    fileprivate init(_ propertyNames: Set<String>) {
        self.propertyNames = Array(propertyNames)
    }
    public static var no: IdentityAttribute { IdentityAttribute([]) }
    
    internal var strategy: IdentityAttributeStrategy {
        if propertyNames.count == 0 {
            return NoIdentityAttributesStrategy()
        } else if propertyNames.count == 1 {
            return SingleIdentityAttributeStrategy(propertyName: propertyNames[0])
        } else {
            return CompositeIdentityAttributeStrategy(propertyNames: propertyNames)
        }
    }
}

extension IdentityAttribute: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: Self.StringLiteralType) {
        self = IdentityAttribute(Set([value]))
    }
}
/*
extension IdentityAttribute: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = String
    public init(arrayLiteral elements: String...) {
        self = IdentityAttribute(Set(elements))
    }
}*/

internal protocol IdentityAttributeStrategy {
    func existingObject<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: KeyedDecodingContainer<ManagedObject.CodingKeys.Standard>) throws -> ManagedObject?
    func decodeArray<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, container: UnkeyedDecodingContainer) throws -> [ManagedObject]
}
