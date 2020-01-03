//
//  CoreDataCodable.swift
//  Coredatable
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

// MARK: - Codable
public typealias CoreDataCodable = CoreDataDecodable & CoreDataEncodable

public protocol UsingDefaultCodingKeys {}

public extension UsingDefaultCodingKeys {
    public typealias CodingKeys = CoreDataDefaultCodingKeys
}
