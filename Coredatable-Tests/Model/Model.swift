//
//  Model.swift
//  Coredatable-Tests
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation
import CoreData

final class Person: NSManagedObject {
    @NSManaged var id: Int
    @NSManaged var name: String
}
