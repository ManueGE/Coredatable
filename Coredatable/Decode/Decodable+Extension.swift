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
	
	func decodeAny(forKey key: Key) -> Any? {
		if let boolValue = try? decode(Bool.self, forKey: key) {
			return boolValue
		} else if let stringValue = try? decode(String.self, forKey: key) {
			return stringValue
		} else if let intValue = try? decode(Int.self, forKey: key) {
			return intValue
		} else if let doubleValue = try? decode(Double.self, forKey: key) {
			return doubleValue
		} else if (try? decodeNil(forKey: key)) == true {
			return nil
		}
		return nil
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
	
	mutating func decodeAny() -> Any? {
		if let boolValue = try? decode(Bool.self) {
			return boolValue
		} else if let stringValue = try? decode(String.self) {
			return stringValue
		} else if let intValue = try? decode(Int.self) {
			return intValue
		} else if let doubleValue = try? decode(Double.self) {
			return doubleValue
		} else if (try? decodeNil()) == true {
			return nil
		}
		return nil
	}
}

// MARK: - Single Value Container

internal extension SingleValueDecodingContainer {
    
    mutating func decodeAny() -> Any? {
        if let boolValue = try? decode(Bool.self) {
            return boolValue
        } else if let stringValue = try? decode(String.self) {
            return stringValue
        } else if let intValue = try? decode(Int.self) {
            return intValue
        } else if let doubleValue = try? decode(Double.self) {
            return doubleValue
        }
        return nil
    }
}
