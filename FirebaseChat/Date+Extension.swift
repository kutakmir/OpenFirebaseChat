//
//  Date+Extension.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 23/03/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation

extension Date {
    
    func isToday() -> Bool {
        return isSame(as: Date())
    }
    
    func isSame(as date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: self) == formatter.string(from: date)
    }
    
}
