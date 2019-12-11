//
//  CodableTests.swift
//  Coredatable-Tests
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import XCTest
import CoreData
import Coredatable

class CodableTests: XCTestCase {

    var container: NSPersistentContainer!
    var jsonDecoder: JSONDecoder!
    var viewContext: NSManagedObjectContext { container.viewContext }
    
    override func setUp() {
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: "Model", withExtension:"momd") else {
                fatalError("Error loading model from bundle")
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        container = NSPersistentContainer(name: "Coredatable", managedObjectModel: mom)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        jsonDecoder = JSONDecoder()
        jsonDecoder.managedObjectContext = viewContext
    }

    override func tearDown() {
        
    }
    
    // MARK: - Decode
    
    func testDecodeSimpleObject() {
        // given
        let data = Data(resource: "person.json")!
        
        // when
        let person = try? jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(person?.personId, 1)
        XCTAssertEqual(person?.fullName, "Marco")
        XCTAssertEqual(person?.city, "Murcia")
        XCTAssertEqual(person?.country?.id, 1)
        XCTAssertEqual(person?.country?.name, "Spain")
        let attributes = person?.attributes.sorted { $0.id < $1.id }
        XCTAssertEqual(attributes?.count, 2)
        XCTAssertEqual(attributes?[0].id, 1)
        XCTAssertEqual(attributes?[0].name, "funny")
        XCTAssertEqual(attributes?[1].id, 2)
        XCTAssertEqual(attributes?[1].name, "small")
    }
    
    func testDecodeSimpleObjectWithNilValue() {
        // given
        let data = Data(resource: "personWithNil.json")!
        
        // when
        let person = try? jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(person?.personId, 1)
        XCTAssertEqual(person?.fullName, "Marco")
        XCTAssertEqual(person?.country?.id, 1)
        XCTAssertEqual(person?.country?.name, "Spain")
        XCTAssertNil(person?.city)
        let attributes = person?.attributes.sorted { $0.id < $1.id }
        XCTAssertEqual(attributes?.count, 2)
        XCTAssertEqual(attributes?[0].id, 1)
        XCTAssertEqual(attributes?[0].name, "funny")
        XCTAssertEqual(attributes?[1].id, 2)
        XCTAssertEqual(attributes?[1].name, "small")
    }
    
    func testDecodeWithKeyStrategy() {
        // given
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = Data(resource: "personSnakeCase.json")!
        
        // when
        let person = try? jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(person?.personId, 1)
        XCTAssertEqual(person?.fullName, "Marco")
    }
    
    func testDecodeWithCustomKeys() {
        // given
        let data = Data(resource: "personDifferentKey.json")!
        
        // when
        let person = try? jsonDecoder.decode(PersonDiffKeys.self, from: data)
        
        // then
        XCTAssertEqual(person?.personId, 1)
        XCTAssertEqual(person?.fullName, "Marco")
    }
    
    func testDecodeUpdatingValueWithSingleUniqueIdentifier() {
        // given
        let existing = Person(context: viewContext)
        existing.fullName = "Marcoto"
        existing.personId = 1
        let request: NSFetchRequest<Person> = NSFetchRequest(entityName: "Person")
        XCTAssertEqual(try viewContext.count(for: request), 1)
        
        let data = Data(resource: "person.json")!
        
        // when
        let person = try? jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(try viewContext.count(for: request), 1)
        XCTAssertEqual(person?.personId, 1)
        XCTAssertEqual(person?.fullName, "Marco")
        XCTAssertEqual(person?.objectID, existing.objectID)
    }
    
    func testDecodeUpdatingValueWithSingleUniqueIdentifierAndNilValue() {
        // given
        let existing = Person(context: viewContext)
        existing.fullName = "Marcoto"
        existing.personId = 1
        existing.city = "Murcia"
        let request: NSFetchRequest<Person> = NSFetchRequest(entityName: "Person")
        XCTAssertEqual(try viewContext.count(for: request), 1)
        
        let data = Data(resource: "personWithNil.json")!
        
        // when
        let person = try? jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(try viewContext.count(for: request), 1)
        XCTAssertEqual(person?.personId, 1)
        XCTAssertEqual(person?.fullName, "Marco")
        XCTAssertNil(person?.city)
        XCTAssertEqual(person?.objectID, existing.objectID)
    }
    
