# **Co**re**da**ta**ble**

Easy `Codable` conformance in `NSManagedObject` subclasses. 

> This library is in beta phase. Until version `1.0.0` is released, breaking changes might be added.

## Installation
### CocoaPods
Add the following to your `Podfile`:

```
pod 'Coredatable'
```

## Summary

Adding `Decodable` and `Encodable` conformance to `NSManagedObject` subclasses is usually very tricky. `Coredatable` simplifies this process using equivalent protocols called `CoreDataDecodable`, `CoreDataEncodable` and `CoreDataCodable` this way:

```swift
final class Person: NSManagedObject, CoreDataCodable, UsingDefaultCodingKeys {
    @NSManaged var id: Int
    @NSManaged var name: String?
    @NSManaged var city: String?
    @NSManaged var birthday: Date?
    @NSManaged var attributes: NSSet
}

class PersonAttribute: NSManagedObject, CoreDataCodable {    
    @NSManaged private(set) var id: Int
    @NSManaged private(set) var name: String
    
    enum CodingKeys: String, CoreDataCodingKey {
        case id
        case name = "attributeName"
    }
}

// Decode
let decoder = JSONDecoder()
decoder.managedObjectContext = myContext
let person = try decoder.decode(Person.self, from: data)

// Encode
let encoder = JSONEncoder()
let data = try encoder.encode(person)
```
And yes, that's all. 

You just need to add a `NSManagedObjectContext` to your decoder, and make the classes conform the protocol. The protocol forces you to add a `CodingKeys` type. In the samples we have two different cases:

- If the keys to use are the default ones (same names as the property) you can just conform `UsingDefaultCodingKeys`. Alternatively, you could do  `typealias CodingKeys = CoreDataDefaultCodingKeys`. 
- If you want to use a different set of keys, you must create a `enum` called `CodingKeys`, make it conforms `CoreDataCodingKeys` and define the cases  and its string values. 

In the case you want a more customized `CodingKey`, you can create a `class` a `struct` or any other type and make it conforms `AnyCoreDataCodingKey`.

## Identity Attributes.

Optionally, you can ensure uniqueness in your `NSManagedObject` instances. To do it, you can use  `identityAttribute` property:

```swift
final class Person: NSManagedObject, CoreDataCodable, UsingDefaultCodingKeys {
    @NSManaged var id: Int
    @NSManaged var name: String?
    @NSManaged var country: String?
    @NSManaged var birthday: Date?
    @NSManaged var attributes: NSSet
    
    static let identityAttribute: IdentityAttribute = #keyPath(Person.id)
}
```

If you do this, `Coredatable` will take care of check if an object with the same value for the `identityAttribute` already exists in the context. If it exists, the object will be updated with the new values. If it doesn't, it will be just inserted. When an object is updated, only the values present in the new json are updated. 

Composite identity attributes are supported this way:

```swift
static let identityAttribute: IdentityAttribute = [#keyPath(Person.id), #keyPath(Person.name)]
```

However, only use composite identity attributes if it is really needed because the performance will be affected. The single identity attribute strategy requires one fetch for every array of JSON objects, whereas the composite identity attribute strategy requires one fetch for every single JSON object.

If uniqueness is not required, you can exclude `identityAttribute` at all.

### Serializing relationships from identifiers

Suppose that our API does not return full objects for the relationships but only the identifiers.

We don't need to change our model to support this situation:


```swift
let json: [String: Any] = [
    "id": "1",
    "name": "Marco",
    "attributes": [1, 2]
]
let data = try JSONSerialization.data(withJSONObject: json, options: [])
let person = try decoder.decode(Person.self, from: data)
```

The above code creates a `Person` object. In the case we already have in our context a `PersonAttribute` with ids `1` or `2`, those objects will be set in the relationship. If not, two `PersonAttribute` instances will be created with the given `id`.

> Note that serializing relationships from identifiers only works with entities specifying only one attribute as the value of `identityAttribute`.

## KeyPath Coding Keys

Let's supose we have  a value which is inside a nested json:

