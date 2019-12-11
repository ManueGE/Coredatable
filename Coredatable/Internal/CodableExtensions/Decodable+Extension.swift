//
//  Decoder+Extension.swift
//  Coredatable
//
//  Created by Manuel García-Estañ on 12/07/2019.
//  Copyright © 2019 Manuege. All rights reserved.
//

import CoreData

#warning("Maybe removable")
// MARK: - Convert to array / dictionary
/*
extension Decoder {
	func asDictionary() throws -> [AnyHashable: Any] {
		let container = try self.container(keyedBy: StringCodingKey.self)
		return container.allKeys.reduce([:]) { (current, key) -> [AnyHashable: Any] in
			var current = current
			current[key.stringValue] = container.decodeAny(forKey: key)
			return current
		}
	}
	
	func asArray() throws -> [Any] {
		var container = try self.unkeyedContainer()
		let count = container.count ?? 0
		return (0..<count).compactMap { _ in container.decodeAny() }
	}
}
*/
extension KeyedDecodingContainer {
	
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
	
	func decode(_ type: [AnyHashable: Any].Type, forKey key: K) throws -> [AnyHashable: Any] {
		let container = try self.nestedContainer(keyedBy: StringCodingKey.self, forKey: key)
		return container.allKeys.reduce([:]) { (current, key) -> [AnyHashable: Any] in
			var current = current
			current[key.stringValue] = container.decodeAny(forKey: key)
			return current
		}
	}
	
	func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
		var container = try self.nestedUnkeyedContainer(forKey: key)
		let count = container.count ?? 0
		return (0..<count).compactMap { _ in container.decodeAny() }
	}
}


extension UnkeyedDecodingContainer {
	
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
	
	mutating func decode(_ type: [AnyHashable: Any].Type) throws -> [AnyHashable: Any] {
		let container = try self.nestedContainer(keyedBy: StringCodingKey.self)
		return container.allKeys.reduce([:]) { (current, key) -> [AnyHashable: Any] in
			var current = current
			current[key.stringValue] = container.decodeAny(forKey: key)
			return current
		}
	}
	
	mutating func decode(_ type: [Any].Type) throws -> [Any] {
		var container = try nestedUnkeyedContainer()
		let count = container.count ?? 0
		return (0..<count).compactMap { _ in container.decodeAny() }
	}
}

extension SingleValueDecodingContainer {
    
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
