//
//  StringCodingKey.swift
//  Coredatable
//
//  Created by Manuel García-Estañ on 12/07/2019.
//  Copyright © 2019 Manuege. All rights reserved.
//

import Foundation

struct StringCodingKey: CodingKey {
	let string: String
	
	init(_ string: String) {
		self.string = string
	}
	
    public init?(stringValue: String) {
		self.string = stringValue
	}
	
    var stringValue: String { return string }
    var intValue: Int? = nil
    init?(intValue: Int) { return nil }
}
