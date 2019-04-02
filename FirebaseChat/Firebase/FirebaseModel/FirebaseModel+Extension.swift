//
//  FirebaseModel+Extension.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 18/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation

extension FirebaseModel {
    
    static func jointKey(keyA: String, keyB: String) -> String {
        return [keyA, keyB].sorted().joined(separator: "")
    }
}
