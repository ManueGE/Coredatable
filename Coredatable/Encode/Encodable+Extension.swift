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
	mutating func encodeAny(_ value: Any, forKey key: Key) throws {
		if let value = value as? Int {
			try encode(value, forKey: key)
		} else if let value = value as? Double {
			try encode(value, forKey: key)
		} else if let value = value as? Bool {
            try encode(value, forKey: key)
        } else if let value = value as? String {
			try encode(value, forKey: key)
		} else if let _ = value as? NSNull {
			try encodeNil(forKey: key)
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

// MARK: - Unkeyed Container

internal extension UnkeyedEncodingContainer {
	mutating func encodeAny(_ value: Any) throws {
        if let value = value as? Int {
            try encode(value)
        } else if let value = value as? Double {
			try encode(value)
		} else if let value = value as? Bool {
            try encode(value)
        } else if let value = value as? String {
			try encode(value)
		} else if let _ = value as? NSNull {
			try encodeNil()
		}
	}
}