```swift
{
    "id": 1,
    "name": "Marco",
    "origin": {
        "country" {
            "id": 1,
            "name": "Spain"
        }
    }
}
```

we can access the country name directly using key parh notation:

```swift
enum CodingKeys: String, CoreDataCodingKey {
    case id, name, birthday, attributes
    case country = "origin.country.name"
}
```

by default, keypaths use a period  `.` as paths delimiter, but you could use any other string sdding this:

```swift
enum CodingKeys: String, CoreDataCodingKey {
    case id, name, birthday, attributes
    case country = "origin->country->name"
    
    var keyPathDelimiter: String { "->" }
}
```


## Custom Decoding

In the case that you need custom serialization, you'll need to do something slightly different from what you'd do in regular `Codable`. Instead of overriding `init(from decoder: Decoder)`  you should override `func initialize(from decoder: Decoder) throws`. 

Let's see an example:

```swift
final class Custom: NSManagedObject, CoreDataDecodable {
    @NSManaged var id: Int
    @NSManaged var compound: String
    
    enum CodingKeys: String, CoreDataCodingKey {
        case id
        case first
        case second
    }
    
    static var identityAttribute: IdentityAttribute = #keyPath(Custom.id)
    
    // 1
    func initialize(from decoder: Decoder) throws {
        // 2
        try defaultInitialization(from: decoder, with: [.id])
        
        // 3
        let container = try decoder.container(for: Custom.self)
        
        // 4
        let first = try container.decode(String.self, forKey: .first)
        let second = try container.decode(String.self, forKey: .second)
        
        // 5
        compound = [first, second].joined(separator: " ")
    }
}
```

here, we have a propery  `compound` which is built joining two strings which come under different keys. What we do is:
- `// 1`: Overreding  ` func initialize(from container: CoreDataKeyedDecodingContainer<Custom>)`
- `// 2`: Call the default serialization only taking in account the `id` key. (Note: there are a few more default implementations where you can specify what keys are included or skipped)
- `// 3`: Create a new container passing the own type as parameter. Passing another type will lead to errors.
- `// 4: Extract the `first` and `second` values from the container. 
- `// 5`: Adding the joined string to the `compound` property.

If you need to perform some changes in the `identityAttributes` before the json is serialized, you need to use a different method. Let's supose that our json sends `id` as a `String` but we have it as an integer. We can modifiy the value using: 

```swift
// 1
static func container(for decoder: Decoder) throws -> AnyCoreDataKeyedDecodingContainer {
   // 2
   var container = try decoder.container(for: CustomDoubleId.self)
   
   // 3
   container[.id] = Int(try container.decode(String.self, forKey: .id)) ?? 0
   
   // 4
   return container
}
```

- `// 1`: Override  `static func container(for decoder: Decoder) throws -> AnyCoreDataKeyedDecodingContainer`
- `// 2`: Create a new mutable container passing the own type as parameter. Passing another type will lead to errors.
- `// 3`: Convert the value to the needed one and assing it to the `.id` key
- `// 4`: return the modified container


## Many

You can use `CoreDataDecodable` objects nested in another `Codable` object without any problem:

```swift
struct LoginResponse: Codable {
    let token: String
    let user: Person
}
```

However, in the case you want to reference an array of `CoreDataDecodable` objects:

```swift
struct Response: Codable {
    let nextPage: String
    let previousPage: String
    let total: Int
    // don't do this
    let results: [Person]
}
```

it is better if you use `Many` instead of `Array`:

```swift
struct Response: Codable {
    let nextPage: String
    let previousPage: String
    let total: Int
    let results: Many<Person>
}
```

Using `Many` will improve performance. `Many` is a replacement of `Array` and can be used in the same way. In any case, you can access the raw array using `many.array`. 


## Inspiration:

This library has been heavily inspired by [**Groot**](https://github.com/gonzalezreal/groot)


## Author

[@ManueGE](https://twitter.com/ManueGE)

## License
Coredatable is available under the MIT License. See [LICENSE](https://github.com/ManueGE/Goya/blob/master/LICENSE).
