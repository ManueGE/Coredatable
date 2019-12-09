//
//  IdentityAttribute.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

public enum IdentityAttribute {
    case no
    case composed(Set<String>)
    static func single(_ string: String) -> IdentityAttribute {
        composed([string])
    }
}

extension IdentityAttribute: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: Self.StringLiteralType) {
        self = .composed(Set([value]))
    }
}

extension IdentityAttribute: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = String
    public init(arrayLiteral elements: String...) {
        if elements.count == 0 {
            self = .no
        } else {
            self = .composed(Set(elements))
        }
    }
}
