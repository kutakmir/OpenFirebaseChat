//
//  User.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit
import FirebaseDatabase

class FirebaseUser: FirebaseModel {
    
    override class var basePath: String { return "users" }
    
    override var skipProperties: [String] {
        return super.skipProperties + ["isCurrent", "userData", "isSelected"]
    }
    
    // Ignored Properties
    
    // Mapped Properties
    // @objc var oneSignalUIDs: [String : Bool]? /// DJ: Delete when done since not using 'OneSignal'.
    
    @objc var name: String?
    @objc var imageURL: URL?
    
    lazy var userData: UserData = {
        let data = UserData()
        data.id = id
        return data
    }()
    
    @objc var latestEnteredExitedOrActivityTimestamp = Date() /// DJ: TODO: Check 'latestEnteredExitedOrActivityTimestamp' to know if to gray out or remove updates that were showing about the state of editing or sharing. And this also indicates whether the person is online. Or should this actually be using this for updating the timing in 'Detecting Connection State' and below at https://firebase.google.com/docs/database/ios/offline-capabilities#section-presence?
    /// DJ: Possibly change to 'var lastOnline = Date()'.
    
    // ----------------------------------------------------
    // MARK: - Initialization
    // ----------------------------------------------------
    
    // Creating a fake user for testing purposes
    init(name: String) {
        super.init()
        
        self.name = name
        id = NSUUID().uuidString
    }
    // We need to implement the required initializers because we are using a custom init(name:_)
    required init() { super.init() }
    required init?(snapshot: DataSnapshot) { super.init(snapshot: snapshot) }
    required init(id: String) { super.init(id: id) }
    
    // ----------------------------------------------------
    // MARK: - Derived properties
    // ----------------------------------------------------
    static var current : FirebaseUser?
    
    // ----------------------------------------------------
    // MARK: - Ignored Properties
    // ----------------------------------------------------
    var isCurrent: Bool {
        if let current = FirebaseUser.current, current == self {
            return true
        }
        return false
    }
    var isSelected : Bool = false
    
    /**
     Gets the nickname or the name of the current user. It prefers a cached name if possible so it should be as efficient as possible.
     */
    func getDisplayName(_ with: @escaping (_ name: String?)->Void) {
        
        if isCurrent {
            with("Me")
            //            if let name = FirebaseUser.current?.name {
            //                with(name)
            //            } else {
            //                FirebaseUser.current?.attachOnce {
            //                    with(FirebaseUser.current?.name)
            //                }
            //            }
            
        } else {
            if let name = name {
                with(name)
            } else {
                attachPropertyOnce(property: #keyPath(FirebaseUser.name), with: {
                    with(self.name)
                })
            }
        }
    }
    
}