    func testDecodeUpdatingValueWithSingleUniqueIdentifierAndMissingKeys() {
        // given
        let existing = Person(context: viewContext)
        existing.fullName = "Marcoto"
        existing.personId = 1
        existing.city = "Murcia"
        let request: NSFetchRequest<Person> = NSFetchRequest(entityName: "Person")
        XCTAssertEqual(try viewContext.count(for: request), 1)
        
        let data = Data.fromJson(["personId": 1, "fullName": "Marco"])!
        
        // when
        let person = try? jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(try? viewContext.count(for: request), 1)
        XCTAssertEqual(person?.personId, 1)
        XCTAssertEqual(person?.fullName, "Marco")
        XCTAssertEqual(person?.city, "Murcia")
        XCTAssertEqual(person?.objectID, existing.objectID)
    }
    
    func testDecodeManyUpdatingExistingValues() {
        // given
        let existing1 = Person(context: viewContext)
        existing1.fullName = "Marcoto"
        existing1.personId = 1
        existing1.city = "Murcia"
        
        let existing2 = Person(context: viewContext)
        existing2.fullName = "Ana Ester"
        existing2.personId = 2
        existing2.city = "La Ñora"
        
        let request: NSFetchRequest<Person> = NSFetchRequest(entityName: "Person")
        XCTAssertEqual(try viewContext.count(for: request), 2)
        
        let data = Data.fromArray([["personId": 1, "fullName": "Marco"], ["personId": 2, "fullName": "Ana"]])!
        
        // when
        let people = try? jsonDecoder.decode(Many<Person>.self, from: data)
        
        // then
        XCTAssertEqual(try viewContext.count(for: request), 2)
        
        XCTAssertEqual(people?[0].personId, 1)
        XCTAssertEqual(people?[0].fullName, "Marco")
        XCTAssertEqual(people?[0].city, "Murcia")
        XCTAssertEqual(people?[0].objectID, existing1.objectID)
        
        XCTAssertEqual(people?[1].personId, 2)
        XCTAssertEqual(people?[1].fullName, "Ana")
        XCTAssertEqual(people?[1].city, "La Ñora")
        XCTAssertEqual(people?[1].objectID, existing2.objectID)
    }
    
    func testDecodeObjectWithNestedManagedObject() {
        // given
        let data = Data(resource: "nestedPerson.json")!
        
        // when
        let object = try? jsonDecoder.decode(NestedPerson.self, from: data)
        
        // then
        XCTAssertEqual(object?.token, "abcdefg")
        let person = object?.person
        XCTAssertEqual(person?.personId, 1)
        XCTAssertEqual(person?.fullName, "Marco")
        XCTAssertEqual(person?.city, "Murcia")
        XCTAssertEqual(person?.country?.id, 1)
        XCTAssertEqual(person?.country?.name, "Spain")
        let attributes = person?.attributes.sorted { $0.id < $1.id }
        XCTAssertEqual(attributes?.count, 2)
        XCTAssertEqual(attributes?[0].id, 1)
        XCTAssertEqual(attributes?[0].name, "funny")
        XCTAssertEqual(attributes?[1].id, 2)
        XCTAssertEqual(attributes?[1].name, "small")
    }

    func testDecodeObjectFromIdentityAttributes() {
        // given
        struct Wrapper: Decodable {
            let person: Person
        }
        let data = Data.fromJson(["person": 1])!
        
        // when
        let wrapper = try? jsonDecoder.decode(Wrapper.self, from: data)
        
        // then
        let request: NSFetchRequest<Person> = NSFetchRequest(entityName: "Person")
        XCTAssertEqual(try viewContext.count(for: request), 1)
        
        XCTAssertEqual(wrapper?.person.personId, 1)
        XCTAssertNil(wrapper?.person.fullName)
        XCTAssertNil(wrapper?.person.city)
    }
    
