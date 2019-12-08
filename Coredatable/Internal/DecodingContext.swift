//
//  DecodingContext.swift
//  Coredatable
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation
import CoreData

@objc public protocol DecodingContextType {
    var managedObjectContext: NSManagedObjectContext { get }
    func containsKey(_ key: String) -> Bool
    func decodedValue(forKey key: String) -> Any?
}

final class DecodingContext<Keys: CoreDataCodingKey>: NSObject, DecodingContextType {
    private typealias BridgeCodingKeys = CoreDataCodingKeyWrapper<Keys>
    private let container: KeyedDecodingContainer<BridgeCodingKeys>
    @objc let managedObjectContext: NSManagedObjectContext
    private let codingKeysByPropertyNames: [String: BridgeCodingKeys]
    
    init(decoder: Decoder, codingKeys: Keys.Type) throws {
        guard let managedObjectContext = decoder.managedObjectContext else {
            throw CoreDataCodableError.missingContext
        }
        self.managedObjectContext = managedObjectContext
        self.container = try decoder.container(keyedBy: BridgeCodingKeys.self)
        self.codingKeysByPropertyNames = self.container.allKeys.reduce(into: [:]) { (current, key) in
            guard let coreDataKey = Keys(stringValue: key.stringValue) else { return }
            current[coreDataKey.propertyName] = key
        }
    }
    
    @objc func containsKey(_ key: String) -> Bool {
        guard let codingKey = codingKey(for: key) else {
            return false
        }
        return container.contains(codingKey.standardCodingKey)
    }
    
    @objc func decodedValue(forKey key: String) -> Any? {
        guard let codingKey = codingKey(for: key) else {
            return nil
        }
        return container.decodeAny(forKey: codingKey.standardCodingKey)
    }
    
    private func codingKey(for propertyName: String) -> Keys? {
        codingKeysByPropertyNames[propertyName]?.key
    }
}
