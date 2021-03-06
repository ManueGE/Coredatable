//
//  Many.swift
//  Alamofire+CoreData
//
//  Created by Manuel García-Estañ on 7/10/16.
//  Copyright © 2016 ManueGE. All rights reserved.
//

import Foundation
import CoreData


/// An `Array` replacement which can just contains `NSManagedObject` instances.
/// It implements `Decodable` so it can be used to insert-serialize array responses using Alamofire.
/// It can be used in the same way that `Array`. Anyway, if you need to access the raw `Array` version of this class, you can use the `array` property.
public struct Many<Element: NSManagedObject> {
    /// The array representation of the receiver
    public private(set) var array: [Element]
    private init(_ array: [Element]) {
        self.array = array
    }
}

extension Many: Decodable where Element: CoreDataDecodable {
	public init(from decoder: Decoder) throws {
        let decoder = try CoreDataDecoder<Element>(decoder: decoder)
        self.init(try decoder.decodeArray())
    }
}

extension Many: Encodable where Element: CoreDataEncodable {
	public func encode(to encoder: Encoder) throws {
        try array.encode(to: encoder)
	}
}

// MARK: Array protocols
extension Many: MutableCollection {

    public var startIndex: Int {
        return array.startIndex
    }
    
    public var endIndex: Int {
        return array.endIndex
    }
    
    public subscript(position: Int) -> Element {
        get {
            return array[position]
        }
        
        set {
            array[position] = newValue
        }
    }
    
    public subscript(bounds: Range<Int>) -> ArraySlice<Element> {
        get {
            return array[bounds]
        }
        
        set {
            array[bounds] = newValue
        }
    }
    
    public func index(after i: Int) -> Int {
        return array.index(after: i)
    }
}

extension Many: RangeReplaceableCollection {

    public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C : Collection, C.Iterator.Element == Element {
        self.array.replaceSubrange(subrange, with: newElements)
    }

    public init() {
        self.init([])
    }
}

extension Many: ExpressibleByArrayLiteral {
    public init(arrayLiteral: Element...) {
        self.init(arrayLiteral)
    }
}

extension Many: CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self, unlabeledChildren: array, displayStyle: .collection)
    }
}

extension Many: RandomAccessCollection {
    public typealias SubSequence = Array<Element>.SubSequence
    public typealias Indices = Array<Element>.Indices
}

extension Many: CustomDebugStringConvertible {
    public var debugDescription: String {
        return array.debugDescription
    }
}

extension Many: CustomStringConvertible {
    public var description: String {
        return array.description
    }
}
