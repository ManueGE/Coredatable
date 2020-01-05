//
//  Model.swift
//  Coredatable-Tests
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation
import Coredatable
import CoreData

final class Person: NSManagedObject, CoreDataCodable, UsingDefaultCodingKeys {
    @NSManaged var personId: Int
    @NSManaged var fullName: String?
    @NSManaged var city: String?
    @NSManaged var date: Date?
    @NSManaged var country: Country?
    @NSManaged var attributesSet: NSSet
    var customValue = ""
    
    var attributes: Set<PersonAttribute> {
        return attributesSet.reduce(into: []) { (result, item) in
            if let i = item as? PersonAttribute {
                result.insert(i)
            }
        }
    }
    
    static let identityAttribute: IdentityAttribute = #keyPath(Person.personId)
    
    func initialize(from decoder: Decoder) throws {
        try defaultInitialization(from: decoder)
        customValue = "custom"
    }
}

final class PersonAttribute: NSManagedObject, CoreDataCodable {
    typealias CodingKeys = CoreDataDefaultCodingKeys
    
    @NSManaged private(set) var id: Int
    @NSManaged private(set) var name: String
    
    static let identityAttribute: IdentityAttribute = #keyPath(PersonAttribute.id)
}

final class Country: NSManagedObject, CoreDataCodable {
    typealias CodingKeys = CoreDataDefaultCodingKeys
    
    @NSManaged private(set) var id: Int
    @NSManaged private(set) var name: String
    
    static let identityAttribute: IdentityAttribute = #keyPath(Country.id)
}

final class PersonDiffKeys: NSManagedObject, CoreDataCodable {
    @NSManaged var personId: Int
    @NSManaged var fullName: String
    @NSManaged var city: String?
    @NSManaged var keyPath1: String?
    @NSManaged var keyPath2: String?
    
    enum CodingKeys: String, CoreDataCodingKey {
        case personId = "id"
        case fullName = "name"
        case city
        case keyPath1 = "object.one"
        case keyPath2 = "object.nested.two"
    }
}

final class NestedPerson: Codable {
    let token: String
    let person: Person
    let people: Many<Person>
}

final class Custom: NSManagedObject, CoreDataDecodable {
    @NSManaged var id: Int
    @NSManaged var compound: String
    @NSManaged var integer: Int
    
    enum CodingKeys: String, CoreDataCodingKey {
        case id
        case first
        case second
        case integer
    }
    
    static var identityAttribute: IdentityAttribute = #keyPath(Custom.id)
    
    func initialize(from decoder: Decoder) throws {
        try defaultInitialization(from: decoder, with: [.id])
        
        let container = try decoder.container(for: Custom.self)
        let first = try container.decode(String.self, forKey: .first)
        let second = try container.decode(String.self, forKey: .second)
        compound = [first, second].joined(separator: " ")
        
        let string = try container.decode(String.self, forKey: .integer)
        integer = Int(string) ?? 0
    }
    
    static func container(for decoder: Decoder) throws -> Any {
        var container = try decoder.container(for: Custom.self)
        container[.id] = Int(try container.decode(String.self, forKey: .id)) ?? 0
        return container
    }
}

final class CustomDoubleId: NSManagedObject, CoreDataDecodable {
    @NSManaged var id: String
    @NSManaged var value: String
    
    enum CodingKeys: String, CoreDataCodingKey {
        case id
        case first
        case last
        case value
    }
        
    static var identityAttribute: IdentityAttribute = #keyPath(CustomDoubleId.id)
    
    static func container(for decoder: Decoder) throws -> Any {
        var container = try decoder.container(for: CustomDoubleId.self)
        let first = try container.decode(String.self, forKey: .first)
        let last = try container.decode(String.self, forKey: .last)
        container[.id] = first + last
        return container
    }
}

final class Card: NSManagedObject, CoreDataDecodable {
    @NSManaged var suit: String
    @NSManaged var value: String
    @NSManaged var numberOfTimesPlayed: Int
    
    enum CodingKeys: String, CoreDataCodingKey {
        case suit, value
        case numberOfTimesPlayed = "played"
    }
    
    static var identityAttribute: IdentityAttribute = [#keyPath(Card.suit), #keyPath(Card.value)]
}

final class CodableContainer: NSManagedObject, CoreDataCodable {
    @NSManaged var codable: RelationshipCodable
    @NSManaged var codableMany: NSSet
    @NSManaged var coreData: RelationshipCoreDataCodable
    @NSManaged var coreDataMany: NSSet
    
    typealias CodingKeys = CoreDataDefaultCodingKeys
}

final class RelationshipCoreDataCodable: NSManagedObject, CoreDataCodable {
    @NSManaged var id: Int64
    @NSManaged var value: String
    @NSManaged var inverse: CodableContainer
    @NSManaged var inverseMany: CodableContainer
    
    typealias CodingKeys = CoreDataDefaultCodingKeys
}

final class RelationshipCodable: NSManagedObject, Codable {
    @NSManaged var id: Int64
    @NSManaged var value: String
    @NSManaged var inverse: CodableContainer
    @NSManaged var inverseMany: CodableContainer
    
    convenience init(from decoder: Decoder) throws {
        guard let context = decoder.managedObjectContext else {
            fatalError()
        }
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        value = try container.decode(String.self, forKey: .value)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(value, forKey: .value)
    }
}

class Complete: NSManagedObject, CoreDataCodable {
    @NSManaged var int16: Int16
    @NSManaged var int32: Int32
    @NSManaged var decimal: NSDecimalNumber?
    @NSManaged var double: Double
    @NSManaged var float: Float
    @NSManaged var boolean: Bool
    @NSManaged var date: Date?
    @NSManaged var string: String?
    @NSManaged var int64: Int64
    @NSManaged var binary: Data?
    @NSManaged var uuid: UUID?
    @NSManaged var uri: URL?
    @NSManaged var transformable: [String]?
    
    func initialize(from decoder: Decoder) throws {
        let key: CoreDataDefaultCodingKeys = #keyPath(Complete.transformable)
        try self.defaultInitialization(from: decoder, skipping: [#keyPath(Complete.transformable)])
        let container = try decoder.container(for: Complete.self)
        transformable = try container.decodeIfPresent([String].self, forKey: key)
    }
    
    typealias CodingKeys = CoreDataDefaultCodingKeys
    static var identityAttribute: IdentityAttribute = #keyPath(Complete.int16)
}
