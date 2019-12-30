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
    
    // MARK: - Decode
    
    func testDecodeSimpleObject() {
        // given
        let data = Data(resource: "person.json")!
        
        // when
        let person: Person?
        do {
           person = try jsonDecoder.decode(Person.self, from: data)
        } catch {
            XCTFail()
            return
        }
        
        // then
        XCTAssertEqual(person?.personId, 1)
        XCTAssertEqual(person?.fullName, "Marco")
        XCTAssertEqual(person?.city, "Murcia")
        XCTAssertEqual(person?.country?.id, 1)
        XCTAssertEqual(person?.country?.name, "Spain")
        XCTAssertEqual(person?.customValue, "custom")
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
        XCTAssertEqual(person?.customValue, "custom")
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
        XCTAssertEqual(person?.keyPath1, "keypath1")
        XCTAssertEqual(person?.keyPath2, "keypath2")
    }
    
    func testDecodeArrayWithCustomKeys() {
        // given
        let data = Data(resource: "personDiffKeyArray.json")!
        
        // when
        let person = try? jsonDecoder.decode([PersonDiffKeys].self, from: data).first
        
        // then
        XCTAssertEqual(person?.personId, 1)
        XCTAssertEqual(person?.fullName, "Marco")
        XCTAssertEqual(person?.keyPath1, "keypath1")
        XCTAssertEqual(person?.keyPath2, "keypath2")
    }
    
    func testDecodeManyWithCustomKeys() {
        // given
        let data = Data(resource: "personDiffKeyArray.json")!
        
        // when
        let person = try? jsonDecoder.decode(Many<PersonDiffKeys>.self, from: data).first
        
        // then
        XCTAssertEqual(person?.personId, 1)
        XCTAssertEqual(person?.fullName, "Marco")
        XCTAssertEqual(person?.keyPath1, "keypath1")
        XCTAssertEqual(person?.keyPath2, "keypath2")
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
        XCTAssertEqual(person?.customValue, "custom")
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
        XCTAssertEqual(person?.customValue, "custom")
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
        XCTAssertEqual(person?.customValue, "custom")
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
        XCTAssertEqual(people?[0].customValue, "custom")
        XCTAssertEqual(people?[0].objectID, existing1.objectID)
        
        XCTAssertEqual(people?[1].personId, 2)
        XCTAssertEqual(people?[1].fullName, "Ana")
        XCTAssertEqual(people?[1].city, "La Ñora")
        XCTAssertEqual(people?[1].customValue, "custom")
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
        XCTAssertEqual(person?.customValue, "custom")
        
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
        XCTAssertEqual(wrapper?.person.customValue, "custom")
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
        XCTAssertEqual(wrapper?.person.customValue, "custom")
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
        XCTAssertEqual(people?[0].customValue, "custom")
        
        XCTAssertEqual(people?[1].personId, 2)
        XCTAssertNil(people?[1].fullName)
        XCTAssertNil(people?[1].city)
        XCTAssertEqual(people?[1].customValue, "custom")
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
        XCTAssertEqual(people?[0].customValue, "custom")
        XCTAssertEqual(people?[0].objectID, existing1.objectID)
        
        XCTAssertEqual(people?[1].personId, 2)
        XCTAssertEqual(people?[1].fullName, "Ana")
        XCTAssertEqual(people?[1].city, "La Ñora")
        XCTAssertEqual(people?[1].customValue, "custom")
        XCTAssertEqual(people?[1].objectID, existing2.objectID)
    }
    
    func testCustomSerialization() {
        // given
        let data = Data.fromJson(["id": "1", "first": "FIRST", "second": "SECOND", "integer": "20"])!
        
        // when
        let custom = try? jsonDecoder.decode(Custom.self, from: data)
        
        // then
        XCTAssertNotNil(custom)
        XCTAssertEqual(custom?.id, 1)
        XCTAssertEqual(custom?.compound, "FIRST SECOND")
        XCTAssertEqual(custom?.integer, 20)
    }
    
    func testCustomSerializationArray() {
        // given
        let data = Data.fromArray([
            ["id": "1", "first": "FIRST", "second": "SECOND", "integer": "20"],
            ["id": "2", "first": "UNO", "second": "DOS", "integer": "30"]
        ])!
        
        // when
        let customs = try? jsonDecoder.decode([Custom].self, from: data)
        
        // then
        XCTAssertNotNil(customs)
        XCTAssertEqual(customs?.count, 2)
        
        XCTAssertEqual(customs?.first?.id, 1)
        XCTAssertEqual(customs?.first?.compound, "FIRST SECOND")
        XCTAssertEqual(customs?.first?.integer, 20)
        
        XCTAssertEqual(customs?.last?.id, 2)
        XCTAssertEqual(customs?.last?.compound, "UNO DOS")
        XCTAssertEqual(customs?.last?.integer, 30)
    }
    
    func testCustomSerializationMany() {
        // given
        let data = Data.fromArray([
            ["id": "1", "first": "FIRST", "second": "SECOND", "integer": "20"],
            ["id": "2", "first": "UNO", "second": "DOS", "integer": "30"]
        ])!
        
        // when
        let customs = try? jsonDecoder.decode(Many<Custom>.self, from: data)
        
        // then
        XCTAssertNotNil(customs)
        XCTAssertEqual(customs?.count, 2)
        
        XCTAssertEqual(customs?.first?.id, 1)
        XCTAssertEqual(customs?.first?.compound, "FIRST SECOND")
        XCTAssertEqual(customs?.first?.integer, 20)
        
        XCTAssertEqual(customs?.last?.id, 2)
        XCTAssertEqual(customs?.last?.compound, "UNO DOS")
        XCTAssertEqual(customs?.last?.integer, 30)
    }
    
    func testCustomCompondId() {
        // given
        let data = Data.fromJson(["first": "0", "last": "1", "value": "one"])!
        
        // when
        let custom = try? jsonDecoder.decode(CustomDoubleId.self, from: data)
        
        // then
        XCTAssertNotNil(custom)
        XCTAssertEqual(custom?.id, "01")
        XCTAssertEqual(custom?.value, "one")
    }
    
    func testCustomCompondIdFromArray() {
        // given
        let data = Data.fromArray([["first": "0", "last": "1", "value": "one"]])!
        
        // when
        let custom = try? jsonDecoder.decode([CustomDoubleId].self, from: data).first
        
        // then
        XCTAssertNotNil(custom)
        XCTAssertEqual(custom?.id, "01")
        XCTAssertEqual(custom?.value, "one")
    }
    
    func testCustomCompondIdFromMany() {
        // given
        let data = Data.fromArray([["first": "0", "last": "1", "value": "one"]])!
        
        // when
        let custom = try? jsonDecoder.decode(Many<CustomDoubleId>.self, from: data).first
        
        // then
        XCTAssertNotNil(custom)
        XCTAssertEqual(custom?.id, "01")
        XCTAssertEqual(custom?.value, "one")
    }
    
    func testCustomCompondIdUpdate() {
        // given
        let existing = CustomDoubleId(context: container.viewContext)
        existing.id = "01"
        existing.value = "zero"
        
        let data = Data.fromJson(["first": "0", "last": "1", "value": "one"])!
        
        // when
        let custom = try? jsonDecoder.decode(CustomDoubleId.self, from: data)
        
        // then
        XCTAssertNotNil(custom)
        XCTAssertEqual(custom?.id, "01")
        XCTAssertEqual(custom?.value, "one")
        XCTAssertEqual(existing.value, "one")
        
        let fetchRequest = NSFetchRequest<CustomDoubleId>(entityName: "CustomDoubleId")
        let all = try? container.viewContext.fetch(fetchRequest)
        XCTAssertEqual(1, all?.count)
    }
    
    func testSerializationWithCompositeKey() {
        guard let data = Data(resource: "cards.json"),
            let updatedData = Data(resource: "cards_update.json") else {
                XCTFail()
                return
        }

        do {
            let context = container.viewContext
            let cards: [Card] = try jsonDecoder.decode([Card].self, from: data)

            XCTAssertEqual(2, cards.count)

            let threeOfDiamonds = cards[0]
            XCTAssertEqual(2, threeOfDiamonds.numberOfTimesPlayed)
            XCTAssertEqual("Diamonds", threeOfDiamonds.suit)
            XCTAssertEqual("Three", threeOfDiamonds.value)

            let jackOfHearts = cards[1]
            XCTAssertEqual(3, jackOfHearts.numberOfTimesPlayed)
            XCTAssertEqual("Hearts", jackOfHearts.suit)
            XCTAssertEqual("Jack", jackOfHearts.value)

            let updatedCards = try jsonDecoder.decode([Card].self, from: updatedData)

            XCTAssertEqual(4, jackOfHearts.numberOfTimesPlayed)

            let threeOfClubs = updatedCards[1];
            XCTAssertEqual(1, threeOfClubs.numberOfTimesPlayed)
            XCTAssertEqual("Clubs", threeOfClubs.suit)
            XCTAssertEqual("Three", threeOfClubs.value)

            let fetchRequest = NSFetchRequest<Card>(entityName: "Card")
            let allCards = try context.fetch(fetchRequest)
            XCTAssertEqual(3, allCards.count)
        } catch {
            XCTFail("error: \(error)")
        }
    }
    
    func testManySerializationWithCompositeKey() {
        guard let data = Data(resource: "cards.json"),
            let updatedData = Data(resource: "cards_update.json") else {
                XCTFail()
                return
        }

        do {
            let context = container.viewContext
            let cards = try jsonDecoder.decode(Many<Card>.self, from: data)

            XCTAssertEqual(2, cards.count)

            let threeOfDiamonds = cards[0]
            XCTAssertEqual(2, threeOfDiamonds.numberOfTimesPlayed)
            XCTAssertEqual("Diamonds", threeOfDiamonds.suit)
            XCTAssertEqual("Three", threeOfDiamonds.value)

            let jackOfHearts = cards[1]
            XCTAssertEqual(3, jackOfHearts.numberOfTimesPlayed)
            XCTAssertEqual("Hearts", jackOfHearts.suit)
            XCTAssertEqual("Jack", jackOfHearts.value)

            let updatedCards: [Card] = try jsonDecoder.decode([Card].self, from: updatedData)

            XCTAssertEqual(4, jackOfHearts.numberOfTimesPlayed)

            let threeOfClubs = updatedCards[1];
            XCTAssertEqual(1, threeOfClubs.numberOfTimesPlayed)
            XCTAssertEqual("Clubs", threeOfClubs.suit)
            XCTAssertEqual("Three", threeOfClubs.value)

            let fetchRequest = NSFetchRequest<Card>(entityName: "Card")
            let allCards = try context.fetch(fetchRequest)
            XCTAssertEqual(3, allCards.count)
        } catch {
            XCTFail("error: \(error)")
        }
    }
    
    // MARK: - Encode
    func testEncodeSimpleObject() {
        // given
        // given
        let data1 = Data(resource: "person.json")!
        guard let person = try? jsonDecoder.decode(Person.self, from: data1) else {
            XCTFail()
            return
        }
                
        // when
        let data = try! JSONEncoder().encode(person)
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

        // then
        XCTAssertEqual(json?.count, 5)
        XCTAssertEqual(json?["personId"] as? Int, 1)
        XCTAssertEqual(json?["fullName"] as? String, "Marco")
        XCTAssertEqual(json?["city"] as? String, "Murcia")
        
        var attributes = json?["attributesSet"] as? [[String: Any]]
        attributes?.sort(by: { (a, b) -> Bool in
            guard let aId = a["id"] as? Int,
                let bId = b["id"] as? Int
                else { return false }
            return aId < bId
        })
        XCTAssertEqual(attributes?.count, 2)
        XCTAssertEqual(attributes?[0]["id"] as? Int, 1)
        XCTAssertEqual(attributes?[0]["name"] as? String, "funny")
        XCTAssertEqual(attributes?[1]["id"] as? Int, 2)
        XCTAssertEqual(attributes?[1]["name"] as? String, "small")
        
        let country = json?["country"] as? [String: Any]
        XCTAssertEqual(country?.count, 2)
        XCTAssertEqual(country?["id"] as? Int, 1)
        XCTAssertEqual(country?["name"] as? String, "Spain")
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
        XCTAssertEqual(json?.count, 5)
        XCTAssertEqual(json?["person_id"] as! Int, 1)
        XCTAssertEqual(json?["full_name"] as! String, "Marco")
    }
    
    func testEncodeWithCustomKeys() {
        // given
        let marco = PersonDiffKeys(context: container.viewContext)
        marco.personId = 1
        marco.fullName = "Marco"
        marco.keyPath1 = "keypath1"
        marco.keyPath2 = "keypath2"
        
        // when
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try! encoder.encode(marco)
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        print(String(data: data, encoding: .utf8)!)
        // then
        XCTAssertEqual(json?.count, 4)
        XCTAssertEqual(json?["id"] as? Int, 1)
        XCTAssertEqual(json?["name"] as? String, "Marco")
        XCTAssertEqual(json?["city"] as? NSNull, NSNull())
        
        let objectDict = json?["object"] as? [String: Any]
        XCTAssertEqual(objectDict?.count, 2)
        XCTAssertEqual(objectDict?["one"] as? String, "keypath1")
        
        let nestedDict = objectDict?["nested"] as? [String: Any]
        XCTAssertEqual(nestedDict?.count, 1)
        XCTAssertEqual(nestedDict?["two"] as? String, "keypath2")
    }
}
