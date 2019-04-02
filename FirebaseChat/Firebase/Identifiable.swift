//
//  Identifiable.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

protocol Identifiable {
    var id: String {get set}
    func attributesDictionary() -> [String: AnyObject]
}

// Override equivalence for optionals
func == (lhs: Identifiable?, rhs: Identifiable?) -> Bool {
    if let lid = lhs?.id, let rid = rhs?.id {
        return lid == rid
    } else if lhs?.id == nil && rhs?.id == nil {
        return true
    } else {
        return false
    }
}

func == (lhs: DataSnapshot?, rhs: DataSnapshot?) -> Bool {
    if let lid = lhs?.key, let rid = rhs?.key {
        return lid == rid
    } else if lhs?.key == nil && rhs?.key == nil {
        return true
    } else {
        return false
    }
}

extension Array where Element : Equatable {
    
    func index(of element: Element) -> Int? {
        var index = 0
        for item in self {
            if item == element {
                return index
            }
            index += 1
        }
        
        return nil
    }
}
