//
//  CoreDataDecoder.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal struct CoreDataDecoder<ManagedObject: CoreDataDecodable, Keys: AnyCoreDataCodingKey> {
    private let context: NSManagedObjectContext
    private let container: KeyedDecodingContainer<CoreDataCodingKeyWrapper<Keys>>
    
    init(decoder: Decoder) throws {
        guard let context = decoder.managedObjectContext else {
            throw CoreDataCodableError.missingContext(decoder: decoder)
        }
        
        self.context = context
        self.container = try decoder.container(keyedBy: CoreDataCodingKeyWrapper<Keys>.self)
    }
    
    func decode() throws -> ManagedObject {
        let object = try existingObject() ?? ManagedObject.init(context: context)
        try applyValues(to: object)
        return object
    }
}

private extension CoreDataDecoder {
    func existingObject() throws -> ManagedObject? {
        switch ManagedObject.identityAttribute {
        case .no:
            return nil
            
        case let .composed(propertyNames) where propertyNames.count == 0:
            return nil
            
        case let .composed(propertyNames) where propertyNames.count == 1:
            let propertyName = propertyNames.first!
            guard let codingKey = Keys(propertyName: propertyName),
                let value = container.decodeAny(forKey: codingKey.standardCodingKey) else {
                    let receivedKeys = container.allKeys.map { $0.key.stringValue }
                    throw CoreDataCodableError.missingIdentityAttribute(class: ManagedObject.self, identityAttributes: [propertyName], receivedKeys: receivedKeys)
            }
            
            let request = NSFetchRequest<ManagedObject>(entityName: ManagedObject.entity(inManagedObjectContext: context).name!)
            request.predicate = NSPredicate(format: "\(propertyName) == \(value)")
            return try context.fetch(request).first
            
        case let .composed(propertyNames):
            return nil
        }
    }
    
    func applyValues(to object: ManagedObject) throws {
        object.entity.properties.forEach {
            guard let codingKey = Keys(propertyName: $0.name),
                container.contains(codingKey.standardCodingKey)
                else { return }
            
            let value = container.decodeAny(forKey: codingKey.standardCodingKey)
            object.setValue(value, forKey: codingKey.propertyName)
        }
    }
}
