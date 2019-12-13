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
    var attributes: Set<PersonAttribute> {
        return attributesSet.reduce(into: []) { (result, item) in
            if let i = item as? PersonAttribute {
                result.insert(i)
            }
        }
    }
    
    static let identityAttribute: IdentityAttribute = #keyPath(Person.personId)
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
    @NSManaged var keyPath1: String?
    @NSManaged var keyPath2: String?
    
    enum CodingKeys: String, CoreDataCodingKey {
        case personId = "id"
        case fullName = "name"
        case keyPath1 = "object.one"
        case keyPath2 = "object.nested.two"
    }
}

final class NestedPerson: Codable {
    let token: String
    let person: Person
    let people: Many<Person>
}
