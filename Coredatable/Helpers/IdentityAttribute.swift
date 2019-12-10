//
//  IdentityAttribute.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

public struct IdentityAttribute {
    enum Kind {
        case no
        case single(String)
        case composite([String])
    }
    
    private let propertyNames: [String]
    fileprivate init(_ propertyNames: Set<String>) {
        self.propertyNames = Array(propertyNames)
    }
    public static var no: IdentityAttribute { IdentityAttribute([]) }
    
    var kind: Kind {
        if propertyNames.count == 0 {
            return .no
        } else if propertyNames.count == 1 {
            return .single(propertyNames[0])
        } else {
            return .composite(propertyNames)
        }
    }
}

extension IdentityAttribute: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: Self.StringLiteralType) {
        self = IdentityAttribute(Set([value]))
    }
}

extension IdentityAttribute: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = String
    public init(arrayLiteral elements: String...) {
        self = IdentityAttribute(Set(elements))
    }
}
