//
//  UserData.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

class UserData: FirebaseModel {
    
    override class var basePath: String { return "userData" }
    
    @objc var channels = [Channel]()
    @objc var userFlags = [UserFlags]()
    
}
