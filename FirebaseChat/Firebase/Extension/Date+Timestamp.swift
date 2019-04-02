//
//  Timestamp.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 18/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation

extension Date {
    
    init?(currentInverseString: String?) {
        if let currentInverseString = currentInverseString, let integer = Double(currentInverseString) {
            let timestamp = Double((integer - 999999999999999.0) * -1) / 100000
            self.init(timeIntervalSince1970: timestamp)
        } else {
            return nil
        }
    }
    
    var inverseTimestamp : String {
        let inversePositiveNumber = 999999999999999.0 - timeIntervalSince1970 * 100000
        return String(format: "%.0f", inversePositiveNumber)
    }
    
    var timestamp : String {
        let timeStamps = "\(timeIntervalSince1970 * 100000)"
        let times = timeStamps.split(separator: ".")
        return String(times[0])
    }
    
    var negativeTimestamp : String {
        let timeStamps = "\(timeIntervalSince1970 * -100000)"
        let times = timeStamps.split(separator: ".")
        return String(times[0])
    }
    
    var shortTimestamp : String {
        let timeStamps = "\(timeIntervalSince1970 * 1000)"
        let times = timeStamps.split(separator: ".")
        return String(times[0])
    }
    
}
