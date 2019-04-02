//
//  UserFlags.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit
import FirebaseDatabase

class UserFlags: FirebaseModel {
    @objc var unreadChatsTab : Bool = false
    
    // ----------------------------------------------------
    // MARK: - Factory
    // ----------------------------------------------------
    
    static var current : UserFlags? {
        guard let user = FirebaseUser.current else { return nil }
        return UserFlags(user: user)
    }
    
    // ----------------------------------------------------
    // MARK: - Initialization
    // ----------------------------------------------------
    
    init(user: FirebaseUser) {
        super.init()
        reference = UserData.baseRef.child(user.id).child(#keyPath(UserData.userFlags))
    }
    
    required init() {
        super.init()
    }
    
    required init?(snapshot: DataSnapshot) {
        super.init(snapshot: snapshot)
    }
    
    required init(id: String) {
        super.init(id: id)
    }
    
    // ----------------------------------------------------
    // MARK: - Computed properties
    // ----------------------------------------------------
    
    var totalUnreadTabsCount : Int {
        return [
            unreadChatsTab
            ].filter({ $0 == true }).count
    }
}
