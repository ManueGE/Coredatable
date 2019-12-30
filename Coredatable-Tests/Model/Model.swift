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

final class Person: NSManagedObject, CoreDataCodable {
    typealias CodingKeys = CoreDataDefaultCodingKeys
    
    @NSManaged var personId: Int
    @NSManaged var fullName: String?
    @NSManaged var city: String?
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
    
    func initialize(from container: CoreDataKeyedDecodingContainer<Person>) throws {
        try defaultInitialization(from: container)
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
    
    func initialize(from container: CoreDataKeyedDecodingContainer<Custom>) throws {
        var container = container
        container[.id] = Int(try container.decode(String.self, forKey: .id)) ?? 0
        
        try defaultInitialization(from: container, with: [.id])
        
        let first = try container.decode(String.self, forKey: .first)
        let second = try container.decode(String.self, forKey: .second)
        compound = [first, second].joined(separator: " ")
        
        let string = try container.decode(String.self, forKey: .integer)
        integer = Int(string) ?? 0
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
    
    func initialize(from container: CoreDataKeyedDecodingContainer<CustomDoubleId>) throws {
        try defaultInitialization(from: container)
    }
    
    static var identityAttribute: IdentityAttribute = #keyPath(CustomDoubleId.id)
    
    static func prepare(_ container: CoreDataKeyedDecodingContainer<CustomDoubleId>) throws -> CoreDataKeyedDecodingContainer<CustomDoubleId> {
        var container = container
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
