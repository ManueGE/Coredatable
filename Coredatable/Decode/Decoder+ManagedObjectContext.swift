//
//  Decoder+ManagedObjectContext.swift
//  Coredatable
//
//  Created by Manuel García-Estañ on 12/07/2019.
//  Copyright © 2019 Manuege. All rights reserved.
//

import Foundation
import CoreData

public extension CodingUserInfoKey {
	static let managedObjectContext = CodingUserInfoKey(rawValue: "coredatable.managedObjectContext")!
}

extension Decoder {
	public var managedObjectContext: NSManagedObjectContext? {
		return userInfo[.managedObjectContext] as? NSManagedObjectContext
	}
}

extension JSONDecoder {
	public var managedObjectContext: NSManagedObjectContext? {
		get { return userInfo[.managedObjectContext] as? NSManagedObjectContext }
		set { userInfo[.managedObjectContext] = newValue }
	}
}
