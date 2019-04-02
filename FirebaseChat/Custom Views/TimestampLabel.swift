//
//  TimestampLabel.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class TimestampLabel: UILabel {

    fileprivate var timeUpdateTimer : Timer?

    var timestamp : Date? {
        didSet {
            
            text = nil
            
            guard let t = timestamp else { return; }
            
            // More than a day
            let formatter = DateFormatter()
            
            if t.isToday() {
                formatter.timeStyle = .short
            } else {
                formatter.dateStyle = .short
            }
            
            text = formatter.string(from: t)
        }
        
    }
}
