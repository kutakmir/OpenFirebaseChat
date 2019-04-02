//
//  FirebaseService+StandardOperations.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

extension FirebaseService {
    
    func performIncrementTransaction(ref: DatabaseReference, increment: Int = 1, completion: ((_ totalCount: Int)->Void)? = nil) {
        // Using Firebase transaction, because not only this device can be writing at the same time (very unlikely though)
        ref.runTransactionBlock { (data : MutableData) -> TransactionResult in
            // Get the current value
            var totalCount = data.value as? Int ?? 0
            // Increment
            totalCount += increment
            data.value = totalCount
            
            completion?(totalCount)
            
            // Save
            return TransactionResult.success(withValue: data)
        }
    }
    
}
