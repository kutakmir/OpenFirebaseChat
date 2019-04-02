//
//  Report.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class Report: FirebaseModel {
    
    override class var basePath: String { return "reports" }
    
    @objc var reportedUserNested : FirebaseUser?
    @objc var reportedChannelNested : Channel?
    
    @objc var caption : String?
    @objc var creatorNested : FirebaseUser?
    
}
