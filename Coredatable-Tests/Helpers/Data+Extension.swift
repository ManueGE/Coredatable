//
//  Data+Extension.swift
//  Coredatable-Tests
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

extension Data {
    private class Dummy {}

    internal init?(resource: String) {

        let name = (resource as NSString).deletingPathExtension
        let type = (resource as NSString).pathExtension
        let bundle = Bundle(for: Dummy.self)

        guard let url = bundle.url(forResource: name, withExtension: type) else {
            return nil
        }

        try? self.init(contentsOf: url)
    }
    
    internal static func fromJson(_ dictionary: [AnyHashable: Any?]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: dictionary, options: [])
    }
    
    internal static func fromArray(_ array: [Any]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: array, options: [])
    }
}
