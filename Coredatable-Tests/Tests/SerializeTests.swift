//
//  CO_re_DA_ta_BLE_Tests.swift
//  Coredatable-Tests
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import XCTest
import CoreData

class CO_re_DA_ta_BLE_Tests: XCTestCase {

    var container: NSPersistentContainer!
    
    override func setUp() {
        container = NSPersistentContainer(name: "Model")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }

    override func tearDown() {
        
    }
    
    func testSerializeSimpleObject() {
        
    }
}
