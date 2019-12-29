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
		} else if let nestedDictionary = try? decode([AnyHashable: Any].self, forKey: key) {
			return nestedDictionary
		} else if let nestedArray = try? decode([Any].self, forKey: key) {
			return nestedArray
		}
		return nil
	}
	
	private func decode(_ type: [AnyHashable: Any].Type, forKey key: K) throws -> [AnyHashable: Any] {
		let container = try self.nestedContainer(keyedBy: StringCodingKey.self, forKey: key)
		return container.allKeys.reduce([:]) { (current, key) -> [AnyHashable: Any] in
			var current = current
			current[key.stringValue] = container.decodeAny(forKey: key)
			return current
		}
	}
	
	private func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
		var container = try self.nestedUnkeyedContainer(forKey: key)
		let count = container.count ?? 0
		return (0..<count).compactMap { _ in container.decodeAny() }
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
		} else if let nestedDictionary = try? decode([AnyHashable: Any].self) {
			return nestedDictionary
		} else if let nestedArray = try? decode([Any].self) {
			return nestedArray
		}
		return nil
	}
	
	private mutating func decode(_ type: [AnyHashable: Any].Type) throws -> [AnyHashable: Any] {
		let container = try self.nestedContainer(keyedBy: StringCodingKey.self)
		return container.allKeys.reduce([:]) { (current, key) -> [AnyHashable: Any] in
			var current = current
			current[key.stringValue] = container.decodeAny(forKey: key)
			return current
		}
	}
	
	private mutating func decode(_ type: [Any].Type) throws -> [Any] {
		var container = try nestedUnkeyedContainer()
		let count = container.count ?? 0
		return (0..<count).compactMap { _ in container.decodeAny() }
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
