//
//  DataReference.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 23/01/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

extension DatabaseReference {
    
    var path : String {
        return description().components(separatedBy: "firebaseio.com/").last!
    }
    
    var pathComponents : [String] {
        return path.components(separatedBy: "/")
    }
    
}
