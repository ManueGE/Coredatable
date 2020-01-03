//
//  Encodable+Extension.swift
//  Coredatable
//
//  Created by Manuel García-Estañ on 12/07/2019.
//  Copyright © 2019 Manuege. All rights reserved.
//

import Foundation

// MARK: - Keyed Container

internal extension KeyedEncodingContainer {
    mutating func encode(_ value: Any?, attribute: NSAttributeDescription, forKey key: Key) throws {
        guard let value = value else {
            try encodeNil(forKey: key)
            return
        }
        
        switch (attribute.attributeType, value) {
        case (_, _ as NSNull):
            try encodeNil(forKey: key)
        case (.undefinedAttributeType, _):
            return
        case (.integer16AttributeType, let x as Int16):
            try encode(x, forKey: key)
        case (.integer32AttributeType, let x as Int32):
            try encode(x, forKey: key)
        case (.integer64AttributeType, let x as Int64):
            try encode(x, forKey: key)
        case (.decimalAttributeType, let x as Decimal):
            try encode(x, forKey: key)
        case (.doubleAttributeType, let x as Double):
            try encode(x, forKey: key)
        case (.floatAttributeType, let x as Float):
            try encode(x, forKey: key)
        case (.stringAttributeType, let x as String):
            try encode(x, forKey: key)
        case (.booleanAttributeType, let x as Bool):
            try encode(x, forKey: key)
        case (.dateAttributeType, let x as Date):
            try encode(x, forKey: key)
        case (.binaryDataAttributeType, let x as Data):
            try encode(x, forKey: key)
        case (.UUIDAttributeType, let x as UUID):
            try encode(x, forKey: key)
        case (.URIAttributeType, let x as URL):
            try encode(x, forKey: key)
        case (.transformableAttributeType, let x as Encodable):
            let childEncoder = superEncoder(forKey: key)
            try x.encode(to: childEncoder)
        case (.objectIDAttributeType, _):
            return
        default:
            return
        }
	}
}

internal extension KeyedEncodingContainer where Key: CoreDataStandardCodingKey {
    mutating func nestedContainer(forCoreDataKey key: Key.CoreDataKey) -> Self? {
        var components = key.keyPathComponents
        _ = components.removeLast()
        return components.reduce(self) { (current, key) -> KeyedEncodingContainer<K> in
            var current = current
            return current.nestedContainer(keyedBy: K.self, forKey: K(key))
        }
    }
}
