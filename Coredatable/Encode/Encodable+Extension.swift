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
		if let value = value as? Bool {
			try encode(value, forKey: key)
		} else if let value = value as? Double {
			try encode(value, forKey: key)
		} else if let value = value as? String {
			try encode(value, forKey: key)
		} else if let _ = value as? NSNull {
			try encodeNil(forKey: key)
		} else if let value = value as? [String: Any] {
			try encode(value, forKey: key)
		} else if let value = value as? [Any] {
			try encode(value, forKey: key)
		}
	}
	
	mutating func encode(_ dictionary: [String: Any], forKey key: Key) throws {
		var container = nestedContainer(keyedBy: StringCodingKey.self, forKey: key)
		try dictionary.forEach { (key, value) in
			try container.encodeAny(value, forKey: StringCodingKey(key))
		}
	}
	
	mutating func encode(_ array: [Any], forKey key: Key) throws {
		var container = nestedUnkeyedContainer(forKey: key)
		try array.forEach { try container.encodeAny($0) }
	}
}

// MARK: - Unkeyed Container

internal extension UnkeyedEncodingContainer {
	mutating func encodeAny(_ value: Any) throws {
		if let value = value as? Bool {
			try encode(value)
		} else if let value = value as? Double {
			try encode(value)
		} else if let value = value as? String {
			try encode(value)
		} else if let _ = value as? NSNull {
			try encodeNil()
		} else if let value = value as? [String: Any] {
			try encode(value)
		} else if let value = value as? [Any] {
			try encode(value)
		}
	}
	
	private mutating func encode(_ dictionary: [String: Any]) throws {
		var container = nestedContainer(keyedBy: StringCodingKey.self)
		try dictionary.forEach { (key, value) in
			try container.encodeAny(value, forKey: StringCodingKey(key))
		}
	}
	
	private mutating func encode(_ array: [Any]) throws {
		var container = nestedUnkeyedContainer()
		try array.forEach { try container.encodeAny($0) }
	}
}
