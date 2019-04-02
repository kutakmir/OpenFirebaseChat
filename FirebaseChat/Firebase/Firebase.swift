//
//  Firebase.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import FirebaseMessaging

@objc public class Firebase : NSObject {
    
    static var authToken : String?
    static func observeAuthToken() {
        Firebase.auth().addStateDidChangeListener { (auth: Auth, user: User?) in
            user?.getIDToken(completion: { (token: String?, error: Error?) in
                Firebase.authToken = token
            })
        }
    }
    
    enum Environment : String {
        case Development, Production
    }
    
    // Change this to change the database
    // DON'T FORGET TO SET THIS TO PRODUCTION WHEN DEPLOYING TO THE APP STORE!!!
    static var environment: Environment {
        #if DEBUG
            return .Development
        #else
            return .Production
        #endif
    }
    
    @objc static func database() -> Database {
        return Database.database(app: app())
    }
    
//    @objc static func firestore() -> Firestore {
//        return Firestore.firestore(app: app())
//    }
    
    @objc static func messaging() -> Messaging {
        return Messaging.messaging()
    }
    
    @objc static func app() -> FirebaseApp {
        return FirebaseApp.app()! /// DJ: Does this ever crash? In what cases does it crash? Is '!' useful to include to know when it crashes?
//        return FirebaseApp.app(name: environment.rawValue)!
    }
    
    @objc static func auth() -> Auth {
        return Auth.auth(app: app())
    }
    
    @objc static func configure() {
        FirebaseApp.configure()
        
//        let firebaseEnvironment = environment.rawValue
//        let options = FirebaseOptions(contentsOfFile: Bundle.main
//            .path(forResource: "GoogleService-Info-\(firebaseEnvironment)", ofType: "plist")!)!
//
//        FirebaseApp.configure(name: firebaseEnvironment, options: options)
    }
    
//    func reference<T : FirebaseModel>() 
}
