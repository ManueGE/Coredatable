//
//  CodableTests.swift
//  Coredatable-Tests
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import XCTest
import CoreData

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
        let person = try! jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(person.personId, 1)
        XCTAssertEqual(person.fullName, "Marco")
        XCTAssertEqual(person.city, "Murcia")
        /*
        let attributes = person.attributes.sorted { $0.id < $1.id }
        XCTAssertEqual(attributes.count, 2)
        XCTAssertEqual(attributes[0].id, 1)
        XCTAssertEqual(attributes[0].name, "clever")
        XCTAssertEqual(attributes[1].id, 2)
        XCTAssertEqual(attributes[1].name, "small")*/
    }
    
    func testDecodeSimpleObjectWithNilValue() {
        // given
        let data = Data(resource: "personWithNil.json")!
        
        // when
        let person = try! jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(person.personId, 1)
        XCTAssertEqual(person.fullName, "Marco")
        XCTAssertNil(person.city)
        /*
        let attributes = person.attributes.sorted { $0.id < $1.id }
        XCTAssertEqual(attributes.count, 2)
        XCTAssertEqual(attributes[0].id, 1)
        XCTAssertEqual(attributes[0].name, "clever")
        XCTAssertEqual(attributes[1].id, 2)
        XCTAssertEqual(attributes[1].name, "small")*/
    }
    
    func testDecodeWithKeyStrategy() {
        // given
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = Data(resource: "personSnakeCase.json")!
        
        // when
        let person = try! jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(person.personId, 1)
        XCTAssertEqual(person.fullName, "Marco")
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
        let person = try! jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(try viewContext.count(for: request), 1)
        XCTAssertEqual(person.personId, 1)
        XCTAssertEqual(person.fullName, "Marco")
        XCTAssertEqual(person.objectID, existing.objectID)
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
        let person = try! jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(try viewContext.count(for: request), 1)
        XCTAssertEqual(person.personId, 1)
        XCTAssertEqual(person.fullName, "Marco")
        XCTAssertNil(person.city)
        XCTAssertEqual(person.objectID, existing.objectID)
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
        let person = try! jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(try viewContext.count(for: request), 1)
        XCTAssertEqual(person.personId, 1)
        XCTAssertEqual(person.fullName, "Marco")
        XCTAssertEqual(person.city, "Murcia")
        XCTAssertEqual(person.objectID, existing.objectID)
    }
    
    // MARK: - Encode
    func testEncodeSimpleObject() {
        // given
        let marco = Person(context: container.viewContext)
        marco.personId = 1
        marco.fullName = "Marco"
        
        // when
        let data = try! JSONEncoder().encode(marco)
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        // then
        XCTAssertEqual(json.count, 2)
        XCTAssertEqual(json["personId"] as! Int, 1)
        XCTAssertEqual(json["fullName"] as! String, "Marco")
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
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        // then
        XCTAssertEqual(json.count, 2)
        XCTAssertEqual(json["person_id"] as! Int, 1)
        XCTAssertEqual(json["full_name"] as! String, "Marco")
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
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        // then
        XCTAssertEqual(json.count, 2)
        XCTAssertEqual(json["id"] as? Int, 1)
        XCTAssertEqual(json["name"] as? String, "Marco")
    }
}
