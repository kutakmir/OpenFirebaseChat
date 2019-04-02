//
//  Dictionary+Extension.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 15/02/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation


extension Dictionary {
    
    mutating func addValues(fromDictionary dictionary: [Key : Value]) {
        for (_, tuple) in dictionary.enumerated() {
            self[tuple.key] = tuple.value
        }
    }
    
}
