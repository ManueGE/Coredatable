//
//  ManyTests.swift
//  Coredatable-Tests
//
//  Created by Manu on 03/01/2020.
//  Copyright © 2020 Manuel García-Estañ. All rights reserved.
//

import XCTest
import Coredatable

class ManyTests: XCTestCase {
    
    var container: NSPersistentContainer!
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
    }
    
    func testMany() {
        // given
        func person(id: Int) -> Person {
            let person = Person(context: viewContext)
            person.personId = id
            return person
        }
        var many: Many = [person(id: 1), person(id: 2)]
        many.append(person(id: 3))
        
        // then
        XCTAssertEqual(many.count, 3)
        XCTAssertEqual(many[0].personId, 1)
        XCTAssertEqual(many[1].personId, 2)
        XCTAssertEqual(many[2].personId, 3)
        XCTAssertEqual(many.first?.personId, 1)
        XCTAssertEqual(many.last?.personId, 3)
        XCTAssertEqual(many[0...1].map { $0.personId }, [1, 2])
        
        XCTAssertEqual(many.customMirror.displayStyle, .collection)
        XCTAssert(many.customMirror.subjectType == Many<Person>.self)
        XCTAssertEqual(many.customMirror.children.count, 3)
        
        many[0...1] = [person(id: 4), person(id: 5)]
        XCTAssertEqual(many[0].personId, 4)
        XCTAssertEqual(many[1].personId, 5)
        
        many[0] = person(id: 6)
        XCTAssertEqual(many[0].personId, 6)
        
        
        
    }
}
