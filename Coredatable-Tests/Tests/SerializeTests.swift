//
//  CoredatableTests.swift
//  Coredatable-Tests
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import XCTest
import CoreData

class CoredatableTests: XCTestCase {

    var container: NSPersistentContainer!
    var jsonDecoder: JSONDecoder!
    
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
        jsonDecoder.managedObjectContext = container.viewContext
    }

    override func tearDown() {
        
    }
    
    func testSerializeSimpleObject() {
        // give
        let data = Data(resource: "person.json")!
        
        // when
        let person = try! jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(person.personId, 1)
        XCTAssertEqual(person.fullName, "Marco")
    }
    
    func testSerializeWithKeyStrategy() {
        // give
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = Data(resource: "personSnakeCase.json")!
        
        // when
        let person = try! jsonDecoder.decode(Person.self, from: data)
        
        // then
        XCTAssertEqual(person.personId, 1)
        XCTAssertEqual(person.fullName, "Marco")
    }
    
    func testSerializeCustomKeyObject() {
        // give
        let data = Data(resource: "personDifferentKey.json")!
        
        // when
        let person = try! jsonDecoder.decode(PersonDiffKeys.self, from: data)
        
        // then
        XCTAssertEqual(person.personId, 1)
        XCTAssertEqual(person.fullName, "Marco")
    }
}
