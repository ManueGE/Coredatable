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

/// A protocol which used in combination with `CoreDataDecodable`,  `CoreDataEncodable` or `CoreDataCodable` indicates that the object uses `CoreDataDefaultcodingKeys`
public protocol UsingDefaultCodingKeys {}

public extension UsingDefaultCodingKeys {
    typealias CodingKeys = CoreDataDefaultCodingKeys
}