    func testDecodeUpdateObjectFromIdentityAttributes() {
        // given
        struct Wrapper: Decodable {
            let person: Person
        }
        let data = Data.fromJson(["person": 1])!
        let existing1 = Person(context: viewContext)
         existing1.fullName = "Marco"
         existing1.personId = 1
         existing1.city = "Murcia"
        
        // when
        let wrapper = try? jsonDecoder.decode(Wrapper.self, from: data)
        
        // then
        let request: NSFetchRequest<Person> = NSFetchRequest(entityName: "Person")
        XCTAssertEqual(try viewContext.count(for: request), 1)
        
        XCTAssertEqual(wrapper?.person.personId, 1)
        XCTAssertEqual(wrapper?.person.fullName, "Marco")
        XCTAssertEqual(wrapper?.person.city, "Murcia")
        XCTAssertEqual(wrapper?.person.objectID, existing1.objectID)
    }
    
    func testDecodeArrayFromIdentityAttributes() {
        // given
        let data = Data.fromArray([1, 2])!
        
        // when
        let people = try? jsonDecoder.decode(Many<Person>.self, from: data)
        
        // then
        let request: NSFetchRequest<Person> = NSFetchRequest(entityName: "Person")
        XCTAssertEqual(try viewContext.count(for: request), 2)
        
        XCTAssertEqual(people?[0].personId, 1)
        XCTAssertNil(people?[0].fullName)
        XCTAssertNil(people?[0].city)
        
        XCTAssertEqual(people?[1].personId, 2)
        XCTAssertNil(people?[1].fullName)
        XCTAssertNil(people?[1].city)
    }
    
    func testDecodeArrayUpdateFromIdentityAttributes() {
        // given
        let existing1 = Person(context: viewContext)
        existing1.fullName = "Marco"
        existing1.personId = 1
        existing1.city = "Murcia"
        
        let existing2 = Person(context: viewContext)
        existing2.fullName = "Ana"
        existing2.personId = 2
        existing2.city = "La Ñora"
        let data = Data.fromArray([1, 2])!
        
        // when
        let people = try? jsonDecoder.decode(Many<Person>.self, from: data)
        
        // then
        let request: NSFetchRequest<Person> = NSFetchRequest(entityName: "Person")
        XCTAssertEqual(try viewContext.count(for: request), 2)
        
        XCTAssertEqual(people?[0].personId, 1)
        XCTAssertEqual(people?[0].fullName, "Marco")
        XCTAssertEqual(people?[0].city, "Murcia")
        XCTAssertEqual(people?[0].objectID, existing1.objectID)
        
        XCTAssertEqual(people?[1].personId, 2)
        XCTAssertEqual(people?[1].fullName, "Ana")
        XCTAssertEqual(people?[1].city, "La Ñora")
        XCTAssertEqual(people?[1].objectID, existing2.objectID)
    }
    
    // MARK: - Encode
    func testEncodeSimpleObject() {
        // given
        let marco = Person(context: container.viewContext)
        marco.personId = 1
        marco.fullName = "Marco"
        
        // when
        let data = try! JSONEncoder().encode(marco)
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        // then
        XCTAssertEqual(json?.count, 2)
        XCTAssertEqual(json?["personId"] as! Int, 1)
        XCTAssertEqual(json?["fullName"] as! String, "Marco")
    }
    
    func testEncodeWithKeyStrategy() {
        // given
        let marco = Person(context: container.viewContext)
        marco.personId = 1
        marco.fullName = "Marco"
        
        // when
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try! encoder.encode(marco)
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        
        // then
        XCTAssertEqual(json?.count, 2)
        XCTAssertEqual(json?["person_id"] as! Int, 1)
        XCTAssertEqual(json?["full_name"] as! String, "Marco")
    }
    
    func testEncodeWithCustomKeys() {
        // given
        let marco = PersonDiffKeys(context: container.viewContext)
        marco.personId = 1
        marco.fullName = "Marco"
        
        // when
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try! encoder.encode(marco)
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        // then
        XCTAssertEqual(json?.count, 2)
        XCTAssertEqual(json?["id"] as? Int, 1)
        XCTAssertEqual(json?["name"] as? String, "Marco")
    }
}
