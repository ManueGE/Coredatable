//
//  CoreDataKeyedDecodingContainer.swift
//  Coredatable
//
//  Created by Manu on 30/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

/// A replacement for `KeyedDecodingContainer` where the Keys are `AnyCoreDataKey`.
/// It is used in the `initialize` methods of a `CoreDataDecodable`.
/// It can be used in the same way as the regular `KeyedDecodingContainer`
public struct CoreDataKeyedDecodingContainer<ManagedObject: CoreDataDecodable> {
    public typealias Key = ManagedObject.CodingKeys
    private let container: KeyedDecodingContainer<Key.Standard>
    private var manualValues: [String: Any?] = [:]
    
    public var codingPath: [Key] { container.codingPath.compactMap { Key(stringValue: $0.stringValue) } }
    public var allKeys: [Key] { container.allKeys.compactMap { Key(stringValue: $0.stringValue) } }
    
    static func from(_ container: KeyedDecodingContainer<Key.Standard>) throws -> Self {
        let container = Self(container: container)
        return try ManagedObject.prepare(container)
    }
    
    private init(container: KeyedDecodingContainer<Key.Standard>) {
        self.container = container
    }
    
    /// MARK: Decodable methods
    public func contains(_ key: Key) -> Bool {
        if manualValues.keys.contains(key.stringValue) {
            return true
        }
        return container.contains(coreDataKey: key)
    }
    
    public func decodeNil(forKey key: Key) throws -> Bool {
        if let value = manualValues[key.stringValue] {
            return value == nil
        }
        return try nestedContainer(forKey: key).decodeNil(forKey: key.standarized)
    }
    
    public func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        if let value = manualValues[key.stringValue] {
            if let casted = value as? T {
                return casted
            } else {
                let context = DecodingError.Context(codingPath: container.codingPath + [key.standarized], debugDescription: "Expected \(T.self), received \(String(describing: value))")
                throw DecodingError.typeMismatch(T.self, context)
            }
        }
        return try nestedContainer(forKey: key).decode(T.self, forKey: key.standarized)
    }
    
    public func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
        do {
            return try decode(T.self, forKey: key)
        } catch DecodingError.keyNotFound {
            return nil
        } catch DecodingError.valueNotFound {
            return nil
        }
    }
    
    internal func decode(_ attribute: NSAttributeDescription, forKey key: Key) -> Any? {
        if let value = manualValues[key.stringValue] {
            return value
        }
        return nestedContainer(forKey: key).decode(attribute, forKey: key.standarized)
    }
    
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        return try nestedContainer(forKey: key).nestedContainer(keyedBy: NestedKey.self, forKey: key.standarized)
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return try nestedContainer(forKey: key).nestedUnkeyedContainer(forKey: key.standarized)
    }
    
    public func superDecoder() throws -> Decoder {
        try container.superDecoder()
    }
    
    public func superDecoder(forKey key: Key) throws -> Decoder {
        try container.superDecoder(forKey: key.standarized)
    }
    
    private func nestedContainer(forKey key: Key) -> KeyedDecodingContainer<Key.Standard> {
        return container.nestedContainer(forCoreDataKey: key) ?? container
    }
    
    /// MARK: Set manual values
    public subscript(key: Key) -> Any? {
        get {
            if let value = manualValues[key.stringValue] {
                return value
            } else {
                return nil
            }
        }
        set { manualValues[key.stringValue] = newValue }
    }
}
