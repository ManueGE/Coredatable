//
//  Decoder+Extension.swift
//  Coredatable
//
//  Created by Manuel García-Estañ on 12/07/2019.
//  Copyright © 2019 Manuege. All rights reserved.
//

import CoreData


// MARK: - Keyed Container
internal extension KeyedDecodingContainer {
	
    func decode(_ attribute: NSAttributeDescription, forKey key: Key) -> Any? {
        switch attribute.attributeType {
        case .undefinedAttributeType:
            return nil
        case .integer16AttributeType:
            return try? decode(Int16.self, forKey: key)
        case .integer32AttributeType:
            return try? decode(Int32.self, forKey: key)
        case .integer64AttributeType:
            return try? decode(Int64.self, forKey: key)
        case .decimalAttributeType:
            return try? decode(Decimal.self, forKey: key)
        case .doubleAttributeType:
            return try? decode(Double.self, forKey: key)
        case .floatAttributeType:
            return try? decode(Float.self, forKey: key)
        case .stringAttributeType:
            return try? decode(String.self, forKey: key)
        case .booleanAttributeType:
            return try? decode(Bool.self, forKey: key)
        case .dateAttributeType:
            return try? decode(Date.self, forKey: key)
        case .binaryDataAttributeType:
            return try? decode(Data.self, forKey: key)
        case .UUIDAttributeType:
            return try? decode(UUID.self, forKey: key)
        case .URIAttributeType:
            return try? decode(URL.self, forKey: key)
        case .transformableAttributeType:
            guard let className = attribute.attributeValueClassName,
                let theClass = NSClassFromString(className),
                let childDecoder = try? superDecoder(forKey: key),
                let codableClass = theClass as? Decodable.Type else {
                    return nil
            }
            return try? codableClass.init(from: childDecoder)
            #warning("See what can we do with transformables")
            // return try? decode(<#Type#>.self, forKey: key)
            return nil
        case .objectIDAttributeType:
            return nil
        @unknown default:
            return nil
        }
    }
}

internal extension KeyedDecodingContainer where Key: CoreDataStandardCodingKey {
    func nestedContainer(forCoreDataKey key: Key.CoreDataKey) -> Self? {
        var components = key.keyPathComponents
        _ = components.removeLast()
        return try? components.reduce(self) { (current, key) -> KeyedDecodingContainer<K> in
            return try current.nestedContainer(keyedBy: K.self, forKey: K(key))
        }
    }
    
    func contains(coreDataKey key: Key.CoreDataKey) -> Bool {
        if contains(Key(key.stringValue)) {
            return true
        } else if let nested = nestedContainer(forCoreDataKey: key), let last = key.keyPathComponents.last {
            return nested.contains(Key(last))
        }
        return false
    }
}

// MARK: - Unkeyed Container
internal extension UnkeyedDecodingContainer {
	
    mutating func decode(_ attribute: NSAttributeDescription) -> Any? {
        switch attribute.attributeType {
        case .undefinedAttributeType:
            return nil
        case .integer16AttributeType:
            return try? decode(Int16.self)
        case .integer32AttributeType:
            return try? decode(Int32.self)
        case .integer64AttributeType:
            return try? decode(Int64.self)
        case .decimalAttributeType:
            return try? decode(Decimal.self)
        case .doubleAttributeType:
            return try? decode(Double.self)
        case .floatAttributeType:
            return try? decode(Float.self)
        case .stringAttributeType:
            return try? decode(String.self)
        case .booleanAttributeType:
            return try? decode(Bool.self)
        case .dateAttributeType:
            return try? decode(Date.self)
        case .binaryDataAttributeType:
            return try? decode(Data.self)
        case .UUIDAttributeType:
            return try? decode(UUID.self)
        case .URIAttributeType:
            return try? decode(URL.self)
        case .transformableAttributeType:
            // transofrmable is not a valid identity attribute, and this is only used for identity attribute serialization
            return nil
        case .objectIDAttributeType:
            return nil
        @unknown default:
            return nil
        }
    }
}

// MARK: - Single Value Container

internal extension SingleValueDecodingContainer {
    
    mutating func decode(_ attribute: NSAttributeDescription) -> Any? {
        switch attribute.attributeType {
        case .undefinedAttributeType:
            return nil
        case .integer16AttributeType:
            return try? decode(Int16.self)
        case .integer32AttributeType:
            return try? decode(Int32.self)
        case .integer64AttributeType:
            return try? decode(Int64.self)
        case .decimalAttributeType:
            return try? decode(Decimal.self)
        case .doubleAttributeType:
            return try? decode(Double.self)
        case .floatAttributeType:
            return try? decode(Float.self)
        case .stringAttributeType:
            return try? decode(String.self)
        case .booleanAttributeType:
            return try? decode(Bool.self)
        case .dateAttributeType:
            return try? decode(Date.self)
        case .binaryDataAttributeType:
            return try? decode(Data.self)
        case .UUIDAttributeType:
            return try? decode(UUID.self)
        case .URIAttributeType:
            return try? decode(URL.self)
        case .transformableAttributeType:
            return nil
        case .objectIDAttributeType:
            return nil
        @unknown default:
            return nil
        }
    }
}
