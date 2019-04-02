//
//  Timestamp.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation

class Timestamp {
    static func timestamp(date: Date) -> String {
        // 1508483824.2493241
        // 150848382424932
        // 1508485385779
        
        return "\(Int(date.timeIntervalSince1970 * 100000))"
    }
    static func shortTimestamp(date: Date) -> String {
        let timeStamps = "\(date.timeIntervalSince1970 * 1000)"
        let times = timeStamps.split(separator: ".")
        return String(times[0])
    }
    static var current : String {
        let timeStamps = "\(Date().timeIntervalSince1970 * 100000)"
        let times = timeStamps.split(separator: ".")
        return String(times[0])
    }
    static var currentNegative : String {
        let timeStamps = "\(Date().timeIntervalSince1970 * -100000)"
        let times = timeStamps.split(separator: ".")
        return String(times[0])
    }
     static var currentInverse : String {
//     150564627008548
//     999999999999999
        let inversePositiveNumber = 999999999999999.0 - Date().timeIntervalSince1970 * 100000
      return String(format: "%.0f", inversePositiveNumber)
     }
    
    static func timestamp(currentInverseString: String?) -> Date? {
        if let currentInverseString = currentInverseString, let integer = Double(currentInverseString) {
            let timestamp = Double((integer - 999999999999999.0) * -1) / 100000
            return Date(timeIntervalSince1970: timestamp)
        }
        return nil
    }
}
