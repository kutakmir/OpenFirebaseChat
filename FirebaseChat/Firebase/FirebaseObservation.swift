//
//  FirebaseObservation.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 21/03/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct FirebaseObservation {
    let handle : DatabaseHandle
    let query : DatabaseQuery
    
    func remove() {
        query.removeObserver(withHandle: handle)
    }
}
