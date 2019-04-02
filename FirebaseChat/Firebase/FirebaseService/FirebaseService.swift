//
//  FirebaseService.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 27/02/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import OneSignal

class FirebaseService {
    
    static var ref : DatabaseReference {
        return Firebase.database().reference()
    }
    
    static func readChannelRef(channelKey: String, userKey: String) -> DatabaseReference {
        return Channel.baseRef.child(channelKey).child("chatParticipantSettingsNested").child(userKey)
    }
    
    
    static func observeCurrentUser() {
        
        if let currentUserKey = currentUserKey {
            let user = FirebaseUser()
            user.id = currentUserKey
            FirebaseUser.current = user
        }
        
        // Observe the logged in status
        Firebase.auth().addStateDidChangeListener({ (auth: Auth, user: User?) in
            if let u = user {
                    
                let user = FirebaseUser()
                user.id = u.uid
                user.name = u.displayName
                FirebaseUser.current = user
            }
        })
    }
    
    static var currentUserKey: String? {
        if let currentUser = Firebase.auth().currentUser {
            return currentUser.uid
        }
        return nil
    }
    
}
