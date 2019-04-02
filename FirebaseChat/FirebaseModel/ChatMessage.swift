//
//  ChatMessage.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit
import FirebaseDatabase
class ChatMessage: FirebaseModel {
    
    enum ChatMessageType : String {
        case text
        case photo
    }
    
    override class var basePath : String { return "chatMessages" }
    
    override var skipProperties: [String] {
        return super.skipProperties + ["chatMessageType", "isIncoming", "timestamp", "creatorId"]
    }

    @objc var text : String?
    @objc var type : String?
    @objc var senderId : String?
    @objc var recipientId : String?
    @objc var photoURL : String?
    
    var creatorId : String? {
        return senderId
    }
    
    required init?(snapshot: DataSnapshot) {
        super.init(snapshot: snapshot)
    }
    
    required init() {
        super.init()
        
        // Generate inverse timestamp
        id = Timestamp.currentInverse
    }
    
    required init(id: String) {
        super.init(id: id)
    }
    
    lazy var timestamp : Date? = {
        return Timestamp.timestamp(currentInverseString: id)
    }()
    
    var chatMessageType : ChatMessageType {
        if let type = type, let chatMessageType = ChatMessageType(rawValue: type) {
            return chatMessageType
        } else {
            if photoURL != nil {
                return .photo
            }
            // Text by default
            return .text
        }
    }
    
    var isIncoming : Bool {
        guard let currentUserKey = FirebaseService.currentUserKey, let senderId = senderId else { return true }
        
        if recipientId == currentUserKey {
            return true
        }
        if senderId == currentUserKey {
            return false
        }
        
        return true
    }
    
}
